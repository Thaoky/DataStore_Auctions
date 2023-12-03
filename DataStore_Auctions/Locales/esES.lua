local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Auctions", "esES")

if not L then return end

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Objetos con tiempo terminado permanecen en la base de datos hasta que el jugador visite de nuevo la casa de subastas."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Objetos con tiempo terminado son borrados automáticamente de la base de datos."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Borrar automáticamente subastas y pujas terminadas"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Borrar objetos de la Casa de Subastas"

L["LAST_VISIT_SLIDER_TOOLTIP"] = "Avisar cuando la casa de subastas no ha sido visitada desde hace más días que este valor"
L["LAST_VISIT_CHECK_DISABLED"] = "No se comprobará la hora de la última visita a la casa de subastas."
L["LAST_VISIT_CHECK_ENABLED"] = "Se comprobará la hora de la última visita a la casa de subastas de cada personaje. Los complementos del cliente recibirán una notificación por cada personaje que no haya visitado la casa de subastas durante más tiempo que este valor."
L["LAST_VISIT_CHECK_LABEL"] = "Última visita a la casa de subastas"
L["LAST_VISIT_CHECK_TITLE"] = "Comprobar la hora de la última visita"
