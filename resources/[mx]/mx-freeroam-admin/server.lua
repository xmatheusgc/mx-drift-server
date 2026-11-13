local drafts={}
local resource=GetCurrentResourceName()
local permissions={'inspect','invalidate','cleanup','content','announce','warn','kick','ban','teleport'}
local function permitted(src,action) return AdminModeration.allowed(src,action) end
local function authorize(src,action) MX.require(permitted(src,action),'FORBIDDEN','Permissão ACE necessária: mx.'..action) end
local function audit(src,action,target,requestId,details)
    local actor=src~=0 and MX.actor(src)
    MX.db('INSERT INTO audit_log(actor,action,target,request_id,details) VALUES (?,?,?,?,?)',{actor and 'profile:'..actor.id or 'console',action,target or '',requestId or '',json.encode(details or {})})
    print(json.encode({domain='admin',action=action,target=target,requestId=requestId,actor=actor and actor.id or 'console'}))
end
local function requireModule(name) MX.require(MX.online('mx-freeroam-'..name),'UNAVAILABLE','Módulo indisponível: '..name) end
local function inspect(src)
    MX.require(src==0 or IsPlayerAceAllowed(src,'mx.admin'),'FORBIDDEN','Administração restrita')
    local p={} for _,action in ipairs(permissions) do p[action]=permitted(src,action) end
    local any=false for _,allowed in pairs(p) do any=any or allowed end
    MX.require(any,'FORBIDDEN','Administração requer permissão ACE')
    local states={} for _,name in ipairs({'core','world','vehicles','social','activities','progression','menu','experience','drivecam'}) do states[name]=GetResourceState('mx-freeroam-'..name) end
    return {permissions=p,resources=states,vehicles=p.inspect and MX.online('mx-freeroam-vehicles') and exports['mx-freeroam-vehicles']:Inspect() or {},presentations=p.inspect and MX.online('mx-freeroam-vehicles') and exports['mx-freeroam-vehicles']:PreviewInspect() or {},sessions=p.inspect and MX.online('mx-freeroam-activities') and exports['mx-freeroam-activities']:Inspect() or {},diagnostic='Persistência real. Coordenadas, voz, dois clientes e carga exigem ensaio de jogo.'}
end
local function revoke(src,d,requestId)
    authorize(src,'invalidate') requireModule('activities')
    MX.require(MX.text(d.id,36,36) and MX.text(d.reason,1,120),'RESULT')
    -- Registra intenção antes da mutação. Revogação idempotente permanece recuperável se o segundo log falhar.
    audit(src,'revoke_requested',d.id,requestId,{reason=d.reason})
    exports['mx-freeroam-activities']:Revoke(d.id,d.reason)
    audit(src,'revoke_applied',d.id,requestId,{compensation='durable_pending'}) return {}
end
local function cleanup(src,requestId)
    authorize(src,'cleanup') requireModule('vehicles')
    audit(src,'cleanup',nil,requestId)
    for _,car in ipairs(exports['mx-freeroam-vehicles']:Inspect()) do if MX.online('mx-freeroam-activities') then exports['mx-freeroam-activities']:Invalidate(car.source,'admin_cleanup') end end
    exports['mx-freeroam-vehicles']:Cleanup() return {}
end
local function announce(src,d,requestId)
    authorize(src,'announce') requireModule('social')
    MX.require(MX.text(d.destination,1,48),'DESTINATION')
    audit(src,'announce',d.destination,requestId) return exports['mx-freeroam-social']:Announce(src,d.destination)
end
MX.routes('admin',{
    cameraEditor=AdminTools.editor,
    coordinates=AdminTools.snapshot,
    coordinateOverlay=AdminTools.overlay,
    teleport=function(src,d,_,requestId)
        local actor=AdminTools.check(src,'teleport') requireModule('world')
        audit(src,'teleport_requested',d.mode,requestId,{point=d.point})
        MX.require(AdminTools.check(src,'teleport').epoch==actor.epoch,'SESSION')
        return MX.unwrap(exports['mx-freeroam-world']:AdminTravel(src,d))
    end,
    permissions=function(src) local result={admin=src==0 or IsPlayerAceAllowed(src,'mx.admin')} for _,action in ipairs(permissions) do result[action]=permitted(src,action) end return result end,
    moderate=function(src,d,_,requestId) return AdminModeration.apply(src,d,requestId,audit) end,
    createTeleport=function(src,d,_,requestId)
        authorize(src,'content') requireModule('world')
        local actor=MX.actor(src)
        audit(src,'teleport_requested',nil,requestId,{name=d.name,category=d.category})
        authorize(src,'content')
        MX.require(actor and MX.actor(src) and MX.actor(src).epoch==actor.epoch,'SESSION')
        return exports['mx-freeroam-world']:CreateTeleport(src,d.name,d.category)
    end,
    inspect=function(src) return inspect(src) end,
    revoke=function(src,d,_,requestId) return revoke(src,d,requestId) end,
    cleanup=function(src,_,__,requestId) return cleanup(src,requestId) end,
    announce=function(src,d,_,requestId) return announce(src,d,requestId) end
})
local function command(name,permission,fn)
    RegisterCommand(name,function(src,args)
        local ok,result=pcall(function() authorize(src,permission) return fn(src,args) end)
        local message=ok and (type(result)=='string' and result or json.encode(result or {})) or (type(result)=='table' and result.message or 'Falha; confira diagnóstico de banco')
        if src==0 then print('[MX] '..message) else TriggerClientEvent('mx:notify',src,message) end
    end,false)
