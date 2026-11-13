local T=DriftTest local one=T.cars[1].fields local two=T.cars[2].fields
assert(VehicleDrift.supported(1,'one'))
assert(VehicleDrift.set(1,'one',true).enabled)
local report=VehicleDrift.audit(1,'one',true)
assert(report.checked==51 and report.mismatches==0,'all 51 runtime attributes are read back after refresh')
assert(T.cars[1].derivedForce==.94 and T.cars[1].derivedVelocity==200 and T.cars[1].highGear==5,'derived transmission values actually refreshed, not merely stored in handling')
assert(not T.cars[1].powered[1] and not T.cars[1].powered[2] and T.cars[1].powered[3] and T.cars[1].powered[4],'RWD powers rear wheels, including originally FWD vehicles')
assert(one.fMass==1280 and one.fInitialDriveForce==.94 and one.fSteeringLock==54 and one.nInitialDriveGears==5,'owner supplied mass, power, steering and gears')
assert(one.fTractionCurveMax==1.07 and one.fTractionCurveMin==1.3,'supplied traction values are preserved verbatim')
assert(one.fClutchChangeRateScaleUpShift==20.8 and one.fInitialDriveMaxFlatVel==200 and one.fDriveBiasFront==0,'transmission data is not retuned')
assert(one.strModelFlags==0x440010 and one.strHandlingFlags==0 and one.strDamageFlags==0,'hex and zero flags use integer setters')
assert(one.vecCentreOfMassOffset.y==.15 and one.vecInertiaMultiplier.z==1.9,'vectors preserved')
assert(one.fBackEndPopUpBuildingImpulseMult==.03 and one.fBackEndPopUpMaxDeltaSpeed==.6,'car subhandling applied')
assert(two.fMass==2 and two.fSteeringLock==2,'other vehicles remain unchanged')
local writes=T.writes VehicleDrift.set(1,'one',true) assert(T.writes==writes,'repeated sync never replaces original snapshot')
one.fSteeringLock=40 report=VehicleDrift.audit(1,'one',true) assert(report.mismatches==1,'diagnostic detects external field changes')
local found=false for _,field in ipairs(report.fields)do if field.field=='fSteeringLock' then found=field.matches==false and field.actual==40 and field.expected==54 end end assert(found,'diagnostic includes exact expected/observed mismatches')
VehicleDrift.set(1,'one',true) assert(one.fSteeringLock==54,'repeat apply repairs discrepancies without capturing a new original')
T.cars[1].derivedForce=2 local refreshed=T.cars[1].refreshes
VehicleDrift.set(1,'one',true,true) assert(T.cars[1].derivedForce==.94 and T.cars[1].refreshes>refreshed,'force refresh rebuilds caches after repair or ownership change')
VehicleDrift.set(1,'one',false) assert(one.fMass==2 and one.nInitialDriveGears==6 and one.vecInertiaMultiplier.z==3 and one.fBackEndPopUpCarImpulseMult==.5,'disable restores complete original values')
assert(T.cars[1].derivedForce==2 and T.cars[1].derivedVelocity==2 and T.cars[1].highGear==6 and T.cars[1].powered[1] and not T.cars[1].powered[3],'restore also rebuilds original transmission and FWD wheel state')
report=VehicleDrift.audit(1,'one',false)assert(report.checked==51 and report.mismatches==0,'manual diagnostic can compare all original values after disabling')
T.failRefreshOnce=true assert(not pcall(VehicleDrift.set,1,'one',true),'refresh failure cannot claim success')
assert(one.fMass==2 and T.cars[1].derivedForce==2,'failed refresh rolls back handling and derived drivetrain')
T.reject='fMass' assert(not pcall(VehicleDrift.set,1,'one',true),'read-back failure cannot report success') T.reject=nil
assert(one.fSteeringLock==2 and one.fMass==2 and one.strModelFlags==6,'partial application rolls back')
T.missing='fBackEndPopUpMaxDeltaSpeed' writes=T.writes
assert(not pcall(VehicleDrift.set,2,'two',true) and T.writes==writes,'unsupported subtype fails preflight before mutation') T.missing=nil
two.nInitialDriveGears=8
assert(not pcall(VehicleDrift.set,2,'two',true) and T.writes==writes,'baseline above Cfx handling-setter gear limit is rejected before any mutation') two.nInitialDriveGears=6
VehicleDrift.set(1,'one',true) T.cars[1].id='reused'
writes=T.writes assert(not pcall(VehicleDrift.set,1,'one',false) and T.writes==writes,'old identity cannot restore onto reused entity')
T.cars[1].id='one' T.events.onClientResourceStop('mx-freeroam-vehicles') assert(one.fMass==2,'resource stop restores original data')
local sync=T.threads[1]
local function tick()local ok,err=coroutine.resume(sync)assert(ok,err)end
T.control=false T.wanted[1]={id='one',preset=VehicleDriftPreset.id,enabled=true}
tick()tick() assert(one.fMass==1280,'late-streamed observer applies preset')
refreshed=T.cars[1].refreshes T.control=true tick()
assert(T.cars[1].refreshes==refreshed+1,'network ownership gain refreshes transmission even with matching raw fields')
tick()assert(T.cars[1].refreshes==refreshed+1,'stable owner does not reset transmission every polling interval')
T.wanted[1].enabled=false tick()assert(one.fMass==2 and T.cars[1].derivedForce==2,'replicated disable restores original derived state')
print('Drift preset: supplied values, local scope, int/float/vector/subtype, original restoration, partial-failure rollback, unsupported subtype, repeated sync and reused identity passed with native adapters.')
