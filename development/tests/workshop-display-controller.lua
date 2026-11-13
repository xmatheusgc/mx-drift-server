local T,D=DisplayTest,WorkshopDisplay
local live=true local token='controller'local requests,syncs,clears=0,0,0
local busy=false
MX.request=function(domain,action,payload)
 assert(domain=='experience' and action=='displayVehicles' and payload.token==token)
 requests=requests+1
 if busy then return {ok=false,code='BUSY'}end
 return {ok=true,data={vehicles=T.rows}}
end
exports['mx-freeroam-vehicles']={
 ClearWorkshopDisplay=function()clears=clears+1 VehicleDisplay.clear()end,
 SyncWorkshopDisplay=function(_,value,rows,cfg)syncs=syncs+1 assert(value==token)T.lastLimit=cfg.maxVehicles end,
 WorkshopDisplayStats=function()return {}end
}
D.hooks={token=function()return token end,valid=function(value)return live and value==token end}
D.start(token)T.step(999)assert(requests==0)T.step(1)assert(requests==1 and syncs==1)
D.start(token)T.step(1000)assert(requests==1,'no repeated snapshot on preview updates')
source=1 T.events['mx:experience:displayChanged'](token)T.step(500)assert(requests==1)
source=65535 T.events['mx:experience:displayChanged']('stale')T.step(500)assert(requests==1)
for i=1,8 do T.events['mx:experience:displayChanged'](token)end
T.step(300)assert(requests==2,'coalesced trusted notifications')
D.tick()assert(T.lod==.8)
local lod=T.lodCalls live=false D.tick()assert(T.lodCalls==lod,'no outside-scene LOD override')live=true
D.refresh()D.stop()T.step(1000)assert(requests==2,'no late work after exit')
T.commands.mxdisplay(0,{'0'})T.step(2000)assert(not D.session and requests==2)
T.commands.mxdisplay(0,{'3'})T.step(1000)assert(T.lastLimit==3)
T.commands.mxdisplay(0,{'8'})assert(D.override==3,'bounded override')
busy=true D.refresh()local before=requests T.step(3000)assert(requests-before==3,'bounded busy retries')busy=false
D.stop()
exports['mx-freeroam-vehicles'].ClearWorkshopDisplay=function()error('resource unavailable')end
assert(pcall(D.stop),'decorative cleanup failure cannot block scene transition')
print('Workshop controller: deferred/coalesced fetch, context/token/source, local count override, per-frame LOD scope, bounded retries and optional cleanup failures passed; adapters only.')
