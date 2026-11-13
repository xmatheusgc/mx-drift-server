-- Actual stance + actual capability discovery. The native adapters distinguish
-- render geometry from cached getter values, reproducing the reported reset.
local S,C,T=VehicleStance,VehicleCustomization,StanceTest
local car=MX.copy(T.entities[7])
car.id='saved-wheel-spawn' car.model='stance-cold-spawn' car.family=0 car.mod=58 car.size=.6 car.width=.25
car.renderSize=.6 car.renderWidth=.25 T.entities[12]=car
local setFamily,setMod,setSize,setWidth=SetVehicleWheelType,SetVehicleMod,SetVehicleWheelSize,SetVehicleWheelWidth
local probes=0
function SetVehicleWheelType(v,family)
 local e=T.entities[v] e.family=family e.mod=-1 e.renderSize=.6 e.renderWidth=.25 probes=probes+1
 -- Cached dimensions deliberately survive mesh recreation.
end
function SetVehicleMod(v,slot,value)
 if slot==23 then T.entities[v].mod=value T.entities[v].renderSize=.6 T.entities[v].renderWidth=.25 end
end
function SetVehicleWheelSize(v,n)
 local result=setSize(v,n)
 if result==true or result==1 then T.entities[v].renderSize=n end
 return result
end
function SetVehicleWheelWidth(v,n)
 local result=setWidth(v,n)
 if result==true or result==1 then T.entities[v].renderWidth=n end
 return result
end
local saved=VehicleStanceRules.defaults() saved.wheelSize=1.1 saved.wheelWidth=1.2
S.ensure(12,car.id,saved,true)
C.inspect(12)
assert(probes>=13 and car.family==0 and car.mod==58,'cold discovery probes families and restores saved wheels')
assert(math.abs(car.renderSize-.66)<.00001 and math.abs(car.renderWidth-.3)<.00001,'first spawn discovery preserves both visible saved dimensions without opening suspension')
local coldProbes=probes
C.inspect(12)
assert(probes==coldProbes and math.abs(car.renderSize-.66)<.00001,'warm discovery does not probe families again or compound dimensions')
car.renderSize=.6 car.renderWidth=.25
assert(math.abs(GetVehicleWheelSize(12)-.66)<.00001 and math.abs(GetVehicleWheelWidth(12)-.3)<.00001,'cached native values cannot reveal a render-only reset')
S.refresh(12)
assert(math.abs(car.renderSize-.66)<.00001 and math.abs(car.renderWidth-.3)<.00001,'frame refresh repairs visible geometry even when getters already match')
for _=1,30 do S.refresh(12)end
assert(math.abs(car.renderSize-.66)<.00001 and saved.wheelSize==1.1,'reassertion uses the original baseline and never compounds or edits saved factors')
car.id='reused-spawn'
local calls=T.sizeCalls S.refresh(12)
assert(T.sizeCalls==calls,'reused native handle cannot receive the previous saved scale')
SetVehicleWheelType,SetVehicleMod,SetVehicleWheelSize,SetVehicleWheelWidth=setFamily,setMod,setSize,setWidth
print('Saved-wheel spawn regressions passed: cold/warm real discovery, mesh-only reset with matching getters, width/diameter, immutable baseline and reused identity; native adapters, no game.')
