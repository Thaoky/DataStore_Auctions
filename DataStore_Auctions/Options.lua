if not DataStore then return end

local addonName, addon = ...

function addon:SetupOptions()
	local f = DataStore.Frames.AuctionsOptions
	
	DataStore:AddOptionCategory(f, addonName, "DataStore")
	
	-- localize options
	local L = DataStore:GetLocale(addonName)
	
	DataStoreAuctionsOptions_SliderLastVisit.tooltipText = L["LAST_VISIT_SLIDER_TOOLTIP"]
	DataStoreAuctionsOptions_SliderLastVisitLow:SetText("10")
	DataStoreAuctionsOptions_SliderLastVisitHigh:SetText("30")
	
	-- restore saved options to gui
	local options = DataStore_Auctions_Options

	f.CheckLastVisit:SetChecked(options.CheckLastVisit)
	f.AutoClearExpiredItems:SetChecked(options.AutoClearExpiredItems)
end
