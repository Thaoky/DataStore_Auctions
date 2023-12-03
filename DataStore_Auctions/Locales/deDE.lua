local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Auctions", "deDE" )

if not L then return end

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Abgelaufene Gegensände verbleiben in der Datenbank bis der Spieler das nächste Mal das Auktionshaus besucht."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Abgelaufene Gegenstände werden automatisch aus der Datenbank gelöscht."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Automatisch abgelaufene Auktionen und Gebote löschen."
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Gegenstände im Auktionshaus löschen"

