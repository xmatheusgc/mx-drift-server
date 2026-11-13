import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
import assert from 'node:assert/strict';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(src,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(src),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'environment');
for(const p of ['resources/[mx]/mx-freeroam-core/shared.lua','development/tests/admin-tools-env.lua','resources/[mx]/mx-freeroam-admin/tools-server.lua','resources/[mx]/mx-freeroam-experience/camera-developer.lua','development/tests/camera-developer.lua'])run(await readFile(p,'utf8'),p);
const code=ts.transpile(await readFile('development/ui/src/camera-developer-math.ts','utf8'),{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022});
const {moveCamera,rotateCamera}=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
const pose={position:{x:0,y:0,z:0},rotation:{x:0,y:0,z:0},fov:60};
for(const fps of [30,60,144]){let p=pose;for(let i=0;i<fps;i++)p=moveCamera(p,new Set(['KeyW']),1/fps,1);assert(Math.abs(p.position.y-1)<1e-9);}
const diagonal=moveCamera(pose,new Set(['KeyW','KeyD']),.05,1);assert(Math.abs(Math.hypot(diagonal.position.x,diagonal.position.y)-.05)<1e-9);
assert.equal(moveCamera(pose,new Set(['KeyE','ShiftLeft']),.05,1).position.z,.2);
assert.equal(moveCamera(pose,new Set(['KeyQ','ControlLeft']),.05,1).position.z,-.0125);
assert.deepEqual(pose.position,{x:0,y:0,z:0});console.log('Camera movement: FPS independence, diagonal normalization, precision/acceleration and immutable input passed.');
const rotated=rotateCamera(pose,10,10),precise=rotateCamera(pose,10,10,true);
assert.equal(rotated.rotation.x,-.4);assert.equal(precise.rotation.x,-.1);
assert.deepEqual(rotated.position,pose.position);assert.equal(rotated.fov,pose.fov);
assert.equal(rotateCamera(pose,0,10000).rotation.x,-89);
console.log('Mouse rotation: 0.04 degrees/pixel, Ctrl precision, pitch bounds and unchanged position/FOV passed.');
