-- Disposable scenery, never networked, registered as a public vehicle or saved.
local D=VehicleDisplay
local serial=0
local instance=tostring(GetGameTimer())..':'..tostring(math.random(1,1000000000))
local function identity()serial=serial+1 return 'display:'..instance..':'..serial end
D.session=nil D.orphans={} D.metrics={created=0,removed=0,reused=0,failed=0}
local function owns(e)
    return DoesEntityExist(e.vehicle) and GetEntityModel(e.vehicle)==e.model
        and Entity(e.vehicle).state.mxVehicle==e.id and Entity(e.vehicle).state.mxWorkshopDisplay==e.tag
end
local function dispose(e)
    if owns(e)then SetEntityVisible(e.vehicle,false,false) DeleteEntity(e.vehicle)end
    if owns(e)then D.orphans[e.tag]=e
    else D.orphans[e.tag]=nil end
end
function D.reap()for _,e in pairs(D.orphans)do dispose(e)end end
local function releaseModel(s,hash)
    if s.loading==hash then SetModelAsNoLongerNeeded(hash) s.loading=nil end
end
function D.clear()
    local s=D.session D.session=nil
    if not s then return end
    s.alive=false
    if s.loading then releaseModel(s,s.loading)end
    for _,e in pairs(s.entries)do dispose(e)D.metrics.removed=D.metrics.removed+1 end
end
local function warn(row,err)
    D.metrics.failed=D.metrics.failed+1
    print('[MX:DISPLAY] '..json.encode({level='warn',model=row.model,preset=row.id,detail=tostring(err)}))
end
function D.sync(token,rows,cfg)
    MX.require(MX.text(token,1,64) and type(rows)=='table' and type(cfg)=='table','PAYLOAD')
    MX.require(type(cfg.points)=='table' and MX.number(cfg.maxVehicles,0,7,true)
        and MX.number(cfg.modelTimeout,100,15000) and MX.number(cfg.betweenCars,0,2000)
        and MX.number(cfg.lodDistance,10,200),'PAYLOAD')
    local desired={}
    for i=1,math.min(7,#rows,#cfg.points,cfg.maxVehicles)do
        local row=rows[i] local slot=row.slot or i
        MX.require(MX.number(slot,1,math.min(7,#cfg.points,cfg.maxVehicles),true) and not desired[slot],'PAYLOAD')
        local point=cfg.points[slot]
        MX.require(MX.text(row.id,1,64) and MX.text(row.model,1,64),'PAYLOAD')
        MX.require(type(point)=='table' and MX.number(point.x,-10000,10000) and MX.number(point.y,-10000,10000)
            and MX.number(point.z,-1000,3000) and MX.number(point.h,-360,360),'PAYLOAD')
        local properties=VehicleProperties.validate(MX.copy(row.properties))
        local key=MX.canonical({id=row.id,model=row.model,revision=row.revision,properties=properties,point=point,neon=cfg.neon,lod=cfg.lodDistance})
        desired[slot]={key=key,row={id=row.id,model=row.model,properties=properties},point=point}
    end
    local s=D.session
    if not s or s.token~=token then D.clear()s={token=token,id=identity(),entries={},desired={},alive=true}D.session=s end
    for i,item in pairs(desired)do if s.desired[i] and s.desired[i].key==item.key then desired[i]=s.desired[i]end end
    s.desired=desired s.cfg=MX.copy(cfg)
    for i,e in pairs(s.entries)do
        if not desired[i] or desired[i].key~=e.key or (e.vehicle~=0 and not owns(e)) then dispose(e)s.entries[i]=nil
        else D.metrics.reused=D.metrics.reused+1 end
    end
    if s.worker then return end s.worker=true
    CreateThread(function()
        while D.session==s and s.alive do
            local index,item
            for i=1,7 do if s.desired[i] and not s.entries[i]then index,item=i,s.desired[i]break end end
            if not item then break end
            local function current()return D.session==s and s.alive and s.desired[index]==item end
            local row,point=item.row,item.point local hash=joaat(row.model) local created
            local ok,err=pcall(function()
                MX.require(IsModelInCdimage(hash) and IsModelAVehicle(hash),'MODEL')
                s.loading=hash RequestModel(hash)
                local deadline=GetGameTimer()+s.cfg.modelTimeout
                while not HasModelLoaded(hash) and current() and GetGameTimer()<deadline do Wait(50)end
                if not current()then return end
                MX.require(HasModelLoaded(hash),'MODEL_TIMEOUT')
                D.reap()
                -- Failed deletions retain identities and consume the same budget.
                local count=0 for _ in pairs(D.orphans)do count=count+1 end
                for _ in pairs(s.entries)do count=count+1 end
                MX.require(count<7,'DISPLAY_LIMIT')
                local v=CreateVehicle(hash,point.x+0.0,point.y+0.0,point.z+0.0,point.h+0.0,false,false)
                MX.require(v~=0 and DoesEntityExist(v),'CREATE')
                local id=identity()
                created={vehicle=v,model=hash,id=id,tag=id,key=item.key}
                Entity(v).state:set('mxVehicle',created.id,false)
                Entity(v).state:set('mxWorkshopDisplay',created.tag,false)
                s.entries[index]=created
                SetEntityAsMissionEntity(v,true,true) SetEntityVisible(v,false,false)
                local networked=NetworkGetEntityIsNetworked(v)
                MX.require(networked~=true and networked~=1,'NETWORKED')
                SetVehicleOnGroundProperly(v)
                D.apply(v,row.properties)
                SetEntityInvincible(v,true) SetVehicleDoorsLocked(v,2) SetVehicleUndriveable(v,true)
                SetVehicleEngineOn(v,false,true,true) SetVehicleHandbrake(v,true) SetVehicleLights(v,1)
                if not s.cfg.neon then for side=0,3 do SetVehicleNeonLightEnabled(v,side,false)end end
                SetVehicleDirtLevel(v,0.0) SetEntityCollision(v,false,false)
                FreezeEntityPosition(v,true) SetEntityDynamic(v,false)
                SetEntityLodDist(v,s.cfg.lodDistance)
                VehicleStance.refresh(v) SetEntityVisible(v,true,false)
                D.metrics.created=D.metrics.created+1
            end)
            releaseModel(s,hash)
            if not ok and current()then
                if created then dispose(created)end
                -- Failed slots retry on a new revision, scene or manual refresh.
                s.entries[index]={key=item.key,vehicle=0,model=hash,id='',tag='failed:'..s.id..':'..index}
                warn(row,err)
            end
            if D.session==s and s.alive then Wait(s.cfg.betweenCars)end
        end
        s.worker=false
    end)
end
exports('SyncWorkshopDisplay',function(token,rows,cfg)
    MX.require(GetInvokingResource()=='mx-freeroam-experience','FORBIDDEN')
    D.sync(token,rows,cfg) return {queued=true}
end)
exports('ClearWorkshopDisplay',function()
    MX.require(GetInvokingResource()=='mx-freeroam-experience','FORBIDDEN')D.clear()
end)
exports('WorkshopDisplayStats',function()
    local count=0 local orphaned=0
    if D.session then for _,e in pairs(D.session.entries)do if owns(e)then count=count+1 end end end
    for _,e in pairs(D.orphans)do if owns(e)then orphaned=orphaned+1 end end
    return {visible=count,orphaned=orphaned,loading=D.session and D.session.loading~=nil or false,metrics=MX.copy(D.metrics)}
end)
CreateThread(function()while true do Wait(1000)D.reap()end end)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName()or name=='mx-freeroam-experience'or name=='mx-freeroam-menu'then D.clear()D.reap()end
end)
