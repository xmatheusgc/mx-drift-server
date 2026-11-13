import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(text,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(text),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'bootstrap');
for(const file of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','resources/[mx]/mx-freeroam-experience/rules.lua','resources/[mx]/mx-freeroam-experience/character.lua'])run(await readFile(file,'utf8'),file);
run(`
local model='mp_m_freemode_01' local seen={} local overlays,props={},{} local ped=10 local writes={blend=0,feature=0,component=0,prop=0}
MX.copy=function(t)if type(t)~='table'then return t end local r={}for k,v in pairs(t)do r[k]=MX.copy(v)end return r end
function PlayerPedId()return ped end
function PlayerId()return 0 end
function joaat(v)return v end
function GetEntityModel()return model end
function RequestModel()end
function HasModelLoaded()return true end
function GetGameTimer()return 0 end
function SetPlayerModel(_,m)model=m ped=ped+1 end
function SetModelAsNoLongerNeeded()end
function GetPedDrawableVariation()return 0 end
function GetNumberOfPedDrawableVariations()return 20 end
function GetNumberOfPedTextureVariations()return 4 end
function GetPedPropIndex()return -1 end
function GetNumberOfPedPropDrawableVariations()return 5 end
function GetNumberOfPedPropTextureVariations()return 3 end
function GetPedHeadOverlayNum()return 12 end
function SetPedHeadBlendData()writes.blend=writes.blend+1 end
function SetPedFaceFeature(_,i,v)seen[i]=v writes.feature=writes.feature+1 end
function SetPedHeadOverlay(_,i,v)overlays[i]=v end
function SetPedHeadOverlayColor()end
function SetPedComponentVariation()writes.component=writes.component+1 end
function ClearPedProp(_,i)props[i]=-1 end
function SetPedPropIndex(_,i,v)props[i]=v end
function SetPedHairColor()end
function SetPedEyeColor()end
function GetPedBoneCoords()error('animated bones must never drive region layout')end
function GetModelDimensions()return {x=-.3,y=-.15,z=-1},{x=.3,y=.15,z=1}end
function GetOffsetFromEntityInWorldCoords(p,x,y,z)assert(p==ped)return {x=x,y=y,z=z}end
function GetScreenCoordFromWorldCoord(x,y,z)return true,.5+x*.1,.5-z*.3 end
for _,name in ipairs({'mp_m_freemode_01','mp_f_freemode_01'})do
 local a=ExperienceRules.preset(name) a.features[1]=.01 a.features[2]=-.37
 local caps=Character.apply(a)
 assert(seen[0]==.01 and seen[1]==-.37,'fine values reach actual native unchanged')
 assert(overlays[0]==255 and props[0]==-1,'none removes overlays and props')
 assert(#caps.components==12 and #caps.props==8 and #caps.overlays==13)
 local anchors=Character.anchors()
 assert(anchors.head.x==anchors.feet.x and anchors.head.x>.53 and anchors.head.y<anchors.torso.y and anchors.torso.y<anchors.legs.y and anchors.legs.y<anchors.feet.y,'fixed aligned markers are distributed by model bounds')
 local before=MX.copy(writes) Character.apply(a)
 assert(writes.blend==before.blend and writes.feature==before.feature and writes.component==before.component,'ACK validation does not reset identical appearance')
 a.components[12].drawable=1 Character.apply(a)
 assert(writes.component==before.component+1 and writes.blend==before.blend and writes.feature==before.feature,'equipping one garment writes just that garment')
 before=MX.copy(writes) a.features[1]=.02 Character.apply(a)
 assert(writes.feature==before.feature+1 and writes.blend==before.blend and writes.component==before.component,'fine facial edit does not reset blend or clothes')
 a.components[12].drawable=99 assert(not pcall(Character.apply,a),'unsupported outfit is rejected')
 assert(writes.feature==before.feature+1 and writes.component==before.component,'invalid drafts do not partially apply')
end
print('Character native adapters: both models, fine values, static model layout, identical ACK/no reset, garment/feature deltas and invalid-draft atomicity passed.')
`, 'native-character-tests');
// Parse the changed live client as well as the small module exercised above.
const client=await readFile('resources/[mx]/mx-freeroam-experience/client.lua','utf8');
if(lauxlib.luaL_loadbuffer(L,to_luastring(client),null,to_luastring('client.lua'))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
