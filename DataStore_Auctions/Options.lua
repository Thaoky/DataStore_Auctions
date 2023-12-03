if not DataStore then return end

local addonName = "DataStore_Auctions"
local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addon:SetupOptions()
	local f = DataStore.Frames.AuctionsOptions
	
	DataStore:AddOptionCategory(f, addonName, "DataStore")
	
	-- localize options
	DataStoreAuctionsOptions_SliderLastVisit.tooltipText = L["LAST_VISIT_SLIDER_TOOLTIP"]
	DataStoreAuctionsOptions_SliderLastVisitLow:SetText("10")
	DataStoreAuctionsOptions_SliderLastVisitHigh:SetText("30")
	
	-- restore saved options to gui
	f.CheckLastVisit:SetChecked(DataStore:GetOption(addonName, "CheckLastVisit"))
	f.AutoClearExpiredItems:SetChecked(DataStore:GetOption(addonName, "AutoClearExpiredItems"))
end
