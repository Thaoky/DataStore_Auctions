--[[	*** DataStore_Auctions ***
Written by : Thaoky, EU-Marécages de Zangar
July 15th, 2009
--]]
if not DataStore then return end

local addonName, addon = ...
local thisCharacter
local auctionsList, bidsList

local DataStore, TableInsert, TableRemove, format, strsplit, tonumber = DataStore, table.insert, table.remove, format, strsplit, tonumber
local GetNumAuctionItems, GetAuctionItemInfo, GetAuctionItemLink, GetAuctionItemTimeLeft = GetNumAuctionItems, GetAuctionItemInfo, GetAuctionItemLink, GetAuctionItemTimeLeft
local C_Map, C_AuctionHouse, time, date = C_Map, C_AuctionHouse, time, date

-- local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isRetail = type(C_AuctionHouse) == "table"

-- *** Common API ***
local API_GetNumAuctions = isRetail and C_AuctionHouse.GetNumOwnedAuctions or function() return GetNumAuctionItems("owner") end
local API_GetNumBids = isRetail and C_AuctionHouse.GetNumBids or function() return GetNumAuctionItems("bidder") end
local API_GetAuctionInfo
local API_GetBidInfo

local function IsItemSold(status)
	return (status and status == 1)
end

if isRetail then
	API_GetAuctionInfo = function(index) 
			local info = C_AuctionHouse.GetOwnedAuctionInfo(index)
			local saleStatus = info.status
			local itemID = info.itemKey.itemID
			
			-- do not list sold items, they're supposed to be in the mailbox
			if itemID and not IsItemSold(saleStatus) then
				return itemID, info.quantity, info.bidder, info.bidAmount, info.buyoutAmount, info.timeLeftSeconds, info.auctionID
			end
		end
	API_GetBidInfo = function(index) 
			local info = C_AuctionHouse.GetBidInfo(index)
			
			return info.itemKey.itemID, info.quantity, info.bidder, info.bidAmount, info.buyoutAmount, info.timeLeft
		end
else
	API_GetAuctionInfo = function(index) 
			local itemName, _, count, _, _, _, _, startPrice, _, buyoutPrice, _, highBidder, _, _, _, saleStatus, itemID =  GetAuctionItemInfo("owner", index)
			
			-- do not list sold items, they're supposed to be in the mailbox
			if itemName and itemID and not IsItemSold(saleStatus) then
				local timeLeft = GetAuctionItemTimeLeft("owner", index)
			
				return itemID, count, highBidder, startPrice, buyoutPrice, timeLeft
			end
		end
	API_GetBidInfo = function(index) 
			local itemName, _, count, _, _, _, _, _, _, buyoutPrice, bidPrice, _, ownerName = GetAuctionItemInfo("bidder", index)
		
			if itemName then
				local link = GetAuctionItemLink("bidder", index)
				
				if not link:match("battlepet:(%d+)") then		-- temporarily skip battle pets
					local itemID = tonumber(link:match("item:(%d+)"))
					local timeLeft = GetAuctionItemTimeLeft("bidder", index)
					
					return itemID, count, ownerName, bidPrice, buyoutPrice, timeLeft
				end
			end
		end
end


-- *** Utility functions ***
local function ClearEntries(entries, AHZone)
	-- this function clears the "auctions" or "bids" of a specific AH (faction or goblin)
	-- entries = character.Auctions or character.Bids (the name of the table in the DB)
	-- AHZone = 0 for player faction, or 1 for goblin
	local ah = entries
	if not ah then return end
	
	for i = #ah, 1, -1 do			-- parse backwards to avoid messing up the index
		local faction = strsplit("|", ah[i])
		if faction then
			if tonumber(faction) == AHZone then
				TableRemove(ah, i)
			end
		end
	end
end

local function GetAuctionHouseZone()
	local zoneID = C_Map.GetBestMapForUnit("player")
	
	-- return 1 for goblin AH, 0 for faction AH
	return (zoneID == 161 or zoneID == 281 or zoneID == 673) and 1 or 0
end

