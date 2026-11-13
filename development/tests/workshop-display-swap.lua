local T,D,C=DisplayTest,VehicleDisplay,WorkshopDisplay
C.stop()D.clear()T.step(1500)
local token='swap' local requests=0 local main=MX.copy(T.rows[8])
local rows={}for i=1,7 do rows[i]=MX.copy(T.rows[i])end
local snapshot={vehicles=rows,current=main,selected=main}
exports['mx-freeroam-vehicles']={
 ClearWorkshopDisplay=function()D.clear()end,
 SyncWorkshopDisplay=function(_,value,items,cfg)D.sync(value,items,cfg)end,
}
C.hooks={token=function()return token end,valid=function(value)return value==token end}
MX.request=function()
 requests=requests+1 local result=MX.copy(snapshot)
 if T.duringDisplayRequest then local callback=T.duringDisplayRequest T.duringDisplayRequest=nil callback()end
 return {ok=true,data=result}
end
C.override=nil C.start(token)C.preview(main,main)T.step(3000)
assert(T.live()==7 and requests==1)
local function handles()local result={}for i,e in pairs(D.session.entries)do result[i]=e.vehicle end return result end
local function unique()
 local seen={}for _,item in pairs(D.session.desired)do
  assert(item.row.id~=C.session.main.id,'main saved creation cannot also occupy scenery')
  assert(not seen[item.row.id],'each saved creation occupies one slot')seen[item.row.id]=true
 end
end
local before,created=handles(),D.metrics.created
C.preview(rows[3],main)T.step(1)
assert(requests==1 and D.metrics.created==created+1 and T.live()==7,'preview swaps one scenery vehicle without SQL/RPC reload')
assert(C.session.rows[3].id==main.id,'outgoing main uses incoming car vacancy')
for i,v in pairs(before)do if i~=3 then assert(D.session.entries[i].vehicle==v,'unaffected slot retains the exact entity')end end
unique()
C.preview(main,main)T.step(300)
assert(C.session.rows[3].id==rows[3].id and requests==1,'cancel swaps back locally')unique()
before=handles()created=D.metrics.created
C.preview(rows[1],main)C.preview(rows[2],main)C.preview(rows[5],main)T.step(1200)
assert(D.metrics.created==created+3 and requests==1,'rapid browsing updates only the three affected slots')
for _,i in ipairs({3,4,6,7})do assert(D.session.entries[i].vehicle==before[i],'rapid browsing preserves unrelated entities')end
unique()
C.preview(main,main)T.step(500)unique()
-- A reordered SQL snapshot must not reorder cars already parked.
local reordered={}for i=7,1,-1 do reordered[#reordered+1]=MX.copy(rows[i])end
snapshot={vehicles=reordered,current=main,selected=main}
before=handles()created=D.metrics.created C.refresh()T.step(1000)
assert(D.metrics.created==created,'snapshot reordering never reloads positions')
for i,v in pairs(before)do assert(D.session.entries[i].vehicle==v)end
-- Updating a single saved car touches only its own slot.
local changed=reordered[1]changed.revision=99 changed.properties.primary=99
created=D.metrics.created before=handles()C.refresh()T.step(1000)
assert(D.metrics.created==created+1,'single revision rebuilds one scenery car')
for slot,row in pairs(C.session.rows)do if row.id~=changed.id then assert(D.session.entries[slot].vehicle==before[slot])end end
unique()
-- Metadata-only confirmation of the displayed car does not rebuild scenery.
C.preview(rows[2],main)T.step(500)created=D.metrics.created
C.preview(rows[2],rows[2])T.step(500)
assert(D.metrics.created==created,'confirming the current preview keeps scenery intact')unique()
C.preview(main,main)T.step(500)
-- An old snapshot arriving during a new preview cannot undo the local swap.
T.duringDisplayRequest=function()
 C.preview(rows[4],main)
 local fresh={}for _,row in pairs(C.session.rows)do fresh[#fresh+1]=MX.copy(row)end
 snapshot={vehicles=fresh,current=MX.copy(rows[4]),selected=main}
end
C.refresh()T.step(1500)
assert(C.session.main.id==rows[4].id,'late snapshot cannot restore the previous main identity')unique()
C.stop()T.step(1000)assert(T.live()==0,'swap cache and entities are cleaned on exit')
print('Workshop swaps: preview/cancel/confirm, exact entity reuse, no per-selection RPC, sparse stable slots, reordered snapshots, one-row revision, rapid selection and stale response passed (native adapters).')
