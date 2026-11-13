import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const core=await readFile('resources/[mx]/mx-freeroam-core/config.lua','utf8');
const config=await readFile('resources/[mx]/mx-freeroam-experience/config.lua','utf8');
const api=await readFile('development/ui/src/api.ts','utf8');
const scene=Number(config.match(/streaming=\{timeout=(\d+)/)[1]),sceneCall=Number(core.match(/\['experience:scene'\]=(\d+)/)[1]);
const request=Number(core.match(/requestTimeout=(\d+)/)[1]);
assert(sceneCall>scene+10000,'scene RPC must cover character preparation and streaming');
assert(request>sceneCall+35000+4*12000,'outer request must cover scene, selected vehicle and cleanup');
assert(Number(api.match(/AbortSignal.timeout\((\d+)\)/)[1])>request,'browser must wait for the structured core result');
async function suite(files,code){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const run=(text,name)=>{if(lauxlib.luaL_loadbuffer(L,to_luastring(text),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));};
 run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'bootstrap');
 for(const file of files)run(await readFile(file,'utf8'),file);
 run(code,'loading-recovery');
}
await suite(['resources/[mx]/mx-freeroam-core/shared.lua'],`
local handler,ack
function RegisterNetEvent(_,fn)handler=fn end
function CreateThread(fn)fn()end
function TriggerServerEvent(_,token,ok,data)ack={token=token,ok=ok,data=data}end
json.encode=function()return 'client error diagnostic (adapter)'end
MX.clients('fixture',{expected=function()MX.fail('SCENE_STREAM','Aguardando interior da oficina')end,broken=function()error('private runtime detail')end})
source=65535 handler('one','expected',{})
assert(not ack.ok and ack.data.failure.code=='SCENE_STREAM' and ack.data.failure.message=='Aguardando interior da oficina')
handler('two','broken',{})
assert(not ack.ok and ack.data.failure.code=='UNAVAILABLE' and not ack.data.failure.message:find('private runtime detail',1,true),'unexpected diagnostics stay local')
source=1 handler('forged','expected',{})
assert(ack.token=='two','non-server commands are ignored')
print('Client failure envelope: domain messages preserved, raw exceptions stay local, server-source guard retained (adapters).')
`);
await suite(['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','resources/[mx]/mx-freeroam-experience/rules.lua','development/tests/session-car-env.lua','resources/[mx]/mx-freeroam-experience/server.lua','development/tests/entry-server.lua'],`
local T=SessionTest local R=T.routes local failAt=nil local aborts=0 local prepared=0
MX.callClient=function(src,domain,action,data)
 if action=='prepareEntry' then prepared=prepared+1 end
 if action=='abort' then aborts=aborts+1 return {held=true,recovered=false} end
 if action==failAt then MX.fail('SCENE_STREAM','Aguardando interior da oficina') end
 return {ready=true}
end
for _,stage in ipairs({'fade','scene','previewChanged'}) do
 failAt=nil assert(R.lobby(40,{},T.actor).sceneReady)
 local before=aborts failAt=stage
 local ok,err=pcall(R.enter,40,{},T.actor)
 assert(not ok and err.code=='SCENE_STREAM' and err.message:find('entrada inicial permanece protegida',1,true),'transition failure remains useful and recoverable: '..stage)
 assert(aborts==before+1 and T.buckets[40]==0 and T.preview==nil,'rollback clears failed private scene and preview: '..stage)
 failAt=nil local entries=prepared
 assert(R.lobby(40,{},T.actor).sceneReady and prepared==entries+1,'retry establishes a new session instead of reusing partial context')
 assert(R.enter(40,{},T.actor).token,'workshop transition succeeds after retry')
end
print('Loading recovery: actual lobby/workshop routes roll back fade, scene and preview failures; fresh lobby retry and subsequent garage entry pass (adapters).')
`);
await suite(['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','development/tests/loading-recovery-env.lua','resources/[mx]/mx-freeroam-experience/client.lua'],`
local T=LoadingRecoveryTest
T.exports.ShowLobby()
local function up(fn,name,value)
 for i=1,60 do local key,old=debug.getupvalue(fn,i) if key==name then if value~=nil then debug.setupvalue(fn,i,value)end return old end end
 error('missing upvalue '..name)
end
up(T.handlers.scene,'active',true)
up(T.handlers.scene,'sceneGeneration',10)
T.restore=function()assert(up(T.handlers.scene,'sceneGeneration')>10 and T.stopped,'old scene invalidated before rollback can yield')end
local recovered=T.exports.RecoverEntry()
assert(recovered.held and not recovered.recovered and T.frozen and not T.control,'first join stays protected')
assert(T.fade and T.loading==false and not T.exports.InWorkshop(),'rollback removes black fade/loading and active partial scene')
assert(T.lobby and T.lobby.sceneReady==false and T.lobby.error,'opaque lobby exposes retry instead of unloaded world')
assert(T.exports.RecoverEntry().held and T.loading==false,'repeated recovery is safe')
print('Loading recovery: actual client invalidates late scene before restore, clears fade/status, keeps first player frozen and exposes retry (adapters).')
`);

await suite(['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','development/tests/loading-recovery-env.lua','resources/[mx]/mx-freeroam-experience/client.lua','resources/[mx]/mx-freeroam-experience/presentation.lua'],`
local place
for i=1,60 do local name,value=debug.getupvalue(LoadingRecoveryTest.handlers.previewChanged,i) if name=='placeCharacter' then place=value break end end
assert(place)
local function set(name,value)
 for i=1,60 do local key=debug.getupvalue(place,i) if key==name then debug.setupvalue(place,i,value) return end end
 error(name)
end
local time=0 local position
function GetGameTimer()return time end
function Wait(ms)time=time+ms end
function RequestCollisionAtCoord()end
function GetGroundZFor_3dCoord()return false,0 end
function HasCollisionLoadedAroundEntity()return false end
function SetEntityCoordsNoOffset(_,x,y,z)position={x=x,y=y,z=z}end
function SetEntityHeading()end
function TaskStandStill()end
for _,context in ipairs({'lobby','garage'})do
 set('active',true) set('sceneContext',context)
 local before=time place()
 local expected=(context=='lobby' and ExperienceConfig.lobbyScene or ExperienceConfig.scene).ped
 assert(position.x==expected.x and position.y==expected.y and position.z==expected.z,'missing floor retains authored presentation')
 assert(LoadingRecoveryTest.frozen and time-before<=2030,'presentation remains frozen without waiting for collision')
end
print('Missing presentation ground/collision: real placement succeeds in lobby and garage, preserving frozen authored pose (adapters).')
`);
