import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'base adapters');
for(const file of ['resources/[mx]/mx-freeroam-core/shared.lua','development/tests/trainer-menu-env.lua','resources/[mx]/mx-freeroam-menu/client.lua'])run(await readFile(file,'utf8'),file);
run(`
local T=TrainerMenuTest
local started=true local vehicle=10 local netId=55 local accepted=true local calls={}
function GetResourceState()return started and 'started' or 'stopped'end
function PlayerPedId()return 1 end
function GetVehiclePedIsIn()return vehicle end
function DoesEntityExist(v)return v==10 end
function NetworkGetEntityIsNetworked()return true end
function NetworkGetNetworkIdFromEntity()return netId end
local state={['mxsound:status']='paused',['mxsound:paused']=true,['mxsound:url']='fixture', ['mxsound:volume']=0.5,['mxsound:meta']={title='Fixture'},['mxsound:queue']={{meta={title='Next'}}}}
function Entity()return {state=state}end
exports['mx-soundcore']={}
for _,name in ipairs({'PlaySound','AddToQueue','PauseSound','ResumeSound','SkipTrack','StopSound','SetVolume'})do
 exports['mx-soundcore'][name]=function(_,v,a)calls[#calls+1]={name=name,vehicle=v,arg=a};return accepted end
end
assert(not T.nui('vehicleSound',{action='state'}).ok,'closed menu rejects sound access')
T.commands.mxtrainer()
local result=T.nui('vehicleSound',{action='state'})
assert(result.ok and result.data.vehicleId==55 and result.data.volume==15 and result.data.paused and result.data.meta.title=='Fixture','replicated playback state')
for action,name in pairs({play='PlaySound',queue='AddToQueue',pause='PauseSound',resume='ResumeSound',skip='SkipTrack',stop='StopSound',volume='SetVolume'})do
 assert(T.nui('vehicleSound',{action=action,vehicleId=55,input='Fixture',volume=1}).ok)
 assert(calls[#calls].name==name and calls[#calls].vehicle==10,'dispatch uses client export and actual vehicle')
end
assert(calls[#calls] and #calls==7)
local count=#calls
assert(not T.nui('vehicleSound',{action='play',vehicleId=54,input='Fixture'}).ok,'stale vehicle rejected')
for _,volume in ipairs({-1,31,0.5,'15'})do assert(not T.nui('vehicleSound',{action='volume',vehicleId=55,volume=volume}).ok)end
assert(not T.nui('vehicleSound',{action='play',vehicleId=55,input='   '}).ok)
assert(not T.nui('vehicleSound',{action='play',vehicleId=55,input=string.rep('x',2049)}).ok)
assert(not T.nui('vehicleSound',{action='unknown',vehicleId=55}).ok)
assert(#calls==count,'invalid requests never reach soundcore')
accepted=false assert(not T.nui('vehicleSound',{action='stop',vehicleId=55}).ok,'export rejection is propagated')
started=false assert(not T.nui('vehicleSound',{action='state'}).ok,'resource stopped')
started=true vehicle=0 assert(not T.nui('vehicleSound',{action='state'}).ok,'on foot')
vehicle=10 netId=56 assert(not T.nui('vehicleSound',{action='play',vehicleId=55,input='Fixture'}).ok,'vehicle changed while typing')
T.events['chat:addMessage']({args={'[mx-soundcore]','Aguarde antes de trocar'}})
assert(T.messages[#T.messages].type=='soundFeedback','server feedback forwarded to menu')
print('Soundcore menu: replicated state, seven client exports, stale vehicle, validation, unavailable resource, rejected dispatch and feedback passed (runtime adapters).')
`, 'soundcore menu contracts');
