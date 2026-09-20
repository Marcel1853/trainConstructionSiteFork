-- 0.5.8: Builder-Daten reparieren.
-- Bis 0.5.7 wurden Builder beim Abbauen/Zusammenführen umnummeriert, ohne die Controller
-- anzupassen. Danach zeigten Controller auf fremde oder leere Builder und Wagen auf falsche
-- Nummern. Hier werden alle Builder aus den gespeicherten Wagen neu aufgebaut und die
-- Controller neu verbunden (siehe scripts/assembly/builders.lua).
-- Läuft vor on_configuration_changed, daher erst prüfen, ob die Tabellen existieren.
if storage.TA_data and storage.TA_data["trainAssemblers"] and storage.TA_data["trainBuilders"] and
   storage.TC_data and storage.TC_data["trainControllers"] and storage.TC_data["prototypeData"] then
  Trainassembly:rebuildTrainBuilders()
end
