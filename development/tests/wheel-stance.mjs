import assert from 'node:assert/strict';
import {resetStanceForWheelChange} from '../ui/src/wheel-stance.ts';
const saved={wheelType:5,mods:{23:2,24:3},stance:{version:1,height:.03,frontCamber:-4,rearCamber:-2,frontOffset:.05,rearOffset:.08,wheelSize:1.2,wheelWidth:1.3}};
const original=structuredClone(saved);
for(const patch of [{wheelType:7},{mods:{23:4,24:3}},{mods:{23:2,24:4}},{mods:{23:-1,24:-1}}]){
 const result=resetStanceForWheelChange(saved,{...saved,...patch});
 assert.deepEqual(result.stance,{...saved.stance,wheelSize:1,wheelWidth:1});
 assert.deepEqual(saved,original,'preview must not mutate the saved/cancellation state');
}
for(const patch of [{},{wheelColor:4},{customTyres:true},{mods:{...saved.mods,15:2}}]){
 assert.deepEqual(resetStanceForWheelChange(saved,{...saved,...patch}).stance,saved.stance);
}
assert.equal(resetStanceForWheelChange(saved,{...saved,wheelType:7,stance:false}).stance,false);
console.log('Wheel change stance reset: passed');
