local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Auctions", "enUS", true, true)

if not L then return end

L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Automatically clear expired auctions and bids"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Clear Auction House items"
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Expired items are automatically deleted from the database."
L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Expired items remain in the database until the player next visits the auction house."
