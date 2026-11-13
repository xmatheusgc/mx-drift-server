import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {serverRoot} from './workspace.mjs';
const local=(name)=>fileURLToPath(new URL('../node_modules/'+name,import.meta.url));
const tasks={
 build:[[local('typescript/bin/tsc'),'--noEmit','--project','development/tsconfig.json'],[local('vite/bin/vite.js'),'build','--config','development/vite.config.ts']],
 typecheck:[[local('typescript/bin/tsc'),'--noEmit','--project','development/tsconfig.json']],
 dev:[[local('vite/bin/vite.js'),'--config','development/vite.config.ts','--host','127.0.0.1']],
 check:[['development/tests/static.mjs']],test:[['development/tests/run-lua.mjs']],
 'test:db':[['development/tests/database.mjs']],'test:ui':[['development/tests/ui.mjs']],'test:lobby':[['development/tests/lobby.mjs']],
 'test:loading':[['development/tests/cold-join.mjs'],['development/tests/loading-recovery.mjs'],['development/tests/loading-feedback.mjs'],['development/tests/lobby-fallback.mjs']],
 'test:drivecam':[['development/tests/drivecam.mjs']],
 'test:gearbox':[['development/tests/gearbox-drift.mjs']],
 'test:pause':[['development/tests/pause-hud.mjs'],['development/tests/pause-hud-ui.mjs']],
 'test:controls':[['development/tests/interface-navigation.mjs'],['development/tests/menu-controller.mjs'],['development/tests/vehicle-signals.mjs']],
 'test:sound':[['development/tests/soundcore-menu.mjs'],['development/tests/soundcore-resolver.mjs']],
 'test:character':[['development/tests/character.mjs'],['development/tests/character-ui.mjs']],
 'test:garage':[['development/tests/workshop-display.mjs'],['development/tests/garage-selection.mjs']],
 'test:exit':[['development/tests/garage-exit.mjs']],
 'test:wheels':[['development/tests/wheel-recovery.mjs'],['development/tests/wheel-stance.mjs']],
 'test:stance':[['development/tests/stance-streaming.mjs']],
 'test:modkits':[['development/tests/modkits.mjs']],
 migrate:[['development/scripts/migrate.mjs']]
};
const task=process.argv[2];if(!Object.hasOwn(tasks,task))throw Error('Unknown development task: '+task);
for(const args of tasks[task]){
 const result=spawnSync(process.execPath,[...args,...process.argv.slice(3)],{cwd:serverRoot,stdio:'inherit',windowsHide:true});
 if(result.error)throw result.error;
 if(result.status!==0)process.exit(result.status??1);
}
