-- Integration harness for actual experience routes; SQL/native adapters are doubles.
SessionTest={writes=0,receipts={},rows={},actor={id=1,epoch='test'},record={character_completed=1,vehicle_completed=1,revision=1}}
local T=SessionTest
T.notifications={}
function TriggerClientEvent(name,src,token)T.notifications[#T.notifications+1]={name=name,src=src,token=token}end
json={encode=function(v)return v end,decode=function(v)return v end}
local counter=0
MX.uuid=function() counter=counter+1 return string.format('00000000-0000-4000-8000-%012d',counter) end
T.original=MX.uuid()
T.rows[T.original]={id=T.original,name='Original',model='elegy',properties={primary=0},revision=1,available=true}
T.record.selected_id=T.original
MX.actor=function()return T.actor end
MX.online=function()return false end
MX.distance=function()return 0 end
MX.canonical=function(v)
 if type(v)~='table' then return tostring(v) end
 local keys={} for k in pairs(v) do keys[#keys+1]=k end table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
 local result='' for _,k in ipairs(keys) do result=result..tostring(k)..':'..MX.canonical(v[k])..';' end return result
end
MX.routes=function(_,routes) T.routes=routes end
ExperienceRules.uuid=function(v)return type(v)=='string' and #v==36 end
ExperienceRules.appearance=function(v)return v end
ExperienceRules.phase=function()return 'workshop' end
MX.db=function(sql,args)
 if sql:find('SELECT %* FROM player_experience') then return {MX.copy(T.record)} end
 if sql:find('SELECT document,revision') then return {{document={model='mp_m_freemode_01'},revision=1}} end
 if sql:find('SELECT kind,result') then local r=T.receipts[args[2]] return r and {r} or {} end
 return {}
end
MX.tx=function(queries)
 if T.failSave then error('database unavailable') end
 T.writes=T.writes+1
 for _,q in ipairs(queries) do
  if q.query=='test-save' then T.rows[q.row.id]=MX.copy(q.row) end
  if q.query:find('INSERT INTO experience_operations',1,true) then T.receipts[q.values[2]]={kind=q.values[3],result=q.values[4]} end
  if q.query:find('UPDATE player_experience SET selected_id=',1,true) then T.record.selected_id=q.values[1] T.record.revision=T.record.revision+1 end
 end
end
local V={}
function V:SavedDisplayList(owner,count,excluded)
 T.displayRequest={owner=owner,count=count,excluded=excluded}
 local rows={} for _,row in pairs(T.rows)do if row.id~=excluded and #rows<count then rows[#rows+1]=MX.copy(row)end end return rows
end
function V:Saved(_,id) assert(T.rows[id],'missing saved record') return MX.copy(T.rows[id]) end
function V:SavedList()local rows={} for _,row in pairs(T.rows)do rows[#rows+1]=MX.copy(row)end return rows end
function V:Preview(_,model,p,point)T.point=MX.copy(point) T.preview={id='presentation',net=1,model=model,properties=MX.copy(p or {primary=0}),capabilities={}} return {ok=true,data=MX.copy(T.preview)}end
function V:CurrentPreview()return MX.copy(T.preview)end
function V:ApplyPreview(_,p)T.preview.properties=MX.copy(p) return {ok=true,data={applied=true}} end
function V:ShowroomModel(model)return model=='180sx' end
function V:PrepareSaved(_,action,d)
 local row={id=d.id,model=d.model or T.rows[d.id].model,name=d.name or 'Saved',properties=MX.copy(d.properties),revision=action=='save' and d.revision+1 or 1,available=true}
 return {queries={{query='test-save',row=row}},result={id=d.id,revision=row.revision}}
end
function V:Active()return nil end
function V:CanEnterWorkshop()end
function V:RegisterPreviewContext()end
function V:RemoveManaged()end
function V:RemovePreview()T.preview=nil end
exports=setmetatable({['mx-freeroam-vehicles']=V,['mx-freeroam-world']={StopTrainer=function()end}},{__call=function()end})
MX.callClient=function()return {ready=true}end
function GetPlayerPed()return 1 end
function DoesEntityExist(entity)return entity==1 end
function GetEntityHeading()return 0 end
T.buckets={}
T.time=0
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+math.max(ms or 0,1)end
function GetPlayerRoutingBucket(src)return T.buckets[src] or 0 end
function GetEntityCoords()return {x=0,y=0,z=0}end
function SetPlayerRoutingBucket(src,bucket)T.buckets[src]=bucket end
function SetRoutingBucketEntityLockdownMode()end
function SetRoutingBucketPopulationEnabled()end
function RegisterNetEvent()end
function AddEventHandler()end
function GetConvar(_,default)return default end
function GetVehiclePedIsIn()return 0 end
