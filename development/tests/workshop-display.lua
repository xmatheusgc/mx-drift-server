local T,D=DisplayTest,VehicleDisplay
MX.copy=function(v)
 if type(v)~='table'then return v end
 local result={}for k,value in pairs(v)do result[k]=MX.copy(value)end return result
end
assert(MX.uuid==nil,'client must not depend on server SQL UUID helper')
MX.canonical=function(v)
 if type(v)~='table'then return tostring(v)end
 local keys={}for k in pairs(v)do keys[#keys+1]=k end table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local out=''for _,k in ipairs(keys)do out=out..tostring(k)..'='..MX.canonical(v[k])..';'end return out
end
T.rows={}for i=1,10 do T.rows[i]={id='saved-'..i,model='car-'..i,revision=1,properties={primary=i,wheelSize=1.1}}end
local cfg=ExperienceConfig.display
D.sync('garage',T.rows,cfg)T.step(3000)
assert(T.live()==7 and D.metrics.created==7,'bounded sequential local scenery')
local first=D.session.entries[1].vehicle
local e=T.entities[first]
assert(e.properties.primary==1 and e.properties.wheelSize==1.1 and e.stance)
assert(e.SetEntityCollision[1]==false and e.FreezeEntityPosition[1]==true and e.SetVehicleEngineOn[1]==false)
assert(e.SetEntityLodDist[1]==55 and T.released=='car-7')
D.sync('garage',T.rows,cfg)T.step(3000)assert(D.metrics.created==7 and D.session.entries[1].vehicle==first,'reuse unchanged cars')
T.rows[1].revision=2 D.sync('garage',T.rows,cfg)T.step(3000)
assert(D.metrics.created==8 and not DoesEntityExist(first) and T.live()==7,'only changed slot rebuilt')
local session=D.session
assert(not pcall(D.sync,'other',{{id='bad',model='car',properties={invalid=true}}},cfg) and D.session==session,'bad payload cannot clear existing scene')
T.caller='other'assert(not pcall(exports.SyncWorkshopDisplay,'x',{},cfg),'export restricted to experience')T.caller='mx-freeroam-experience'
D.clear()assert(T.live()==0 and not D.session)
T.loaded=false D.sync('slow',T.rows,cfg)T.step(100)assert(D.session.loading)
D.clear()T.loaded=true T.step(500)assert(T.live()==0 and T.released=='car-1','cancel loading and release model')
T.loaded=false D.sync('latest',T.rows,cfg)T.step(100)
local latest=MX.copy(T.rows)latest[1].model='replacement'
D.sync('latest',latest,cfg)T.loaded=true T.step(3000)
assert(GetEntityModel(D.session.entries[1].vehicle)=='replacement' and T.live()==7,'latest desired rows win while loading')
local reused=D.session.entries[1].vehicle T.entities[reused].state.mxVehicle='unrelated'
D.clear()assert(DoesEntityExist(reused),'do not delete reused identity')T.entities[reused].exists=false
T.failApply=true D.sync('failure',{T.rows[1]},cfg)T.step(1000)
assert(T.live()==0 and D.metrics.failed>0,'optional cosmetics failure cleans up')
T.failApply=false D.clear()
T.networked=1 D.sync('network',{T.rows[1]},cfg)T.step(1000)
assert(T.live()==0,'unexpected networked creation rejected and deleted')T.networked=nil D.clear()
local bad=MX.copy(T.rows[1])bad.model='invalid'
D.sync('skip',{bad,T.rows[2]},cfg)T.step(1000)assert(T.live()==1,'bad asset does not block next car')
T.failDelete=true D.clear()assert(exports.WorkshopDisplayStats().orphaned==1)
for _,orphan in pairs(D.orphans)do assert(T.entities[orphan.vehicle].visible==false,'delayed deletion cannot leave a duplicate visible')end
T.failDelete=false T.step(1100)assert(T.live()==0 and exports.WorkshopDisplayStats().orphaned==0,'retry failed deletion')
D.sync('orphans',{T.rows[1]},cfg)T.step(1000)T.failDelete=true
for i=1,8 do
 local changed=MX.copy(T.rows[1])changed.revision=100+i
 D.sync('orphans',{changed},cfg)T.step(500)
 assert(T.live()<=7,'failed deletions cannot exceed live entity budget')
end
assert(exports.WorkshopDisplayStats().orphaned==7,'retain every failed deletion identity across repeated slot replacement')
T.failDelete=false D.clear()T.step(1100)assert(T.live()==0)
T.loaded=false D.sync('timeout',{T.rows[1]},cfg)T.step(5500)
assert(T.live()==0 and not D.session.loading,'bounded model timeout')T.loaded=true D.clear()
local second,seventh=MX.copy(T.rows[2]),MX.copy(T.rows[7])second.slot=2 seventh.slot=7
D.sync('sparse',{second,seventh},cfg)T.step(1000)
assert(D.session.entries[2] and D.session.entries[7] and not D.session.entries[1] and T.live()==2,'empty slots never compact later positions')
local previous=D.session
assert(not pcall(D.sync,'sparse',{second,second},cfg) and D.session==previous,'duplicate slot rejected before mutating scenery')
D.clear()
T.loaded=false D.sync('stable-load',{T.rows[1]},cfg)T.step(100)
local modelRequests=T.modelRequests
D.sync('stable-load',MX.copy({T.rows[1]}),cfg)T.step(100)
assert(T.modelRequests==modelRequests,'unchanged synchronization does not restart in-flight streaming')
T.loaded=true T.step(1000)D.clear()
print('Workshop display: local-only/budget, appearance before reveal, reuse/revision, cancellation/latest state, timeout, failed props, reused identities and deletion retry passed; native adapters only.')
