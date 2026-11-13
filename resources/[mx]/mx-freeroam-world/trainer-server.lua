-- Personal freeroam tools. Checkpoints are captured by the server, never supplied by NUI.
WorldTrainer={sessions={},checkpoints={},settings={}}
local T=WorldTrainer
local grantSequence=0
local grantBoot=('%x-%x'):format(os.time(),math.random(1,0x7fffffff))
local function grantToken() grantSequence=grantSequence+1 return 'trainer-'..grantBoot..'-'..grantSequence end
local function public(src)
    local actor=MX.actor(src)
    MX.require(actor and GetPlayerRoutingBucket(src)==0 and GetEntityHealth(GetPlayerPed(src))>0,'SESSION','Disponível apenas no modo livre, com o personagem vivo')
    MX.require(not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION','Saia da garagem antes de usar o trainer')
    return actor
end
local function driven(src)
    local ped=GetPlayerPed(src)
    if GetVehiclePedIsIn(ped,false)==0 then return ped end
    return exports['mx-freeroam-vehicles']:OwnedDriver(src,true).entity
end
local function invalidate(src,why)
    if MX.online('mx-freeroam-activities') then exports['mx-freeroam-activities']:Invalidate(src,why) end
end
function T.stop(src)
    local s=T.sessions[src]
    if s then
        -- Keep the grant until the client has restored collision/freeze.
        local response=MX.callClient(src,'trainer','stop',{token=s.token})
        MX.require(response.stopped==true,'TRAINER','Não foi possível encerrar o noclip; tente novamente')
        T.sessions[src]=nil
    end
end
function T.status(src)
    local actor=public(src) local cp=T.checkpoints[src]
    if cp and cp.epoch~=actor.epoch then T.checkpoints[src]=nil cp=nil end
    local pref=T.settings[src]
    if not pref or pref.epoch~=actor.epoch then pref={epoch=actor.epoch,speed=TrainerConfig.defaultSpeed,followCamera=true} T.settings[src]=pref end
    local labels={} for _,level in ipairs(TrainerConfig.speeds) do labels[#labels+1]=level.label end
    return {noclip=T.sessions[src]~=nil,speed=pref.speed,followCamera=pref.followCamera,speedLabels=labels,checkpoint=cp and MX.copy(cp.point) or false}
end
function T.noclip(src,d)
    local actor=public(src)
    MX.require(type(d.enabled)=='boolean','PAYLOAD','Estado de noclip inválido')
    if not d.enabled then T.stop(src) return T.status(src) end
    local previous=T.status(src)
    local speed=d.speed or previous.speed
    local followCamera=previous.followCamera
    if d.followCamera~=nil then followCamera=d.followCamera end
    MX.require(MX.number(speed,1,#TrainerConfig.speeds,true) and type(followCamera)=='boolean','PAYLOAD','Velocidade ou modo de noclip inválido')
    local entity=driven(src) local s=T.sessions[src]
    if s then MX.require(s.entity==entity and s.epoch==actor.epoch,'ENTITY','O veículo mudou; desative o noclip antes de continuar') end
    invalidate(src,'noclip')
    s=s or {token=grantToken(),entity=entity,epoch=actor.epoch}
    s.speed=speed s.followCamera=followCamera T.sessions[src]=s
    local ok,result=pcall(MX.callClient,src,'trainer','start',{token=s.token,net=entity~=GetPlayerPed(src) and NetworkGetNetworkIdFromEntity(entity) or nil,id=entity~=GetPlayerPed(src) and Entity(entity).state.mxVehicle or nil,speed=speed,followCamera=followCamera})
    if not ok or not result.active then
        -- A lost ACK is ambiguous: retain the grant until stop is acknowledged.
        local stopped=pcall(T.stop,src)
        if not stopped then print('[MX:TRAINER] Noclip sem confirmação de encerramento: '..src) end
        if not ok then error(result,0) end
        MX.fail('TRAINER','Não foi possível ativar o noclip')
    end
    T.settings[src]={epoch=actor.epoch,speed=speed,followCamera=followCamera}
    return T.status(src)
end
function T.toggle(src) return T.noclip(src,{enabled=not (T.sessions[src]~=nil)}) end
function T.save(src)
    local actor=public(src) MX.require(not T.sessions[src],'NOCLIP','Desative o noclip antes de marcar o checkpoint')
    local entity=driven(src) local p=GetEntityCoords(entity)
    MX.require(MX.number(p.x,-20000,20000) and MX.number(p.y,-20000,20000) and MX.number(p.z,-100,3000),'POSITION','Posição fora da área suportada')
    local rotation=GetEntityRotation(entity,2)
    T.checkpoints[src]={epoch=actor.epoch,point={x=p.x,y=p.y,z=p.z,h=GetEntityHeading(entity)%360,pitch=rotation.x,roll=rotation.y}}
    return T.status(src)
end
function T.clear(src) public(src) T.checkpoints[src]=nil return T.status(src) end
function T.returnTo(src)
    local actor=public(src) local cp=T.checkpoints[src]
    MX.require(cp and cp.epoch==actor.epoch,'CHECKPOINT','Crie um checkpoint primeiro (F3)')
    T.stop(src)
    local withCar=GetVehiclePedIsIn(GetPlayerPed(src),false)~=0
    T.travel(src,WorldConfig.home,withCar,cp.point,true)
    return T.status(src)
end
exports('TrainerActive',function(src) return T.sessions[src]~=nil end)
exports('StopTrainer',T.stop)
RegisterNetEvent('mx:trainer:stopped',function(token)
    local s=T.sessions[source] if s and s.token==token then T.sessions[source]=nil end
end)
RegisterNetEvent('mx:trainer:settings',function(token,speed,followCamera)
    local src=source local s=T.sessions[src] local actor=MX.actor(src)
    if not s or s.token~=token or not actor or actor.epoch~=s.epoch or GetPlayerRoutingBucket(src)~=0 then return end
    if not MX.number(speed,1,#TrainerConfig.speeds,true) or type(followCamera)~='boolean' then return end
    s.speed=speed s.followCamera=followCamera T.settings[src]={epoch=actor.epoch,speed=speed,followCamera=followCamera}
end)
AddEventHandler('playerDropped',function() T.sessions[source]=nil T.checkpoints[source]=nil T.settings[source]=nil end)
CreateThread(function()
    while true do
        Wait(500)
        for src,s in pairs(T.sessions) do
            local ok,entity=pcall(function() local a=public(src) MX.require(a.epoch==s.epoch,'SESSION') return driven(src) end)
            if not ok or entity~=s.entity then pcall(T.stop,src) end
        end
    end
end)
