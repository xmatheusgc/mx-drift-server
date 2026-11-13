-- Load the selected vehicle on demand; do not preload the entire mod catalogue.
VehicleAssets={intent=nil}
function VehicleAssets.setIntent(intent) VehicleAssets.intent=intent end
function VehicleAssets.load(model,intent)
    local hash=joaat(model)
    local function cancelled() return intent~=nil and intent~=VehicleAssets.intent end
    if cancelled() then return {loaded=false,cancelled=true} end
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return {loaded=false} end
    RequestModel(hash)
    local deadline=GetGameTimer()+VehicleConfig.modelLoadTimeout
    local nextReport=0
    while not HasModelLoaded(hash) and not cancelled() and GetGameTimer()<deadline do
        if GetGameTimer()>=nextReport then
            nextReport=GetGameTimer()+1000
            TriggerEvent('mx:loadingProgress',{message='Carregando o veículo selecionado: '..tostring(model)})
        end
        Wait(50)
    end
    local loaded=not cancelled() and HasModelLoaded(hash)
    if not loaded then SetModelAsNoLongerNeeded(hash) end
    return {loaded=loaded,cancelled=cancelled()}
end
