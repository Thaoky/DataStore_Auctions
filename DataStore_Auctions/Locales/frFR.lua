local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Auctions", "frFR" )

if not L then return end

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Les objets expirés restent dans la base de données jusqu'à la prochaine visite du joueur à l'hôtel des ventes."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Les objets expirés sont automatiquement effacés de la base de données."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Effacer automatiquement les enchères et les offres"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Effacer les objets de l'hôtel des ventes"

