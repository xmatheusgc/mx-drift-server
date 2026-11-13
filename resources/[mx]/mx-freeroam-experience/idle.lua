-- Optional local presentation only. Never wait on animation streaming in scene ACKs.
WorkshopIdle={session=nil,history={}}
local I=WorkshopIdle
local function key(a)return a.dict..':'..a.clip end
local function valid(s)
    return DoesEntityExist(s.ped) and GetEntityModel(s.ped)==s.model and
        (s.player and PlayerPedId()==s.ped or not s.player and Entity(s.ped).state.mxWorkshopActor==s.tag)
end
function I.stop(ped)
    local s=I.session if not s or ped and ped~=s.ped then return end
    I.session=nil
    if s.current then
        if valid(s) then StopAnimTask(s.ped,s.current.dict,s.current.clip,ExperienceConfig.idles.blend) end
        RemoveAnimDict(s.current.dict)
    end
    if s.pending then RemoveAnimDict(s.pending.dict) end
end
local function reject(s,a,reason)
    local id=key(a)
    if not s.failed[id] then
        s.failed[id]=true
        print('[MX:IDLE] '..json.encode({level='warn',model=s.model,context=s.context,dict=a.dict,clip=a.clip,reason=reason}))
    end
end
local function choose(s,now)
    local cfg=ExperienceConfig.idles local pool=cfg[s.sex] or {} local candidates={}
    for _,a in ipairs(pool) do if not s.failed[key(a)] and (not a.requiresWall or cfg.wall[s.context]) then candidates[#candidates+1]=a end end
    if #candidates>1 then for i=#candidates,1,-1 do if key(candidates[i])==I.history[s.sex..':'..s.context] then table.remove(candidates,i) end end end
    if #candidates==0 then s.nextAt=now+5000 return end
    local a=candidates[math.random(#candidates)]
    if not DoesAnimDictExist(a.dict) then reject(s,a,'dictionary_missing') s.nextAt=now+250 return end
    s.pending=a s.deadline=now+cfg.loadTimeout RequestAnimDict(a.dict)
end
local function update(ped,context,enabled)
    if not enabled or not ped or ped==0 or not DoesEntityExist(ped) then I.stop() return end
    local model=GetEntityModel(ped) local s=I.session
    if s and (s.ped~=ped or s.model~=model or s.context~=context or not valid(s)) then I.stop() s=nil end
    if not s then
        local player=ped==PlayerPedId() local tag=not player and Entity(ped).state.mxWorkshopActor
        if not player and not tag then return end
        s={ped=ped,model=model,context=context,player=player,tag=tag,sex=IsPedMale(ped) and 'male' or 'female',failed={},nextAt=0} I.session=s
    end
    local now=GetGameTimer() if now<(s.tickAt or 0) then return end s.tickAt=now+250
    local cfg=ExperienceConfig.idles
    if s.current and now>=s.verifyAt and not IsEntityPlayingAnim(ped,s.current.dict,s.current.clip,3) then
        reject(s,s.current,'clip_not_playing') RemoveAnimDict(s.current.dict) s.current=nil s.nextAt=now+250
    end
    local a=s.pending
    if a then
        if HasAnimDictLoaded(a.dict) then
            if GetAnimDuration(a.dict,a.clip)>0 then
                -- Loop with locked translation. Do not extract root motion or
                -- let the clip change the authored scene heading/coordinates.
                TaskPlayAnim(ped,a.dict,a.clip,cfg.blend,-cfg.blend,-1,1,1.0,true,true,true)
                if s.current then RemoveAnimDict(s.current.dict) end
                s.current=a s.verifyAt=now+cfg.verifyMs s.nextAt=now+math.random(cfg.minMs,cfg.maxMs)
                I.history[s.sex..':'..context]=key(a)
            else reject(s,a,'clip_missing') RemoveAnimDict(a.dict) s.nextAt=now+250 end
            s.pending=nil
        elseif now>=s.deadline then reject(s,a,'stream_timeout') RemoveAnimDict(a.dict) s.pending=nil s.nextAt=now+250 end
    elseif now>=s.nextAt then choose(s,now) end
end
function I.update(ped,context,enabled)
    if not enabled then I.stop() return end
    if GetGameTimer()<(I.retryAt or 0) then return end
    local ok,err=pcall(update,ped,context,enabled)
    if not ok then
        pcall(I.stop)
        I.retryAt=GetGameTimer()+5000
        print('[MX:IDLE] '..json.encode({level='warn',context=context,reason='native_error',detail=MX.diagnostic(err)}))
    end
end
AddEventHandler('onClientResourceStop',function(name)if name==GetCurrentResourceName() then I.stop() end end)
