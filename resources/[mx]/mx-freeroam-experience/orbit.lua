-- Workshop-only orbit: asynchronous collision approval and per-frame rendering
-- have separate clocks. Pending/failed tests never publish an unverified pose.
WorkshopOrbit={}
local O=WorkshopOrbit
local function limited(value,step) return math.max(-step,math.min(step,value)) end
function O.new(position,target,input)
    return {position=position,safe=position,target=target,yaw=input.yaw,elevation=input.elevation,distance=input.distance}
end
function O.stop(s,input)
    local p,t=s.position,s.target
    local horizontal=math.sqrt((p.x-t.x)^2+(p.y-t.y)^2)
    input.yaw=math.atan(p.y-t.y,p.x-t.x) input.elevation=math.atan(p.z-t.z,horizontal) input.distance=math.sqrt(horizontal^2+(p.z-t.z)^2)
    s.yaw=input.yaw s.elevation=input.elevation s.distance=input.distance s.safe=p s.query=nil s.stopped=true
end
function O.step(s,car,width,length,height,input,entity,dt)
    -- A released mouse must not trigger another safety-clamp adjustment from
    -- the interpolated pose. Resume only when fresh input changes the target.
    if s.stopped and input.yaw==s.yaw and input.elevation==s.elevation and input.distance==s.distance then return s.position,s.target end
    s.stopped=false
    local cfg=ExperienceConfig.orbit local now=GetGameTimer()
    if s.query then
        local q=s.query
        local a,hitA=q.a,q.hitA local b,hitB=q.b,q.hitB
        if not a then a,hitA=GetShapeTestResult(q.sight) end
        if not b then b,hitB=GetShapeTestResult(q.travel) end
        -- Completed handles are read once; retain results while the other runs.
        if q.a then a,hitA=q.a,q.hitA elseif a~=1 then q.a,q.hitA=a,hitA end
        if q.b then b,hitB=q.b,q.hitB elseif b~=1 then q.b,q.hitB=b,hitB end
        if a~=1 and b~=1 then
            if a==2 and b==2 and hitA==0 and hitB==0 then
                s.safe=q.point s.target=q.target s.yaw=q.yaw s.elevation=q.elevation s.distance=q.distance
            end
            s.query=nil
        elseif now-q.started>=cfg.queryTimeout then s.query=nil end
    end
    if not s.query then
        local _,_,distance,elevation=WorkshopFraming.orbit(car,width,length,height,input.yaw,input.elevation,input.distance)
        input.distance=distance input.elevation=elevation
        local delta=(input.yaw-s.yaw+math.pi)%(2*math.pi)-math.pi
        local yaw=s.yaw+limited(delta,.35)
        local pitch=s.elevation+limited(elevation-s.elevation,.15)
        local radius=s.distance+limited(distance-s.distance,1.0)
        local point,target,clamped,angle=WorkshopFraming.orbit(car,width,length,height,yaw,pitch,radius)
        if MX.distance(s.safe,point)>.001 then s.query={point=point,target=target,yaw=yaw,elevation=angle,distance=clamped,started=now,
            sight=StartShapeTestCapsule(target.x,target.y,target.z,point.x,point.y,point.z,.15,19,entity,7),
            travel=StartShapeTestCapsule(s.position.x,s.position.y,s.position.z,point.x,point.y,point.z,.15,19,entity,7)} end
    end
    local position=WorkshopFraming.dampPoint(s.position,s.safe,dt,cfg.response)
    if WorkshopFraming.outside(car,width,length,height,position) then s.position=position end
    return s.position,s.target
end
