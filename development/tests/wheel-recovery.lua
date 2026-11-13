local T=VehicleApplyTest
local counts,setMod,setFamily=GetNumVehicleMods,SetVehicleMod,SetVehicleWheelType
local getVariation=GetVehicleModVariation
local notices=0
function TriggerEvent(name)if name=='mx:notice'then notices=notices+1 end end
IsVehicleExtraTurnedOn=function(v,id)return T.cars[v].extras[id]==true end
local function apply(p)return T.handlers.apply({net=71,id=T.cars[71].id,properties=p})end
local function make()
    local p=VehicleProperties.validate(VehicleProperties.defaults())
    p.mods={['0']=1,['23']=250,['48']=2}p.wheelType=12 p.customTyres=true
    p.primary=27 p.plate='RECOVER'
    return p
end
-- Pack count shrinks, front index removed, and the second wheel slot is unsupported.
function GetNumVehicleMods(v,slot)if slot==23 then return 40 end return counts(v,slot)end
local p=make()local result=apply(p)
assert(result.applied and result.wheels and result.warning,'invalid saved wheel does not block other customization')
assert(GetVehicleMod(71,23)==-1 and GetVehicleMod(71,24)==-1 and GetVehicleWheelType(71)==0,'verified original wheel fallback')
assert(GetVehicleMod(71,0)==1 and GetVehicleMod(71,48)==2 and GetVehicleColours(71)==27,'body, modkit decal and paint preserved through family reset')
assert(p.mods['23']==250 and p.wheelType==12 and p.customTyres,'caller/saved document not silently mutated')
local accepted=VehicleProperties.acceptStance(p,result)
assert(accepted.mods['23']==-1 and accepted.mods['24']==-1 and accepted.wheelType==0 and not accepted.customTyres and not accepted.customRearTyres,'server accepts precise effective stock wheels')
assert(VehicleProperties.validate(accepted) and accepted.mods['0']==1 and accepted.plate=='RECOVER','accepted recovery retains unrelated state')
local notified=notices apply(p)assert(notices==notified,'repeated stale previews do not spam notices for the same entity')
p=make()p.mods={['0']=1,[23]=5,[24]=12,['48']=2}p.customRearTyres=true
result=apply(p)accepted=VehicleProperties.acceptStance(p,result)
assert(result.wheels and accepted.mods['23']==-1 and accepted.mods['24']==-1 and accepted.mods[23]==nil and accepted.mods[24]==nil and not accepted.customRearTyres,'removed rear wheels and numeric legacy keys recover without duplicate slots')
p=make()p.mods['23']=5 p.customTyres=false p.mods['4']=0
result=apply(p)accepted=VehicleProperties.acceptStance(p,result)
assert(result.applied and result.modsRecovered['4']==-1 and not result.wheels,'missing exhaust recovers independently of valid wheels')
assert(accepted.mods['4']==-1 and accepted.mods['0']==1 and accepted.mods['23']==5 and p.mods['4']==0,'server keeps original exhaust and preserves other parts/request')
p=make()p.mods['0']=1024 assert(not pcall(apply,p),'out-of-schema mod indices still fail')
local writePart=SetVehicleMod
SetVehicleMod=function(v,slot,value,variation)if slot==4 then return end writePart(v,slot,value,variation)end
T.cars[71].mods[4]=0 p=make()p.mods['4']=0
assert(not pcall(apply,p),'native refusing the original exhaust must not produce a success ACK')
T.cars[71].mods[4]=-1 SetVehicleMod=writePart

-- One stale count refresh is enough; keep the requested wheel when it recovers.
local refreshes=0 local available=false
SetVehicleWheelType=function(v,family)setFamily(v,family)if family==12 then refreshes=refreshes+1 if refreshes>=2 then available=true end end end
GetNumVehicleMods=function(v,slot)if slot==23 then return available and 300 or 40 end return counts(v,slot)end
GetVehicleModVariation=function(v,slot)return T.cars[v].variations and T.cars[v].variations[slot] or false end
SetVehicleMod=function(v,slot,value,variation)setMod(v,slot,value)T.cars[v].variations=T.cars[v].variations or {}T.cars[v].variations[slot]=variation==true end
T.cars[71].family=0
p=make()result=apply(p)
assert(result.applied and not result.wheels and GetVehicleMod(71,23)==250,'fresh family retry recovers requested wheel without stock fallback')

