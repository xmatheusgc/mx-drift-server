ScenePoseTest={time=0,delay=0,entities={[1]={model=10,male=true,x=0,y=0,z=0,h=0},[2]={model=20,male=false,tag='actor',x=0,y=0,z=0,h=0}},requested={},removed={},events={},plays={},missing={},warnings=0,bones=0}
local T=ScenePoseTest
MX.copy=function(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=MX.copy(x)end return r end
json.encode=function(v)if v.level=='warn'then T.warnings=T.warnings+1 end return '{}'end
function GetGameTimer()return T.time end
function PlayerPedId()return 1 end
function GetCurrentResourceName()return 'mx-freeroam-experience'end
function DoesEntityExist(ped)return T.entities[ped]~=nil end
function GetEntityModel(ped)return T.entities[ped].model end
function IsPedMale(ped)return T.entities[ped].male end
function Entity(ped)return {state={mxWorkshopActor=T.entities[ped].tag}}end
function DoesAnimDictExist(dict)return not T.missing[dict] end
function RequestAnimDict(dict)T.requested[dict]=T.time end
function HasAnimDictLoaded(dict)return T.time>=(T.requested[dict]or math.huge)+T.delay end
function GetAnimDuration()return T.invalidClip and 0 or 3 end
function TaskPlayAnim(ped,dict,clip,blend,out,duration,flag,rate,x,y,z)
 T.plays[#T.plays+1]={ped=ped,dict=dict,clip=clip,blend=blend,flag=flag,lock=x and y and z}
 if not T.playFailure then T.entities[ped].playing=dict..':'..clip end
end
function IsEntityPlayingAnim(ped,dict,clip)return T.entities[ped].playing==dict..':'..clip end
function StopAnimTask(ped,dict,clip)T.stopped=ped if T.entities[ped].playing==dict..':'..clip then T.entities[ped].playing=nil end end
function RemoveAnimDict(dict)T.removed[dict]=(T.removed[dict]or 0)+1 end
function AddEventHandler(name,fn)local old=T.events[name]T.events[name]=old and function(...)old(...)fn(...)end or fn end
function ClearPedTasksImmediately(ped)T.entities[ped].playing=nil end
function SetEntityCoordsNoOffset(ped,x,y,z)local p=T.entities[ped]p.x=x p.y=y p.z=z end
function SetEntityHeading(ped,h)T.entities[ped].h=h end
function GetPedBoneCoords(ped)T.bones=T.bones+1 return {z=T.entities[ped].z-1}end
function SetPedCanRagdoll()end
function TaskStandStill()end
function FreezeEntityPosition(ped,value)T.entities[ped].frozen=value end
