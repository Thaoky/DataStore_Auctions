local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Auctions", "enUS", true, debug)

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Expired items remain in the database until the player next visits the auction house."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Expired items are automatically deleted from the database."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Automatically clear expired auctions and bids"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Clear Auction House items"

L["LAST_VISIT_SLIDER_TOOLTIP"] = "Warn when auction house has not been visited since more days than this value"
L["LAST_VISIT_CHECK_DISABLED"] = "The time of the last auction house visit will not be checked."
L["LAST_VISIT_CHECK_ENABLED"] = "The time of the last auction house visit of each character will be checked. Client add-ons will get a notification for each character who has not visited the auction house for longer than this value."
L["LAST_VISIT_CHECK_LABEL"] = "Last Auction House Visit"
L["LAST_VISIT_CHECK_TITLE"] = "Check Last Visit Time"
