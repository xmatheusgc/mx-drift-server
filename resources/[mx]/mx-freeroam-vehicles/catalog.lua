-- Legacy identities remain valid for existing saved cars, but never enter Showroom.
local legacy=MX.copy(VehicleConfig.catalog)
exports('ShowroomModel',function(model)
    local row=VehicleConfig.catalog[model]
    return row and row.source=='vehicles' and not row.conflict and MX.online(row.asset) or false
end)
AddEventHandler('mx:vehicles:catalogIndex',function(text)
    local data=json.decode(text) local nextCatalog=MX.copy(legacy)
    for _,row in ipairs(data.rows or {}) do
        nextCatalog[row.model]=row
    end
    VehicleConfig.catalog=nextCatalog
end)
