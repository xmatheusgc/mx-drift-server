import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import ts from 'typescript';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'adapters');
for(const p of ['resources/[mx]/mx-freeroam-core/shared.lua','development/tests/admin-tools-env.lua','resources/[mx]/mx-freeroam-admin/tools-client.lua','resources/[mx]/mx-freeroam-admin/tools-server.lua','resources/[mx]/mx-freeroam-world/admin-travel.lua','resources/[mx]/mx-freeroam-admin/server.lua','development/tests/admin-tools.lua'])run(await readFile(p,'utf8'),p);
const code=ts.transpile(await readFile('development/ui/src/admin-coordinates.ts','utf8'),{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022});
const {parseCoordinates,coordinateText}=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
assert.deepEqual(parseCoordinates('vector4(100.5, -200, 6.2, 90)'),{x:100.5,y:-200,z:6.2,h:90});
assert.deepEqual(parseCoordinates('100 -200 6.2'),{x:100,y:-200,z:6.2});
for(const s of ['','NaN,0,0','0,0,Infinity','0,0,4000','1,2,3,361','1,2','1,2,3,4,5','1,2,3; execute()'])assert.throws(()=>parseCoordinates(s));
assert.equal(coordinateText({x:1,y:-2.5,z:3.12345,h:-90},'vector4'),'vector4(1.000, -2.500, 3.123, 270.00)');
assert.equal(coordinateText({x:1,y:2,z:3,h:90},'table'),'{x=1.000, y=2.000, z=3.000, h=90.00}');
assert.throws(()=>coordinateText({x:NaN,y:2,z:3,h:0},'vector3'));
console.log('Admin coordinate parsing/formatting: vector4, optional heading, bounds, invalid input and finite capture passed.');
