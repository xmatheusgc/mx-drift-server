import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const f of ['resources/[mx]/mx-freeroam-menu/navigation.lua','development/tests/navigation.lua','development/tests/interface-navigation.lua']){
 const code=await readFile(f,'utf8');if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(f))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));
}
