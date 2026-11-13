local T=LobbyAckTest local E=T.exports
assert(not E.LobbyReady(1).accepted and T.shutdown==0,'ACK before lobby is harmless')
T.threads={} E.ShowLobby()
assert(E.IsLobbyGeneration(1) and not E.IsLobbyGeneration(0),'generation belongs to current lobby')
assert(not E.LobbyReady(0).accepted and T.shutdown==0 and T.fades==0,'old generation cannot reveal screen')
local duplicate
T.onWait=function()duplicate=E.LobbyReady(1) assert(T.shutdown==0,'duplicate must not close veil during fade')end
local ready=E.LobbyReady(1)
assert(ready.accepted and ready.loadingClosed and T.shutdown==2 and T.fades==1,'valid ACK closes native loading exactly once')
assert(duplicate.accepted and not duplicate.loadingClosed,'in-flight duplicate cannot announce shutdown prematurely')
E.LobbyReady(1)
assert(T.shutdown==2 and T.fades==1,'repeated ACK after handoff is idempotent')
T.handlers.finish()
local fades=T.fades
assert(not E.LobbyReady(1).accepted and T.fades==fades,'late ACK after leaving cannot touch camera fade')
T.threads={} E.ShowLobby()
local retry=T.threads[1] local events=#T.events local messages=#T.messages
T.onWait=function()T.handlers.finish()end
retry()
local lobbyMessages=0 for i=events+1,#T.events do if T.events[i].name=='mx:experience:lobby' then lobbyMessages=lobbyMessages+1 end end
assert(lobbyMessages==0 and #T.messages==messages,'leaving during retry Wait cannot resurrect lobby or report stale timeout')
assert(not E.LobbyReady(2).accepted,'ACK from cancelled retry is ignored')
print('10 lobby ACK/lifecycle assertions passed against actual client exports; runtime adapters simulated.')
-- Explicit context injection isolates late NUI cleanup from full scene natives.
local function context(name,value)
    for i=1,40 do local key=debug.getupvalue(E.LocalAction,i) if not key then break end if key==name then debug.setupvalue(E.LocalAction,i,value) return end end
    error('missing tested context '..name)
end
local clocks=0 local last
exports['mx-freeroam-world'].SetLobbyTime=function(_,h,m,w)clocks=clocks+1 last={h=h,m=m,w=w}end
context('active',true) context('sceneContext','lobby')
assert(E.LocalAction('previewNight',{enabled=false}).ignored and clocks==0,'old editor cleanup cannot remove lobby night/fog')
assert(E.LocalAction('previewLights',{enabled=false}).ignored,'old light cleanup ignored in lobby')
context('sceneContext','garage')
assert(E.LocalAction('previewNight',{enabled=true}).night and last.h==23 and last.w==nil,'garage night uses enabled contract without fog')
assert(not E.LocalAction('previewNight',{enabled=false}).night and last.h==nil,'editor close restores normal clock')
assert(E.LocalAction('previewLights',{enabled=true}).enabled,'light preview uses enabled contract')
local rev=WorkshopPresentation.rev local calls=0 local pressed
WorkshopPresentation.rev=function(_,value)calls=calls+1 pressed=value end
function IsInputDisabled()return false end
E.LocalAction('engineRev',{id='input-test',pressed=true})
assert(calls==0,'late keyboard heartbeat cannot overwrite controller throttle')
function IsInputDisabled()return true end
E.LocalAction('engineRev',{id='input-test',pressed=true})
assert(calls==1 and pressed==true,'keyboard acceleration still reaches presentation controller')
context('navigationModal',true)
E.LocalAction('engineRev',{id='input-test',pressed=true})
assert(calls==2 and pressed==false,'modal blocks keyboard acceleration')
context('navigationModal',false) WorkshopPresentation.rev=rev
context('active',false)
print('8 actual local-action checks: scene cleanup, lighting, keyboard/controller throttle isolation and modal block; runtime simulated.')
