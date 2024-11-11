local addonName, addon = ...

local allCharacters
local auctionsList, bidsList
local options

local TableRemove = table.remove
local C_Timer, tonumber, pairs, select, strsplit, floor, time = C_Timer, tonumber, pairs, select, strsplit, floor, time
local isVanilla = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

local function _GetAuctionHouseItemInfo(characterID, list, index)
	local entries
	
	if list == "Bids" then
		entries = bidsList[characterID]
	elseif list == "Auctions" then
		entries = auctionsList[characterID]
	end
	
	-- invalid auction type ? exit
	if not entries then return end
	
	-- invalid index ? exit
	local item = entries[index]
	if not item then return end
	
	local isGoblin, itemID, count, name, price1, price2, timeLeft, auctionID = strsplit("|", item)
	isGoblin = (tonumber(isGoblin) == 1) and true or nil
	
	return isGoblin, tonumber(itemID), tonumber(count), name, tonumber(price1), tonumber(price2), tonumber(timeLeft), tonumber(auctionID or 0)
end

local function _GetAuctionHouseItemCount(characterID, searchedID)
	if not auctionsList[characterID] then return 0 end
	
	local count = 0
	
	for k, v in pairs (auctionsList[characterID]) do
		local _, id, itemCount = strsplit("|", v)
		if id and (tonumber(id) == searchedID) then 
			itemCount = tonumber(itemCount) or 1
			count = count + itemCount
		end
	end
	
	return count
end

local function _GetClosestAuctionExpiry(characterID)
	local value = 0
	
	local entries = auctionsList[characterID]
	
	if entries then
		for _, entry in pairs(entries) do
			local _, _, _, _, _, _, timeLeft = strsplit("|", entry)
			timeLeft = tonumber(timeLeft)
			
			if value == 0 or timeLeft < value then
				value = timeLeft
			end
		end
		
		-- Determine the real time left, relative to the last scan
		local char = allCharacters[characterID]
		local diff = time() - char.lastAuctionsScan
		
		value = value - diff	
	end
	
	return value
end

local function _GetHighestBuyoutAuction(characterID)
	local value = 0
	
	local entries = auctionsList[characterID]
	if entries then
		for _, entry in pairs(entries) do
			local _, _, _, _, _, buyout = strsplit("|", entry)
			buyout = tonumber(buyout)
			
			if buyout > value then
				value = buyout
			end
		end
	end
	
	return value
end

local function _GetLowestBuyoutAuction(characterID)
	local value = 0
	
	local entries = auctionsList[characterID]
	if entries then
		for _, entry in pairs(entries) do
			local _, _, _, _, _, buyout = strsplit("|", entry)
			buyout = tonumber(buyout)
			
			if value == 0 or buyout < value then
				value = buyout
			end
		end
	end
	
	return value
end


-- maximum time left in seconds per auction type : [1] = max 30 minutes, [2] = 2 hours, [3] = 12 hours, [4] = more than 12, but max 48 hours
-- info : https://wowpedia.fandom.com/wiki/API_C_AuctionHouse.GetReplicateItemTimeLeft    (retail)
-- info : https://wowpedia.fandom.com/wiki/API_GetAuctionItemTimeLeft   (vanilla & LK)
local maxHours = isVanilla and 24 or 48
local maxTimeLeft = { 30*60, 2*60*60, 12*60*60, maxHours*60*60 }

local function CheckExpiries()
	local sources = { auctionsList, bidsList }
	local timeLeft, diff
	
	local checkLastVisit = options.CheckLastVisit
	local threshold = options.CheckLastVisitThreshold
	local autoClear = options.AutoClearExpiredItems
	
	for charID, character in pairs(allCharacters) do
		-- Check if the last auction visit was maybe a very long time ago, and warn the player that he may have missed items..
		if checkLastVisit and character.lastAuctionsScan then
			local seconds = time() - character.lastAuctionsScan
			local days = floor(seconds / 86400)
			
			DataStore:Broadcast("DATASTORE_AUCTIONS_NOT_CHECKED_SINCE", character, charID, days, threshold)
		end
		
		-- browse both auctions & bids
		for _, source in pairs(sources) do					
			
			-- if we have data for this character
			if source[charID] then
			
				-- from last to first, to make sure TableRemove does not screw up indexes.
				for index = #source[charID], 1, -1 do
					timeLeft = select(7, _GetAuctionHouseItemInfo(charID, ahType, index))
					if not timeLeft or (timeLeft < 1) or (timeLeft > 4) then
						timeLeft = 4	-- timeLeft is supposed to always be between 1 and 4, if it's not in this range, set it to the longest value (4 = more than 12 hours)
					end

					diff = time() - character.lastUpdate
					
					if diff > maxTimeLeft[timeLeft] and autoClear then		-- has expired
						TableRemove(source[charID], index)
					end
				end
			end
		end
	end
end

DataStore:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		rawTables = {
			"DataStore_Auctions_Options"
		},
		characterTables = {
			["DataStore_Auctions_Characters"] = {
				GetAuctionHouseLastVisit = function(character) return character.lastUpdate or 0 end,
			},
		},
		characterIdTables = {
			["DataStore_Auctions_AuctionsList"] = {
				GetNumAuctions = function(characterID) 
					return auctionsList[characterID] and #auctionsList[characterID] or 0
				end,
				GetAuctionHouseItemCount = _GetAuctionHouseItemCount,
				GetAuctionHouseItemInfo = _GetAuctionHouseItemInfo,
				GetClosestAuctionExpiry = _GetClosestAuctionExpiry,
				GetHighestBuyoutAuction = _GetHighestBuyoutAuction,
				GetLowestBuyoutAuction = _GetLowestBuyoutAuction,
			},
			["DataStore_Auctions_BidsList"] = {
				GetNumBids = function(characterID)
					return bidsList[characterID] and #bidsList[characterID] or 0
				end,
			},
		}
	})
	
	allCharacters = DataStore_Auctions_Characters
	auctionsList = DataStore_Auctions_AuctionsList
	bidsList = DataStore_Auctions_BidsList

	options = DataStore:SetDefaults("DataStore_Auctions_Options", {
		CheckLastVisit = true,				-- Check the last auction house visit time or not
		CheckLastVisitThreshold = 15,
		AutoClearExpiredItems = true,		-- Automatically clear expired auctions and bids
	})	
end)

DataStore:OnPlayerLogin(function()
	-- check AH expiries 3 seconds later, to decrease the load at startup
	C_Timer.After(3, CheckExpiries)
end)
