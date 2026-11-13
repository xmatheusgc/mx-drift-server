local T=VehicleApplyTest
local fast=T.exports.PreviewStance local writes=0
local ensure,options=VehicleStance.ensure,VehicleStance.options
VehicleStance.ensure=function(v,id,value,authoritative)
 assert(v==71 and id=='test:71' and value.height==.04 and authoritative)
 writes=writes+1
end
VehicleStance.options=function()return {available=true,value={height=.04}}end
assert(not pcall(fast,71,'test:71',{height=.04}),'untrusted resource cannot preview stance')
T.invoker='mx-freeroam-experience'
assert(not pcall(fast,71,'reused-id',{height=.04}),'reused vehicle identity cannot be previewed')
T.control=false assert(not pcall(fast,71,'test:71',{height=.04}),'missing network ownership blocks local preview')T.control=true
assert(writes==0,'rejected fast previews do not mutate geometry')
assert(fast(71,'test:71',{height=.04}).value.height==.04 and writes==1,'authorized fast preview applies stance only and returns observed capabilities')
VehicleStance.ensure,VehicleStance.options=ensure,options T.invoker=nil
function ClearVehicleCustomPrimaryColour(v)T.cars[v].rgb1=nil end
function ClearVehicleCustomSecondaryColour(v)T.cars[v].rgb2=nil end
function GetIsVehiclePrimaryColourCustom(v)return T.cars[v].rgb1~=nil end
function GetIsVehicleSecondaryColourCustom(v)return T.cars[v].rgb2~=nil end
function GetVehicleCustomPrimaryColour(v)return table.unpack(T.cars[v].rgb1 or {0,0,0})end
function GetVehicleCustomSecondaryColour(v)return table.unpack(T.cars[v].rgb2 or {0,0,0})end
function SetVehicleCustomPrimaryColour(v,r,g,b)T.cars[v].rgb1={r,g,b} T.cars[v].primary=0 end
function SetVehicleCustomSecondaryColour(v,r,g,b)T.cars[v].rgb2={r,g,b} T.cars[v].secondary=0 end
function SetVehicleModColor_1(v)T.cars[v].primary=12 end
function SetVehicleModColor_2(v)T.cars[v].secondary=12 end
local paint=VehicleProperties.defaults()
paint.primary=27 paint.secondary=64 paint.primaryFinish=3 paint.secondaryFinish=1
local oldMod=SetVehicleMod
SetVehicleMod=function(v,slot,value)oldMod(v,slot,value) T.cars[v].primary=0 end
paint.mods={['0']=1}
assert(T.handlers.apply({net=71,id=T.cars[71].id,properties=paint}).applied)
assert(GetVehicleColours(71)==27,'palette is restored after finish and part natives')
paint.customPrimary={24,160,220} paint.customSecondary={255,35,80}
assert(T.handlers.apply({net=71,id=T.cars[71].id,properties=paint}).applied,'RGB validates its own readback instead of a hidden palette index')
local rgbSetter=SetVehicleCustomPrimaryColour
SetVehicleCustomPrimaryColour=function(v)T.cars[v].rgb1={1,2,3}end
local okPaint,paintError=pcall(T.handlers.apply,{net=71,id=T.cars[71].id,properties=paint})
assert(not okPaint and tostring(paintError):find('24,160,220',1,true) and tostring(paintError):find('1,2,3',1,true),'failed RGB readback reports expected and observed values')
SetVehicleCustomPrimaryColour=rgbSetter SetVehicleMod=oldMod
print('Paint: finish/part ordering, independent RGB readback and real rejection diagnostics passed with native adapters; S14 runtime pending.')
local p=VehicleProperties.validate(VehicleProperties.defaults())
p.mods={['0']=1,['48']=2} p.extras={['1']=true,['2']=false}
local result=T.handlers.apply({net=71,id=T.cars[71].id,properties=p})
assert(result.applied and result.extras['1'],'actual apply installs body parts before checking conditional extras')
assert(GetVehicleMod(71,48)==2 and T.liveryWrites==0,'discovery and application preserve modkit-only livery')
for n=1,12 do p.mods['23']=n T.handlers.apply({net=71,id=T.cars[71].id,properties=p})end
assert(GetVehicleMod(71,48)==2 and T.liveryWrites==0,'repeated wheel previews do not rewrite decal')
local spawned=T.handlers.apply({net=72,id=T.cars[72].id,properties=p})
assert(spawned.applied and spawned.extras['1'] and GetVehicleMod(72,48)==2,'new gameplay entity recovers modified configuration')
p.extras['3']=true
local ok,err=pcall(T.handlers.apply,{net=72,id=T.cars[72].id,properties=p})
assert(not ok and tostring(err):find('extra 3',1,true),'unsupported enabled extra has an actionable error')
print('5 actual vehicle apply regressions: conditional extras, repeated wheels, livery preservation and new entity; native adapters only.')
p.extras['3']=false p.mods['48']=-1 p.livery=2
function GetVehicleLiveryCount()return 4 end
function GetVehicleLivery(v)return T.cars[v].legacy or -1 end
function SetVehicleLivery(v,value)T.liveryWrites=T.liveryWrites+1 T.cars[v].legacy=value T.cars[v].mods[48]=value end
T.handlers.apply({net=71,id=T.cars[71].id,properties=p})
local count=T.liveryWrites
for n=13,16 do p.mods['23']=n T.handlers.apply({net=71,id=T.cars[71].id,properties=p})end
assert(count==1 and T.liveryWrites==count and GetVehicleLivery(71)==2,'legacy native livery is not reset by an explicit original modkit slot')
print('1 legacy livery/slot-48 compatibility regression passed with native adapters.')
-- Reproduce the compatibility binding that returned numbers into the spawn ACK.
local extraWrites=0
function IsVehicleExtraTurnedOn(v,id)return T.cars[v].extras[id] and 1 or 0 end
function SetVehicleExtra(v,id,disabled)extraWrites=extraWrites+1 T.cars[v].extras[id]=disabled==0 end
p.extras['1']=false
local disabled=T.handlers.apply({net=72,id=T.cars[72].id,properties=p})
assert(disabled.extras['1']==false,'numeric native 0 must become boolean false, not Lua-truthy true')
local merged=MX.copy(p) merged.extras=disabled.extras
assert(VehicleProperties.validate(merged),'gameplay spawn accepts normalized numeric-native acknowledgement')
local writes=extraWrites
T.handlers.apply({net=72,id=T.cars[72].id,properties=p})
assert(extraWrites==writes,'numeric false does not cause repeated extra writes')
p.extras['1']=true
local enabled=T.handlers.apply({net=72,id=T.cars[72].id,properties=p})
assert(enabled.extras['1']==true,'numeric native 1 must become boolean true')
merged.extras=enabled.extras assert(VehicleProperties.validate(merged),'enabled acknowledgement passes strict server property validation')
for _,value in ipairs({0,1,false,true})do
    IsVehicleExtraTurnedOn=function()return value end
    assert(VehicleCustomization.extraEnabled(72,1)==(value==1 or value==true),'both native binding modes normalize correctly')
end
IsVehicleExtraTurnedOn=function()return '1' end
assert(not pcall(VehicleCustomization.extraEnabled,72,1),'unexpected native values are not silently converted')
merged.extras={['1']=1}
assert(not pcall(VehicleProperties.validate,merged),'untrusted numeric property payload remains rejected')
print('11 native-extra compatibility assertions: 0/1, booleans, spawn ACK validation, idempotence and strict payloads; native adapters only.')
do
 local original=VehicleDrift
 VehicleDrift={ensure=function()return {enabled=false,fallback=true,recovered=true,warning='Original restaurado'}end}
 local result=VehicleApplyTest.handlers.apply({net=71,id=VehicleApplyTest.cars[71].id,properties=VehicleProperties.defaults(),drift=true})
 assert(result.applied and result.drift.fallback and result.drift.recovered,'optional drift failure does not reject the real vehicles/apply callback')
 VehicleDrift=original
end
