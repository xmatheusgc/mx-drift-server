local T=DriftTest
T.commands={} T.gearExports={} T.messages={} T.manualCreates=0 T.manualDestroys=0 T.manualUpdates=0 T.shifts=0
T.driving=1 T.provider='started'
Config.Hud=false Config.DefaultManual=true
exports=setmetatable({['mx-freeroam-vehicles']={IsDriftHandlingApplied=function(_,v)
 if T.exportFailure then error('provider unavailable') end
 return VehicleDrift.isApplied(v)
end}},{__call=function(_,name,fn)T.gearExports[name]=fn end})
function RegisterCommand(name,fn)T.commands[name]=fn end
function RegisterKeyMapping()end
function PlayerPedId()return 101 end
function IsEntityDead()return false end
function GetVehiclePedIsIn()return T.driving end
function GetPedInVehicleSeat()return 101 end
function GetVehicleClass()return 0 end
function GetEntityModel(v)return v end
function joaat(v)return v end
function GetResourceState(name)return name=='mx-freeroam-vehicles' and T.provider or 'missing' end
function GetVehicleMod()return -1 end
function IsInputDisabled()return not T.controller end
function IsNuiFocused()return T.nui==true end
function IsPauseMenuActive()return T.pause==true end
function DisableControlAction()T.controlBlocks=(T.controlBlocks or 0)+1 end
function IsDisabledControlJustPressed(_,control)return control==Config.Controller.ShiftUp end
function GetFrameTime()return .016 end
function GetDisabledControlNormal()return 0 end
function IsControlPressed()return false end
function GetVehicleCurrentRpm()return .3 end
function GetVehicleCurrentGear()return 1 end
function GetIsVehicleEngineRunning()return true end
function SetVehicleCheatPowerIncrease()end
-- Transmission double deliberately changes physics until Destroy restores it.
-- Drift and the gearbox main loop below are the actual production controllers.
function CreateGearbox(v)
 T.manualCreates=T.manualCreates+1
 local gear,brake=T.cars[v].highGear,T.cars[v].fields.fBrakeForce
 T.cars[v].highGear=1 T.cars[v].fields.fBrakeForce=99
 local box={vehicle=v,nativeTransmissionMod=-1,mods={}}
 function box:Destroy()
  T.manualDestroys=T.manualDestroys+1
  T.cars[v].highGear=gear T.cars[v].fields.fBrakeForce=brake
 end
 function box:Update(_,input)
  T.manualUpdates=T.manualUpdates+1 T.clutch=input.clutch
  return 1,{rpm=.3,gear=1,engineOn=true}
 end
 function box:ShiftUp()T.shifts=T.shifts+1 end
 function box:ShiftDown()T.shifts=T.shifts+1 end
 function box:RequestShift()T.shifts=T.shifts+1 return true end
 function box:GetCurrentGear()return 1 end
 function box:GetLogicalRpm()return 2000 end
 function box:GetData()return {gear=1}end
 function box:SetUpgrade()return true end
 return box
end