-- Native refuses a valid index once: force reapplication, then verify.
GetNumVehicleMods=counts SetVehicleWheelType=setFamily
local rejected=0
local install=SetVehicleMod
SetVehicleMod=function(v,slot,value,variation)if slot==23 and value==42 and rejected==0 then rejected=rejected+1 return end install(v,slot,value,variation)end
p=make()p.mods['23']=42
result=apply(p)assert(result.applied and not result.wheels and GetVehicleMod(71,23)==42,'transient native refusal retries the same wheel')
SetVehicleMod=function(v,slot,value,variation)if slot==23 and value>=0 then return end install(v,slot,value,variation)end
p.mods['23']=43 result=apply(p)
assert(result.wheels and GetVehicleMod(71,23)==-1,'persistent native refusal falls back to confirmed stock')

-- A refusal to restore stock must never turn into a success acknowledgement.
install(71,23,7,false)
SetVehicleMod=function(v,slot,value,variation)if slot==23 then return end install(v,slot,value,variation)end
assert(not pcall(apply,p),'unconfirmed stock restoration remains an actual failure')

for _,bad in ipairs({{wheelType=12,front=-1,rear=-1,customTyres=false,customRearTyres=false},{wheelType=0,front=2,rear=-1,customTyres=false,customRearTyres=false},{wheelType=0,front=-1,rear=-1,customTyres=false,customRearTyres=false,paint=1}})do
    assert(not pcall(VehicleProperties.acceptStance,p,{wheels=bad}),'server rejects arbitrary or malformed wheel ACK patches')
end
local parts=make()parts.mods['4']=0
for _,bad in ipairs({{['4']=2},{['23']=-1},{['50']=-1},{['7']=-1},{[4]=-1},{}})do
    assert(not pcall(VehicleProperties.acceptStance,parts,{modsRecovered=bad}),'server accepts only explicit original resets of requested allowed parts')
end
GetNumVehicleMods,SetVehicleMod,SetVehicleWheelType,GetVehicleModVariation=counts,setMod,setFamily,getVariation
do
    local ensure,refresh,drift=VehicleStance.ensure,VehicleStance.refresh,VehicleDrift
    local ground,seat,player,release=SetVehicleOnGroundProperly,SetPedIntoVehicle,PlayerPedId,SetModelAsNoLongerNeeded
    local visible=false local order={}
    VehicleStance.ensure=function()visible=true order[#order+1]='ensure' return {value=false}end
    VehicleStance.refresh=function()visible=true order[#order+1]='refresh'end
    VehicleDrift={ensure=function()visible=false order[#order+1]='drift-reset' return {enabled=true}end}
    SetVehicleOnGroundProperly=function()visible=false order[#order+1]='ground-reset'end
    SetPedIntoVehicle=function()end PlayerPedId=function()return 1 end SetModelAsNoLongerNeeded=function()end
    local result=T.handlers.apply({net=71,id=T.cars[71].id,properties=VehicleProperties.defaults(),seat=true,drift=true})
    assert(result.applied and visible and order[#order]=='refresh','gameplay spawn reapplies stance after seating/ground placement and handling refresh')
    VehicleStance.ensure,VehicleStance.refresh,VehicleDrift=ensure,refresh,drift
    SetVehicleOnGroundProperly,SetPedIntoVehicle,PlayerPedId,SetModelAsNoLongerNeeded=ground,seat,player,release
end
print('Wheel/part recovery: removed wheel indices and missing exhaust, strict original-only ACKs, preserved valid parts/paint/livery, immutable request, bounded retries and failed fallback passed (native adapters).')
