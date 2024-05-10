--[[	*** DataStore_Auctions ***
Written by : Thaoky, EU-Marécages de Zangar
July 15th, 2009
--]]
if not DataStore then return end

local addonName, addon = ...
local thisCharacter

local DataStore, TableInsert, TableRemove, format, strsplit, tonumber = DataStore, table.insert, table.remove, format, strsplit, tonumber
local GetNumAuctionItems, GetAuctionItemInfo, GetAuctionItemLink, GetAuctionItemTimeLeft = GetNumAuctionItems, GetAuctionItemInfo, GetAuctionItemLink, GetAuctionItemTimeLeft
local C_Map, time, date = C_Map, time, date

local isVanilla = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

-- *** Utility functions ***
local function ClearEntries(auctionsList, AHZone)
	-- this function clears the "auctions" or "bids" of a specific AH (faction or goblin)
	-- auctionsList = character.Auctions or character.Bids (the name of the table in the DB)
	-- AHZone = 0 for player faction, or 1 for goblin
	local ah = auctionsList
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
	local numAuctions = GetNumAuctionItems("owner")
	
	char.lastUpdate = now
	char.lastAuctionsScan = nil
	if numAuctions > 0 then
		char.lastAuctionsScan = now
	end
	
	ClearEntries(char.Auctions, AHZone)
		
	for i = 1, GetNumAuctionItems("owner") do
		local itemName, _, count, _, _, _, _, startPrice, 
			_, buyoutPrice, _, highBidder, _, _, _, saleStatus, itemID =  GetAuctionItemInfo("owner", i)
			
		-- do not list sold items, they're supposed to be in the mailbox
		if saleStatus and saleStatus == 1 then		-- just to be sure, in case Bliz ever returns nil
			saleStatus = true
		else
			saleStatus = false
		end
			
		if itemName and itemID and not saleStatus then
			local link = GetAuctionItemLink("owner", i)
			local timeLeft = GetAuctionItemTimeLeft("owner", i)
			char.Auctions = char.Auctions or {}
			TableInsert(char.Auctions, format("%s|%s|%s|%s|%s|%s|%s", 
				AHZone, itemID, count, highBidder or "", startPrice, buyoutPrice, timeLeft))
		end
	end
	
	DataStore:Broadcast("DATASTORE_AUCTIONS_UPDATED")
end

local function ScanBids()
	local AHZone = GetAuctionHouseZone()
	
	local char = thisCharacter
	char.lastUpdate = time()
	char.lastVisitDate = date("%Y/%m/%d %H:%M")
	
	ClearEntries(char.Bids, AHZone)
		
	for i = 1, GetNumAuctionItems("bidder") do
		local itemName, _, count, _, _, _, _, _, 
			_, buyoutPrice, bidPrice, _, ownerName = GetAuctionItemInfo("bidder", i)
			
		if itemName then
			local link = GetAuctionItemLink("bidder", i)
			if not link:match("battlepet:(%d+)") then		-- temporarily skip battle pets
				local id = tonumber(link:match("item:(%d+)"))
				local timeLeft = GetAuctionItemTimeLeft("bidder", i)
				char.Bids = char.Bids or {}
				TableInsert(char.Bids, format("%s|%s|%s|%s|%s|%s|%s", 
					AHZone, id, count, ownerName or "", bidPrice, buyoutPrice, timeLeft))
			end
		end
	end
end

-- *** Event Handlers ***
local function OnAuctionHouseClosed()
	addon:StopListeningTo("AUCTION_HOUSE_CLOSED")
	addon:StopListeningTo("AUCTION_OWNED_LIST_UPDATE")
	addon:StopListeningTo("AUCTION_BIDDER_LIST_UPDATE")
	
	if not isVanilla then
		addon:StopListeningTo("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
	end
end

local function OnAuctioneerHide(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.Auctioneer then
		OnAuctionHouseClosed()
	end
end

local function OnAuctionHouseShow()
	addon:ListenTo("AUCTION_HOUSE_CLOSED", OnAuctionHouseClosed)
	addon:ListenTo("AUCTION_OWNED_LIST_UPDATE", ScanAuctions)
	addon:ListenTo("AUCTION_BIDDER_LIST_UPDATE", ScanBids)
	
	if not isVanilla then
		addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", OnAuctioneerHide)
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


DataStore:OnAddonLoaded(addonName, function()
	DataStore:RegisterModule({
		addon = addon,
		addonName = addonName,
		rawTables = {
			"DataStore_Auctions_Options"
		},
		characterTables = {
			["DataStore_Auctions_Characters"] = {
				ClearAuctionEntries = function(character, AHType, AHZone)
					-- this function clears the "auctions" or "bids" of a specific AH (faction or goblin)
					-- AHType = "Auctions" or "Bids" (the name of the table in the DB)
					-- AHZone = 0 for player faction, or 1 for goblin
					
					ClearEntries(character[AHType], AHZone)
				end,
			},
		}
	})
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Auctions_Characters", true)
end)

DataStore:OnPlayerLogin(function()
	addon:ListenTo("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)
	
	if not isVanilla then
		addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnAuctioneerShow)
	end
	
	addon:SetupOptions()
end)
