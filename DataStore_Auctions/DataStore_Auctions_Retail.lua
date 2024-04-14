--[[	*** DataStore_Auctions ***
Written by : Thaoky, EU-Marécages de Zangar
July 15th, 2009
--]]
if not DataStore then return end

local addonName, addon = ...
local thisCharacter
local auctionsList, bidsList

local DataStore, TableInsert, TableRemove, format, strsplit, tonumber = DataStore, table.insert, table.remove, format, strsplit, tonumber
local C_Map, C_AuctionHouse, time, date = C_Map, C_AuctionHouse, time, date


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
	local numAuctions = C_AuctionHouse.GetNumOwnedAuctions()
	
	char.lastUpdate = now
	char.lastAuctionsScan = nil
	if numAuctions > 0 then
		char.lastAuctionsScan = now
		
	end
	
	auctionsList[charID] = auctionsList[charID] or {}
	ClearEntries(auctionsList[charID], AHZone)
	
	for i = 1, numAuctions do
		local info = C_AuctionHouse.GetOwnedAuctionInfo(i)
		local saleStatus = info.status
		local itemID = info.itemKey.itemID
		
		-- do not list sold items, they're supposed to be in the mailbox
		if saleStatus and saleStatus == 1 then		-- just to be sure, in case Bliz ever returns nil
			saleStatus = true
		else
			saleStatus = false
		end
			
		-- if info.itemLink and itemID and not saleStatus then
		if itemID and not saleStatus then

			TableInsert(auctionsList[charID], format("%s|%s|%s|%s|%s|%s|%s|%s", 
				AHZone, itemID, info.quantity or 1, info.bidder or "", info.bidAmount or 0, info.buyoutAmount or 0, info.timeLeftSeconds or 0, info.auctionID or 0))
		end
	end
	
	-- Completely clear the table is it is empty
	if #auctionsList[charID] == 0 then
		auctionsList[charID] = nil
	end
	
	DataStore:Broadcast("DATASTORE_AUCTIONS_UPDATED")
end

local function ScanBids()
	local AHZone = GetAuctionHouseZone()
	
	local char = thisCharacter
	local charID = DataStore.ThisCharID
	char.lastUpdate = time()
	char.lastVisitDate = date("%Y/%m/%d %H:%M")
	
	bidsList[charID] = bidsList[charID] or {}
	ClearEntries(bidsList[charID], AHZone)
	
	for i = 1, C_AuctionHouse.GetNumBids() do
		local info = C_AuctionHouse.GetBidInfo(i)
		local itemID = info.itemKey.itemID
		
		-- review item.name ? item.quantity ?
		TableInsert(bidsList[charID], format("%s|%s|%s|%s|%s|%s|%s", 
			AHZone, itemID, info.quantity or 1, info.bidder or "", info.bidAmount or 0, info.buyoutAmount, info.timeLeft))	
	
		-- local itemName, _, count, _, _, _, _, _, 
			-- _, buyoutPrice, bidPrice, _, ownerName = C_AuctionHouse.GetReplicateItemInfo("bidder", i);
			
		-- if itemName then
			-- local link = C_AuctionHouse.GetReplicateItemLink("bidder", i)
			-- if not link:match("battlepet:(%d+)") then		-- temporarily skip battle pets
				-- local id = tonumber(link:match("item:(%d+)"))
				-- local timeLeft = C_AuctionHouse.GetReplicateItemTimeLeft("bidder", i)
			
				-- TableInsert(char.Bids, format("%s|%s|%s|%s|%s|%s|%s", 
					-- AHZone, itemID, info.quantity, info.bidder or "", info.bidAmount, info.buyoutAmount, info.timeLeft))
			-- end
		-- end
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
	addon:StopListeningTo("OWNED_AUCTIONS_UPDATED")
	addon:StopListeningTo("AUCTION_HOUSE_AUCTION_CREATED")
	addon:StopListeningTo("BIDS_UPDATED")
end

local function OnAuctioneerHide(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.Auctioneer then
		OnAuctionHouseClosed()
	end
end

local function OnAuctionHouseShow()
	addon:ListenTo("AUCTION_HOUSE_CLOSED", OnAuctionHouseClosed)
	addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", OnAuctioneerHide)
	addon:ListenTo("OWNED_AUCTIONS_UPDATED", ScanAuctions)
	addon:ListenTo("AUCTION_HOUSE_AUCTION_CREATED", ScanAuctions)
	addon:ListenTo("BIDS_UPDATED", ScanBids)
	
	local char = thisCharacter
	char.lastUpdate = time()
	char.lastVisitDate = date("%Y/%m/%d %H:%M")
end

local function OnAuctioneerShow(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.Auctioneer then
		OnAuctionHouseShow()
	end
end


DataStore:OnAddonLoaded(addonName, function()
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

DataStore:OnPlayerLogin(function()
	addon:ListenTo("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)
	addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnAuctioneerShow)
end)
