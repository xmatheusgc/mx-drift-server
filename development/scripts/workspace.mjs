import {fileURLToPath} from 'node:url';
export const serverRoot=fileURLToPath(new URL('../../',import.meta.url));
// Tools operate on server-data paths; dependencies stay inside development/.
process.chdir(serverRoot);
