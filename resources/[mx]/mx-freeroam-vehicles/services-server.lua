-- Domain-owned implementation; dependencies are the existing fleet functions, never client handles.
VehicleServices={}
local S=VehicleServices
local deps
function S.configure(value) deps=value end
local actions={repair=true,clean=true,flip=true,engine=true,doors=true,stop=true,lock=true,eject=true,respawn=true,drift=true,indicatorLeft=true,indicatorRight=true,hazards=true}
-- Saved preference and effective physics are separate. An optional preset
-- failure must not destroy a usable car or masquerade as a successful toggle.
function S.driftState(v,requested,result)
 local confirmed=type(result)=='table' and result.enabled==requested and result.recovered~=false and (not requested or result.transmissionRefreshed==true)
 v.driftRequested=requested
 v.drift=confirmed and requested or false
 v.handlingUncertain=not confirmed and not (type(result)=='table' and result.recovered==true)
 local warning=type(result)=='table' and result.warning
 if not MX.text(warning,1,240) then warning='O handling de drift não foi confirmado. O carro continua disponível; diagnóstico no F8.' end
 v.handlingWarning=not confirmed and warning or nil
 if not confirmed then
  print(json.encode({level='warn',domain='vehicles',code='HANDLING_FALLBACK',vehicle=v.id,model=v.model,requested=requested,uncertain=v.handlingUncertain,detail=type(result)=='table' and type(result.detail)=='string' and MX.diagnostic(result.detail) or 'Aplicação do drift sem confirmação'}))
 end
 Entity(v.entity).state:set('mxDrift',{id=v.id,preset=VehicleDriftPreset.id,enabled=v.drift,requested=requested,uncertain=v.handlingUncertain},true)
 return confirmed
end
local driverOnly={stop=true,drift=true,indicatorLeft=true,indicatorRight=true,hazards=true}
local stationary={flip=true} -- Uprighting a moving vehicle is intentionally blocked.
local function private(src)
 return GetPlayerRoutingBucket(src)~=0 or (MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:IsPrivate(src))
end
local function flying(src)return MX.online('mx-freeroam-world') and exports['mx-freeroam-world']:TrainerActive(src) end
local function base(src)
 local ped=GetPlayerPed(src) local v=deps.selected(src)
 local status={exists=v~=nil,available={},reasons={},driver=false,near=false,doors={},drift=false,locked=false}
 local reason
 if private(src) or GetEntityHealth(ped)<=0 then reason='Disponível apenas no modo livre, com o personagem vivo'
 elseif not v or not DoesEntityExist(v.entity) then reason='Você não tem um veículo ativo'
 elseif Entity(v.entity).state.mxVehicle~=v.id or GetEntityRoutingBucket(v.entity)~=GetPlayerRoutingBucket(src) then reason='O veículo mudou ou está em outra dimensão'
 elseif MX.distance(GetEntityCoords(ped),GetEntityCoords(v.entity))>60 then reason='Aproxime-se do seu veículo ativo (até 60 m)'
 elseif flying(src) then reason='Desative o noclip antes de usar as opções do veículo'
 elseif deps.editing(src) then reason='Finalize a personalização antes de continuar' end
 if v and DoesEntityExist(v.entity) then
  status.id=v.id status.model=v.model status.drift=v.drift==true status.locked=v.locked==true
  status.handlingWarning=v.handlingWarning status.handlingUncertain=v.handlingUncertain==true
  status.driver=GetPedInVehicleSeat(v.entity,-1)==ped status.near=not reason
 end
 for kind in pairs(actions) do
  local why=reason
  if not why and driverOnly[kind] and not status.driver then why='Entre no banco do motorista do seu veículo' end
  if not why and stationary[kind] and GetEntitySpeed(v.entity)>.5 then why='Pare o veículo antes desta ação' end
  if not why and kind=='respawn' and GetEntitySpeed(v.entity)>.5 and not status.driver then why='Entre no banco do motorista para recriar um carro em movimento' end
  if not why and (kind=='respawn' or kind=='flip') and deps.passengers(v.entity,src) then why='Desembarque os outros jogadores primeiro' end
  if not why and kind=='respawn' and GetVehiclePedIsIn(ped,false)~=0 and not status.driver then why='Desembarque antes de recriar seu veículo' end
  status.available[kind]=not why status.reasons[kind]=why
 end
 return status,v
