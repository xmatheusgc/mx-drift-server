-- Natives are explicit test doubles; no FiveM geometry or synchronization here.
StanceTest={entities={[7]={id='stance-a',model='futo',family=0,mod=2,wheels=4,size=.6,width=.25,height=.01,offset={[-1]=0,[0]=-.8,[1]=.8,[2]=-.82,[3]=.82},rotation={[0]=.02,[1]=-.02,[2]=0,[3]=0}}},handlers={},events={}}
local T=StanceTest
json.encode=function()return '{}'end
function MX.copy(value) if type(value)~='table' then return value end local result={} for k,v in pairs(value) do result[k]=MX.copy(v) end return result end
function DoesEntityExist(v) return T.entities[v]~=nil end
function Entity(v) return {state={mxVehicle=T.entities[v].id}} end
function GetEntityModel(v) return T.entities[v].model end
function GetVehicleWheelType(v) return T.entities[v].family end
function GetVehicleMod(v,slot) return slot==23 and T.entities[v].mod or -1 end
function IsThisModelACar() return true end
function GetVehicleNumberOfWheels(v) return T.entities[v].wheels end
function GetVehicleWheelSize(v) return T.entities[v].size end
function GetVehicleWheelWidth(v) return T.entities[v].width end
function GetVehicleSuspensionHeight(v) return T.entities[v].height end
function GetVehicleWheelXOffset(v,i) return T.entities[v].offset[i] end
function GetVehicleWheelYRotation(v,i) return T.entities[v].rotation[i] end
function SetVehicleSuspensionHeight(v,n) T.entities[v].height=n end
function SetVehicleWheelSize(v,n) T.sizeCalls=(T.sizeCalls or 0)+1 if n==0 then T.zeroSizeCalls=(T.zeroSizeCalls or 0)+1 end if T.failSize or n==0 then return false end if not T.ignoreSize then T.entities[v].size=n end return T.nativeResult~=nil and T.nativeResult or true end
function SetVehicleWheelWidth(v,n) T.widthCalls=(T.widthCalls or 0)+1 if n==0 then T.zeroWidthCalls=(T.zeroWidthCalls or 0)+1 end if T.failWidth or n==0 then return false end T.entities[v].width=n return T.nativeResult~=nil and T.nativeResult or true end
function SetVehicleWheelXOffset(v,i,n) T.entities[v].offset[i]=n end
function SetVehicleWheelYRotation(v,i,n) T.entities[v].rotation[i]=n end
function AddStateBagChangeHandler(k,_,fn) T.handlers[k]=fn end
function GetEntityFromStateBagName() return 7 end
function CreateThread() end
function AddEventHandler(k,fn) T.events[k]=fn end
function GetCurrentResourceName() return 'mx-freeroam-vehicles' end
