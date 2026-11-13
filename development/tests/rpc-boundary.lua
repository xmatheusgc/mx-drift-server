local T=RpcBoundaryTest source=7
T.events.playerConnecting(nil,nil,{defer=function()end,done=function(message)assert(not message)end})
local actor=T.exports.Profile(7)
assert(actor and actor.epoch)
MX.routes('fixture',{cancel=function()MX.fail('OBSOLETE','Seleção substituída')end,read=function()return {ready=true}end,broken=function()error('fixture internal error')end})
local holder=coroutine.create(function()return T.exports.Run(7,actor.epoch,function()coroutine.yield('locked')return {ok=true,data={ready=true}}end)end)
assert(coroutine.resume(holder))
T.events['mx:fixture:request']('busy','read',{})
assert(T.sent[#T.sent].result.code=='BUSY','BUSY survives export transport without INTERNAL or stack dump')
assert(coroutine.resume(holder))
T.time=T.time+200 T.events['mx:fixture:request']('obsolete','cancel',{})
assert(T.sent[#T.sent].result.code=='OBSOLETE','callback catches expected errors before Cfx discards thrown values')
T.time=T.time+200 T.events['mx:fixture:request']('read','read',{})
assert(T.sent[#T.sent].result.ok and T.sent[#T.sent].result.data.ready,'failure releases lock for next request')
local before=#T.printed
T.time=T.time+200 T.events['mx:fixture:request']('broken','broken',{})
assert(T.sent[#T.sent].result.code=='UNAVAILABLE' and #T.printed==before+1,'unexpected errors remain internal diagnostics')
assert(not T.sent[#T.sent].result.message:find('fixture internal error',1,true),'internal detail never reaches the UI')
local invalid=T.exports.Run(7,'obsolete-epoch',function()error('must not run')end)
assert(not invalid.ok and invalid.code=='SESSION','epoch guard remains enforced')
io.write('RPC boundaries: real core lock/routes preserve BUSY, OBSOLETE, epoch guards and unexpected diagnostics under a lossy Cfx adapter.\n')
-- Failure text crosses the client ACK without accepting it as success/authority.
local oldTrigger=TriggerClientEvent local ack
promise={new=function()local p={}function p:resolve(value)self.value=value end return p end}
Citizen={Await=function(p)return p.value end}
TriggerClientEvent=function(_,src,id)source=src T.events['mx:core:ack'](id,false,ack)end
ack={failure={code='SCENE_STREAM',message='Ainda aguardando interior da oficina'}}
local reply=T.exports.ClientCall(7,'fixture','scene',{})
assert(not reply.ok and reply.code=='SCENE_STREAM' and reply.message==ack.failure.message,'expected client errors reach this player as a failure')
ack={failure={code='SCENE_STREAM',message=string.rep('x',513)}}
reply=T.exports.ClientCall(7,'fixture','scene',{})
assert(not reply.ok and reply.code=='CLIENT_ERROR','oversized failure cannot be reflected')
ack={failure={code='INVALID<CODE>',message='invalid'}}
reply=T.exports.ClientCall(7,'fixture','scene',{})
assert(not reply.ok and reply.code=='CLIENT_ERROR','malformed error codes use compatibility fallback')
ack={}
reply=T.exports.ClientCall(7,'fixture','scene',{})
assert(not reply.ok and reply.code=='CLIENT_ERROR','legacy clients remain compatible')
TriggerClientEvent=oldTrigger
io.write('Client ACK errors: useful bounded error, invalid/oversized rejection and legacy fallback passed; no failed ACK becomes success.\n')