end
command('mxinspect','inspect',function(src) return inspect(src) end)
command('mxrevoke','invalidate',function(src,args) return revoke(src,{id=args[1],reason=table.concat(args,' ',2)},'command') end)
command('mxcleanup','cleanup',function(src) return cleanup(src,'command') end)
command('mxannounce','announce',function(src,args) return announce(src,{destination=args[1]},'command') end)
command('mxreprocess','invalidate',function(src) requireModule('progression') audit(src,'reprocess',nil,'command') exports['mx-freeroam-progression']:Reprocess() return 'Processamento solicitado' end)
command('mxtrack','content',function(src,args)
    MX.require(src~=0,'PLAYER','Captura exige administrador no jogo')
    local action=args[1]
    if action=='begin' then
        MX.require(type(args[2])=='string' and args[2]:match('^[a-z0-9_]+$') and #args[2]<=48,'TRACK')
        MX.require(args[3]=='forward' or args[3]=='reverse','TRACK')
        MX.require(MX.number(tonumber(args[5]),1,10000,true),'REVISION','Use /mxtrack begin id forward destino revisão')
        requireModule('world') MX.require(exports['mx-freeroam-world']:Destinations()[args[4]],'DESTINATION')
        drafts[src]={id=args[2],name=args[2],revision=tonumber(args[5]),direction=args[3],destination=args[4],region=args[4],validated=false,activated=false,drift=true,startRadius=15,checkpointRadius=12,checkpoints={},recoveries={}}
        return 'Rascunho iniciado. /mxtrack point em cada checkpoint, primeiro = largada'
    elseif action=='point' then
        local draft=drafts[src] MX.require(draft and #draft.checkpoints<100,'DRAFT')
        local ped=GetPlayerPed(src) local p=GetEntityCoords(ped)
        draft.checkpoints[#draft.checkpoints+1]={x=p.x,y=p.y,z=p.z}
        draft.recoveries[#draft.recoveries+1]={x=p.x,y=p.y,z=p.z,h=GetEntityHeading(ped)}
        return 'Checkpoint '..#draft.checkpoints..' capturado do estado sincronizado'
    elseif action=='export' then
        local draft=drafts[src] MX.require(draft and #draft.checkpoints>=2,'DRAFT')
        MX.require(SaveResourceFile(resource,'drafts/'..draft.id..'.json',json.encode(draft),-1),'DISK')
        audit(src,'track_draft',draft.id,'command',{points=#draft.checkpoints}) return 'Exportado em drafts/'..draft.id..'.json; não é pista pública'
    elseif action=='activate' then
        MX.require(args[3]=='confirmado-no-jogo','VALIDATION','Teste trajeto, colisão, checkpoint e recuperação; depois use /mxtrack activate id confirmado-no-jogo')
        MX.require(type(args[2])=='string' and args[2]:match('^[a-z0-9_]+$') and #args[2]<=48,'TRACK')
        local raw=LoadResourceFile(resource,'drafts/'..args[2]..'.json') MX.require(raw,'DRAFT')
        local draft=json.decode(raw) draft.validated=true draft.activated=true
        requireModule('activities') audit(src,'track_activation_requested',draft.id,'command',{revision=draft.revision})
        exports['mx-freeroam-activities']:Publish(draft)
        audit(src,'track_activated',draft.id,'command',{revision=draft.revision}) return 'Pista ativada; revisão preservada'
    end MX.fail('ACTION','Use begin, point, export ou activate')
end)
command('mxdestination','content',function(src,args)
    MX.require(src~=0 and type(args[1])=='string' and args[1]:match('^[a-z0-9_]+$') and #args[1]<=48,'DESTINATION')
    local p=GetEntityCoords(GetPlayerPed(src))
    local d={id=args[1],name=MX.name(table.concat(args,' ',2)),category='Encontro',validated=false,radius=100,slots={{x=p.x,y=p.y,z=p.z,h=GetEntityHeading(GetPlayerPed(src))}}}
    MX.require(SaveResourceFile(resource,'drafts/destination-'..d.id..'.json',json.encode(d),-1),'DISK')
    audit(src,'destination_draft',d.id,'command') return 'Rascunho exportado. Revise slots e importe em world/config.lua com nova revisão operacional após teste no jogo.'
end)
AddEventHandler('mx:profile:dropped',function(src) drafts[src]=nil end)
CreateThread(function()
    while true do Wait(3600000) pcall(function() MX.db('DELETE FROM audit_log WHERE created_at < UTC_TIMESTAMP() - INTERVAL 90 DAY') end) end
end)
