local T=VehicleOptionsTest local routes=T.routes
local savedId='00000000-0000-4000-8000-000000000001'
local before=T.exports.Active(1) local old=before.entity
T.time=T.time+6000 T.cars[old].speed=30
assert(routes.options(1).available.respawn and not routes.options(1).available.flip,'moving replacement allowed; moving upright remains blocked')
assert(#routes.trainerGarage(1,{},T.actors[1])>=1,'trainer lists owned saved creations')
assert(not pcall(routes.switch,1,{presetId=savedId,model='elegy'},T.actors[1]),'ambiguous selection rejected')
assert(not pcall(routes.switch,1,{model='forged'},T.actors[1]),'arbitrary model rejected')
assert(not pcall(routes.switch,2,{presetId=savedId},T.actors[2]),'another owner cannot load this saved creation')
T.peds[2].car=old
assert(not pcall(routes.switch,1,{model='elegy'},T.actors[1]),'cannot replace a car containing another player') T.peds[2].car=0
T.failLoad=true
assert(not pcall(routes.switch,1,{model='elegy'},T.actors[1]) and T.cars[old],'failed target loading preserves original car') T.failLoad=false
local point=T.cars[old].x T.moveDuringLoad=true
T.failPrepare=true T.resumed=false
local prepared,prepareError=pcall(routes.switch,1,{presetId=savedId},T.actors[1])
assert(not prepared and T.cars[old] and not T.cars[old].frozen and T.resumed,'failed saved switch resumes the original car without deletion')
assert(prepareError.message:find('desembarque',1,true) and prepareError.message:find('liberado',1,true),'preparation failure explains the stage and confirmed recovery')
local lastPrepare,lastResume
for _,call in ipairs(T.calls)do if call.action=='prepareRespawn'then lastPrepare=call.data elseif call.action=='resumeRespawn'then lastResume=call.data end end
assert(lastPrepare.transfer==lastResume.transfer,'rollback is scoped to the same transfer')
T.failResume=true
local recovered,recoveryError=pcall(routes.switch,1,{presetId=savedId},T.actors[1])
assert(not recovered and recoveryError.message:find('10 segundos',1,true),'lost recovery ACK is reported instead of claiming restoration')
T.failResume=false T.failPrepare=false T.cars[old].frozen=false
T.moveDuringLoad=false point=T.cars[old].x T.moveDuringLoad=true
local replaced=routes.switch(1,{presetId=savedId},T.actors[1]) T.moveDuringLoad=false
assert(not T.cars[old] and T.peds[1].car==replaced.net and #T.exports.Inspect()==1,'switch replaces one entity and seats the owner')
assert(T.cars[replaced.net].x==point+100,'replacement uses final position after moving during model loading')
assert(T.exports.Active(1).presetId==savedId and T.exports.Active(1).drift and T.cars[replaced.net].properties.mods['23']==17,'saved switch restores customizations and durable drift')
T.time=T.time+6000
local count=0 for _ in pairs(T.saved)do count=count+1 end
local catalog=routes.switch(1,{model='elegy'},T.actors[1])
assert(T.exports.Active(1).model=='elegy' and not T.exports.Active(1).drift and not T.exports.Active(1).presetId,'catalog switch starts a separate stock session car')
local after=0 for _ in pairs(T.saved)do after=after+1 end assert(count==after,'switching catalog model does not create or alter saved creations')
T.time=T.time+6000 T.exports.RemoveManaged(1) T.peds[1].car=0
local foot=routes.switch(1,{model='elegy'},T.actors[1])
assert(T.peds[1].car==foot.net,'player without active car can spawn and enter a catalog car at their reserved location')
print('Trainer car switch: moving position, saved customization/drift, catalog stock state, ownership, passenger guards, preflight failure and foot spawn passed with native/SQL adapters.')
