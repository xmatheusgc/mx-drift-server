-- Only this server domain owns bans. Keep this file outside client files.
local resource=GetCurrentResourceName()
local path='bans.json'
local bans,storageError={},nil
local raw=LoadResourceFile(resource,path)
if raw then
    local ok,value=pcall(json.decode,raw)
    if ok and type(value)=='table' then
        for id,ban in pairs(value) do
            if type(id)~='string' or not id:match('^license:') or type(ban)~='table' or not MX.text(ban.reason,3,120) then storageError='Arquivo de banimentos inválido' break end
        end
        if not storageError then bans=value end
    else storageError='Arquivo de banimentos inválido' end
end
local function allowed(src,action)
    return src==0 or (IsPlayerAceAllowed(src,'mx.admin') and IsPlayerAceAllowed(src,'mx.'..action))
end
local function authorize(src,action) MX.require(allowed(src,action),'FORBIDDEN','Ação exclusiva de administradores autorizados') end
local function persist(nextBans)
    MX.require(not storageError,'STORAGE',storageError)
    local encoded=json.encode(nextBans)
    MX.require(SaveResourceFile(resource,path,encoded,-1) and LoadResourceFile(resource,path)==encoded,'DISK','Não foi possível confirmar a gravação do banimento')
    bans=nextBans
end
exports('CheckConnection',function(identifier)
    MX.require(not storageError,'STORAGE',storageError)
    local ban=bans[identifier]
    if ban then return 'MX: acesso banido. Motivo: '..ban.reason end
end)
AdminModeration={allowed=allowed,authorize=authorize}
function AdminModeration.apply(src,d,requestId,audit)
    MX.require(d.action=='warn' or d.action=='kick' or d.action=='ban','ACTION','Moderação inválida')
    authorize(src,d.action)
    local actor=MX.actor(src)
    MX.require(actor,'SESSION','Sessão administrativa expirada')
    if type(d.reason)=='string' then d.reason=d.reason:match('^%s*(.-)%s*$') end
    MX.require(MX.number(d.target,1,65535,true) and d.target~=src,'PLAYER','Selecione outro jogador conectado')
    MX.require(MX.text(d.reason,3,120) and not d.reason:find('%c'),'REASON','Informe um motivo entre 3 e 120 caracteres')
    local target=d.target
    MX.require(GetPlayerName(target) and not IsPlayerAceAllowed(target,'mx.admin'),'PLAYER','Jogador desconectado ou administrador protegido')
    local identifier=GetPlayerIdentifierByType(target,'license')
    MX.require(type(identifier)=='string' and identifier:match('^license:'),'IDENTITY','Identidade do jogador indisponível')
    audit(src,d.action..'_requested',identifier,requestId,{reason=d.reason,source=target})
    -- Audit yields: source IDs and permissions must be revalidated afterwards.
    authorize(src,d.action)
    MX.require(MX.actor(src) and MX.actor(src).epoch==actor.epoch,'SESSION','A sessão administrativa mudou')
    MX.require(GetPlayerIdentifierByType(target,'license')==identifier and GetPlayerName(target) and not IsPlayerAceAllowed(target,'mx.admin'),'PLAYER','O jogador mudou ou desconectou; ação cancelada')
    if d.action=='ban' then
        local nextBans=MX.copy(bans)
        nextBans[identifier]={reason=d.reason,actor=actor.id,created=os.time(),requestId=requestId}
        persist(nextBans)
    end
    if d.action=='warn' then TriggerClientEvent('mx:notify',target,'AVISO DA ADMINISTRAÇÃO: '..d.reason)
    else DropPlayer(target,(d.action=='ban' and 'Banido: ' or 'Expulso: ')..d.reason) end
    return {applied=true,action=d.action}
end
RegisterCommand('mxunban',function(src,args)
    local ok,result=pcall(function()
        authorize(src,'ban')
        local identifier=args[1]
        MX.require(type(identifier)=='string' and bans[identifier],'PLAYER','Use mxunban license:identificador de um banimento existente')
        local nextBans=MX.copy(bans) nextBans[identifier]=nil persist(nextBans)
        return 'Banimento removido'
    end)
    local message=ok and result or MX.error(result).message
    if src==0 then print('[MX] '..message) else TriggerClientEvent('mx:notify',src,message) end
end,false)