end
function S.status(src)
 local status,v=base(src)
 if status.near then
  local result=MX.callClient(src,'vehicles','serviceInfo',{net=v.net,id=v.id})
  if result.streamed then
   status.doors={}
   for _,door in ipairs(type(result.doors)=='table' and result.doors or {}) do if MX.number(door,0,5,true) then status.doors[#status.doors+1]=door end end
   if result.driftSupported==false and not status.drift then status.available.drift=false status.reasons.drift='Este modelo/build não suporta o preset completo de drift' end
  else
   for kind in pairs(actions) do status.available[kind]=false status.reasons[kind]='Aguarde o veículo carregar no cliente' end
  end
 end
 return status
end
local function valid(src,v,epoch)
 MX.require(MX.actor(src) and MX.actor(src).epoch==epoch and deps.selected(src)==v and DoesEntityExist(v.entity) and Entity(v.entity).state.mxVehicle==v.id,'OBSOLETE','O veículo ou a sessão mudou; atualize o menu')
end
function S.audit(src)
 local status,v=base(src)
 MX.require(status.near,'VEHICLE_CONTEXT',status.reasons.engine)
 local epoch=MX.actor(src).epoch
 local result=MX.callClient(src,'vehicles','handlingAudit',{net=v.net,id=v.id,enabled=v.drift==true})
 valid(src,v,epoch)
 return result
end
function S.run(src,d)
 MX.require(actions[d.kind],'ACTION','Opção de veículo indisponível')
 local status,v=base(src)
 MX.require(status.available[d.kind],'VEHICLE_CONTEXT',status.reasons[d.kind])
 MX.require(not d.vehicleId or d.vehicleId==v.id,'OBSOLETE','Você trocou de veículo; atualize o menu')
 local actor=MX.actor(src) MX.require(actor,'SESSION') local epoch=actor.epoch
 if d.kind=='doors' then MX.require(d.door==nil or MX.number(d.door,-1,5,true),'DOOR','Escolha uma porta válida') end
 if d.kind=='drift' then MX.require(type(d.enabled)=='boolean','PAYLOAD','Informe se deseja ativar o handling de drift') end
 if d.kind~='indicatorLeft' and d.kind~='indicatorRight' and d.kind~='hazards' then deps.invalidate(src,'trainer_'..d.kind) end
 valid(src,v,epoch)
 local again=base(src) MX.require(again.available[d.kind],'VEHICLE_CONTEXT',again.reasons[d.kind])
 if d.kind=='eject' then
  local count=0
  for _,player in ipairs(GetPlayers()) do
   local target=tonumber(player)
   if target~=src and GetVehiclePedIsIn(GetPlayerPed(target),false)==v.entity then
    local targetActor=MX.actor(target)
    local result=MX.callClient(target,'vehicles','eject',{net=v.net,id=v.id})
    valid(src,v,epoch)
    MX.require(result.left==true,'EJECT','Um passageiro não confirmou a saída; tente novamente')
    local deadline=GetGameTimer()+2000
    while MX.actor(target) and targetActor and MX.actor(target).epoch==targetActor.epoch and GetVehiclePedIsIn(GetPlayerPed(target),false)==v.entity and GetGameTimer()<deadline do Wait(50) end
    MX.require(not MX.actor(target) or not targetActor or MX.actor(target).epoch~=targetActor.epoch or GetVehiclePedIsIn(GetPlayerPed(target),false)~=v.entity,'EJECT','A saída do passageiro ainda não foi sincronizada')
    count=count+1
   end
  end
  return {count=count}
 elseif d.kind=='respawn' then return deps.respawn(src,v,actor)
 elseif d.kind=='drift' then
  local previous=v.drift==true
  local ok,result=pcall(MX.callClient,src,'vehicles','service',{net=v.net,id=v.id,kind='drift',enabled=d.enabled,driver=true})
  valid(src,v,epoch)
  if not ok then error(result,0) end
  if type(result)=='table' and result.fallback==true then
   S.driftState(v,d.enabled,result)
   return {enabled=v.drift,persisted=false,warning=v.handlingWarning,handlingUncertain=v.handlingUncertain}
  end
  MX.require(type(result)=='table' and result.enabled==d.enabled and (not d.enabled or result.transmissionRefreshed==true),'HANDLING','O cliente não confirmou o handling; tente novamente')
  S.driftState(v,d.enabled,result)
  local stored,failure=pcall(function()
   valid(src,v,epoch)
   deps.persistDrift(src,v,d.enabled,actor)
  end)
  if not stored then
   if DoesEntityExist(v.entity) and Entity(v.entity).state.mxVehicle==v.id then
    local rolledBack,rollback=pcall(MX.callClient,src,'vehicles','service',{net=v.net,id=v.id,kind='drift',enabled=previous,driver=true})
    if DoesEntityExist(v.entity) and Entity(v.entity).state.mxVehicle==v.id then S.driftState(v,previous,rolledBack and rollback or nil) end
   end
   error(failure,0)
  end
  return {enabled=v.drift,persisted=true,presetId=v.presetId,checked=result.checked,mismatches=result.mismatches,transmissionRefreshed=result.transmissionRefreshed}
 end
 local result=MX.callClient(src,'vehicles','service',{net=v.net,id=v.id,kind=d.kind,door=d.door or -1,driver=driverOnly[d.kind]==true})
 valid(src,v,epoch)
 if d.kind=='indicatorLeft' or d.kind=='indicatorRight' or d.kind=='hazards' then
  MX.require(type(result)=='table' and MX.number(result.indicators,0,3,true),'ACK','Estado das setas não confirmado')
  Entity(v.entity).state:set('mxIndicators',{id=v.id,mode=result.indicators},true)
 end
 if d.kind=='repair' and result.drift then S.driftState(v,true,result.drift) end
 if d.kind=='lock' then v.locked=result.locked==true end
 return result
end
