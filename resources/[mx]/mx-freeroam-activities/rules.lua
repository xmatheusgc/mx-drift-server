ActivityRules={}
local transitions={created={preparing=true,cancelled=true,invalid=true},preparing={countdown=true,cancelled=true,invalid=true},countdown={active=true,cancelled=true,invalid=true},active={completed=true,cancelled=true,invalid=true}}
function ActivityRules.transition(session,nextState)
    MX.require(transitions[session.state] and transitions[session.state][nextState],'STATE','Transição inválida de sessão') session.state=nextState
end
function ActivityRules.track(t)
    MX.require(type(t)=='table' and MX.text(t.id,1,48) and MX.number(t.revision,1,10000,true),'TRACK')
    MX.require(t.direction=='forward' or t.direction=='reverse','TRACK')
    MX.require(type(t.checkpoints)=='table' and #t.checkpoints>=2 and #t.checkpoints<=100,'TRACK')
    MX.require(type(t.validated)=='boolean' and type(t.activated)=='boolean' and MX.number(t.startRadius,3,50) and MX.number(t.checkpointRadius,3,50),'TRACK')
    for _,p in ipairs(t.checkpoints) do MX.require(MX.number(p.x,-20000,20000) and MX.number(p.y,-20000,20000) and MX.number(p.z,-100,3000),'TRACK') end
    MX.require(type(t.recoveries)=='table' and #t.recoveries==#t.checkpoints,'TRACK')
    for _,p in ipairs(t.recoveries) do MX.require(MX.number(p.x,-20000,20000) and MX.number(p.y,-20000,20000) and MX.number(p.z,-100,3000) and MX.number(p.h,0,360),'TRACK') end
    return t
end
function ActivityRules.crossed(previous,current,checkpoint,approach,radius)
    if MX.segment(previous,current,checkpoint)>radius then return false end
    local x,y,z=checkpoint.x-approach.x,checkpoint.y-approach.y,checkpoint.z-approach.z
    return (current.x-previous.x)*x+(current.y-previous.y)*y+(current.z-previous.z)*z>0
end
function ActivityRules.comparable(a,b) return a.model==b.model and a.signature==b.signature end
function ActivityRules.period(now,startTime,endTime) return now>=startTime and now<endTime end
