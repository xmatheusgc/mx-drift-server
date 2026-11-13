-- Exercise the actual placement closure, not a duplicate placement algorithm.
local handler=LobbyAckTest.handlers.previewChanged local place
for i=1,40 do local name,value=debug.getupvalue(handler,i)if name=='placeCharacter'then place=value break end end
assert(place,'actual placement callback is reachable')
local saved={}
local function set(name,value)
 for i=1,40 do local key,old=debug.getupvalue(place,i)if key==name then saved[#saved+1]={i,old}debug.setupvalue(place,i,value)return end end
 error('missing placement upvalue '..name)
end
local oldGround,oldCollision,oldCoords,oldHeading,oldBones=GetGroundZFor_3dCoord,HasCollisionLoadedAroundEntity,SetEntityCoordsNoOffset,SetEntityHeading,GetPedBoneCoords
local oldRequest=RequestCollisionAtCoord
RequestCollisionAtCoord=function()end
GetGroundZFor_3dCoord=function()return true,99 end
HasCollisionLoadedAroundEntity=function()return true end
local positioned={}
SetEntityCoordsNoOffset=function(_,x,y,z)positioned.x=x positioned.y=y positioned.z=z end
SetEntityHeading=function(_,h)positioned.h=h end
GetPedBoneCoords=function()error('fixed position must not be derived from transient feet')end
for _,context in ipairs({'garage','lobby'})do
 set('active',true)set('previewEntity',0)set('sceneContext',context)
 place()
 local expected=(context=='lobby'and ExperienceConfig.lobbyScene or ExperienceConfig.scene).ped
 assert(positioned.x==expected.x and positioned.y==expected.y and positioned.z==expected.z and positioned.h==expected.h,'actual client preserves authored '..context..' pose after ground/collision checks')
 for i=#saved,1,-1 do debug.setupvalue(place,saved[i][1],saved[i][2])end saved={}
end
GetGroundZFor_3dCoord,HasCollisionLoadedAroundEntity,SetEntityCoordsNoOffset,SetEntityHeading,GetPedBoneCoords=oldGround,oldCollision,oldCoords,oldHeading,oldBones
RequestCollisionAtCoord=oldRequest
print('Actual menu client placement: fixed lobby/garage XYZ and heading survive ground/collision confirmation (native adapters).')