-- *** Scanning functions ***
local function ScanAuctions()
	local AHZone = GetAuctionHouseZone()
	
	local now = time()
	local char = thisCharacter
	local charID = DataStore.ThisCharID
	local numAuctions = API_GetNumAuctions()
	
	char.lastUpdate = now
	char.lastAuctionsScan = now
	
	auctionsList[charID] = auctionsList[charID] or {}
	ClearEntries(auctionsList[charID], AHZone)
	
	for i = 1, numAuctions do
		local itemID, quantity, bidder, bidAmount, buyoutAmount, timeLeftSeconds, auctionID = API_GetAuctionInfo(i)
			
		if itemID then
			TableInsert(auctionsList[charID], format("%s|%s|%s|%s|%s|%s|%s|%s", 
				AHZone, itemID, quantity or 1, bidder or "", bidAmount or 0, buyoutAmount or 0, timeLeftSeconds or 0, auctionID or 0))
		end
	end
	
	-- Completely clear the table is it is empty
	if #auctionsList[charID] == 0 then
		auctionsList[charID] = nil
	end
	
	AddonFactory:Broadcast("DATASTORE_AUCTIONS_UPDATED")
end

local function ScanBids()
	local AHZone = GetAuctionHouseZone()
	
	local char = thisCharacter
	local charID = DataStore.ThisCharID
	char.lastUpdate = time()
	char.lastVisitDate = date("%Y/%m/%d %H:%M")
	
	bidsList[charID] = bidsList[charID] or {}
	ClearEntries(bidsList[charID], AHZone)
	
	for i = 1, API_GetNumBids() do
		local itemID, quantity, bidder, bidAmount, buyoutAmount, timeLeft = API_GetBidInfo(i)

		if itemID then
			TableInsert(bidsList[charID], format("%s|%s|%s|%s|%s|%s|%s", AHZone, itemID, quantity or 1, bidder or "", bidAmount or 0, buyoutAmount or 0, timeLeft))	
		end
	end
	
	-- Completely clear the table is it is empty
	if #bidsList[charID] == 0 then
		bidsList[charID] = nil
	end
end

-- *** Event Handlers ***
local function OnAuctionHouseClosed()
	addon:StopListeningTo("AUCTION_HOUSE_CLOSED")
	addon:StopListeningTo("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
	
	if isRetail then
		addon:StopListeningTo("OWNED_AUCTIONS_UPDATED", ScanAuctions)
		addon:StopListeningTo("AUCTION_HOUSE_AUCTION_CREATED", ScanAuctions)
		addon:StopListeningTo("BIDS_UPDATED", ScanBids)
	else
		addon:StopListeningTo("AUCTION_OWNED_LIST_UPDATE", ScanAuctions)
		addon:StopListeningTo("AUCTION_BIDDER_LIST_UPDATE", ScanBids)
	end
end

local function OnAuctioneerHide(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.Auctioneer then
		OnAuctionHouseClosed()
	end
end

local function OnAuctionHouseShow()
	addon:ListenTo("AUCTION_HOUSE_CLOSED", OnAuctionHouseClosed)
	addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", OnAuctioneerHide)
	
	if isRetail then
		addon:ListenTo("OWNED_AUCTIONS_UPDATED", ScanAuctions)
		addon:ListenTo("AUCTION_HOUSE_AUCTION_CREATED", ScanAuctions)
		addon:ListenTo("BIDS_UPDATED", ScanBids)
	else
		addon:ListenTo("AUCTION_OWNED_LIST_UPDATE", ScanAuctions)
		addon:ListenTo("AUCTION_BIDDER_LIST_UPDATE", ScanBids)
	end
	
	local char = thisCharacter
	char.lastUpdate = time()
	char.lastVisitDate = date("%Y/%m/%d %H:%M")
end

local function OnAuctioneerShow(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.Auctioneer then
		OnAuctionHouseShow()
	end
end


AddonFactory:OnAddonLoaded(addonName, function()
	DataStore:RegisterModule({
		addon = addon,
		addonName = addonName,
		characterTables = {
			["DataStore_Auctions_Characters"] = {
				ClearAuctionEntries = function(character, AHType, AHZone)
					-- this function clears the "auctions" or "bids" of a specific AH (faction or goblin)
					-- AHType = "Auctions" or "Bids" (the name of the table in the DB)
					-- AHZone = 0 for player faction, or 1 for goblin
					
					ClearEntries(character[AHType], AHZone)
				end,
			},
		},
		characterIdTables = {
			["DataStore_Auctions_AuctionsList"] = {},
			["DataStore_Auctions_BidsList"] = {},
		}
	})
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Auctions_Characters", true)
	auctionsList = DataStore_Auctions_AuctionsList
	bidsList = DataStore_Auctions_BidsList
end)

AddonFactory:OnPlayerLogin(function()
	addon:ListenTo("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)
	addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnAuctioneerShow)
	
	if not isRetail then
		addon:SetupOptions()
	end
end)
