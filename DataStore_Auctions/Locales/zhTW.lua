local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Auctions", "zhTW" )

if not L then return end

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "過期的物品保留在數據庫中，直到玩家下次訪問拍賣場."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "過期物品將自動從數據庫中刪除."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "自動清除過期拍賣和投標"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "清除拍賣場的物品"

