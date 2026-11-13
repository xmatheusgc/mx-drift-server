-- Simulate a modkit-only livery and an extra exposed only after installing a part.
VehicleApplyTest={cars={},liveryWrites=0}
local T=VehicleApplyTest
for _,id in ipairs({71,72})do T.cars[id]={id='test:'..id,mods={},family=0,extras={},primary=0,secondary=0}end
function GetGameTimer()return 0 end
function CreateThread()end
function AddStateBagChangeHandler()end
function AddEventHandler()end
T.exports={} exports=setmetatable({},{__call=function(_,name,fn)T.exports[name]=fn end})
function GetInvokingResource()return T.invoker end
MX.clients=function(_,handlers)T.handlers=handlers end
VehicleNetwork={resolve=function(net,id)return T.cars[net] and T.cars[net].id==id and net or 0 end}
VehicleStance={supported=function()return true end,restore=function()end,apply=function()end,current=function()return false end,refresh=function()end}
VehicleStance.ensure=function()return {value=false}end
VehicleStance.options=function()return {available=true,ranges=VehicleStanceRules.ranges}end
function DoesEntityExist(v)return T.cars[v]~=nil end
function Entity(v)return {state={mxVehicle=T.cars[v].id}}end
function NetworkRequestControlOfEntity()end
function NetworkHasControlOfEntity()return T.control~=false end
function GetVehicleWheelType(v)return T.cars[v].family end
function SetVehicleWheelType(v,n)T.cars[v].family=n T.cars[v].mods[48]=-1 end
function GetVehicleMod(v,n)return T.cars[v].mods[n] or -1 end
function SetVehicleMod(v,n,value)T.cars[v].mods[n]=value end
function GetVehicleModVariation()return false end
function GetNumVehicleMods(_,n)return ({[0]=3,[23]=300,[48]=4})[n] or 0 end
function GetVehicleLiveryCount()return -1 end
function GetVehicleLivery()return -1 end
function SetVehicleLivery(v)T.liveryWrites=T.liveryWrites+1 T.cars[v].mods[48]=0 end
function GetVehicleRoofLiveryCount()return 0 end
function GetVehicleRoofLivery()return -1 end
function GetVehicleInteriorColor()return 0 end
function GetVehicleDashboardColor()return 0 end
function DoesExtraExist(v,n)return n==1 and GetVehicleMod(v,0)==1 end
function IsVehicleExtraTurnedOn(v,n)return T.cars[v].extras[n]==true end
function SetVehicleExtra(v,n,disabled)T.cars[v].extras[n]=disabled==0 end
function SetVehicleColours(v,a,b)T.cars[v].primary=a T.cars[v].secondary=b end
function GetVehicleColours(v)return T.cars[v].primary,T.cars[v].secondary end
function GetEntityModel()return 'modkit-extra-test' end
function GetModelDimensions()return {x=-1,y=-2,z=0},{x=1,y=2,z=1.5}end
function GetEntityBoneIndexByName()return 1 end
function GetModSlotName()return ''end
function GetGameBuildNumber()return 3258 end
for _,name in ipairs({'SetVehicleModKit','ClearVehicleCustomPrimaryColour','ClearVehicleCustomSecondaryColour','SetVehicleModColor_1','SetVehicleModColor_2','SetVehicleExtraColours','SetVehicleCustomPrimaryColour','SetVehicleCustomSecondaryColour','SetVehicleInteriorColor','SetVehicleDashboardColor','SetVehicleRoofLivery','ClearVehicleXenonLightsCustomColor','SetVehicleXenonLightsColor','SetVehicleXenonLightsCustomColor','ToggleVehicleMod','SetVehicleNumberPlateText','SetVehicleNumberPlateTextIndex','SetVehicleWindowTint','SetVehicleNeonLightEnabled','SetVehicleNeonLightsColour','SetVehicleTyreSmokeColor'})do _G[name]=function()end end
