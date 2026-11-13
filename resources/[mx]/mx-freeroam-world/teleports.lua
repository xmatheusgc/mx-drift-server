local resource=GetCurrentResourceName()
local path='teleports.json'
local points,loadError={},nil
local function valid(d)
    local p=type(d)=='table' and type(d.slots)=='table' and d.slots[1]
    return type(d)=='table' and MX.text(d.name,1,48) and MX.text(d.category,1,24) and p and MX.number(p.x,-20000,20000) and MX.number(p.y,-20000,20000) and MX.number(p.z,-100,3000) and MX.number(p.h,0,360)
end
local raw=LoadResourceFile(resource,path)
if raw then
    local ok,value=pcall(json.decode,raw)
    if ok and type(value)=='table' then
        for id,d in pairs(value) do
            if type(id)~='string' or not id:match('^custom_%d+$') or not valid(d) then loadError='Pontos de teleporte inválidos' break end
        end
        if not loadError then points=value for id,d in pairs(points) do WorldConfig.destinations[id]=d end end
    else loadError='Não foi possível ler os pontos de teleporte' end
end
exports('CreateTeleport',function(src,name,category)
    MX.require(GetInvokingResource()=='mx-freeroam-admin' and IsPlayerAceAllowed(src,'mx.admin') and IsPlayerAceAllowed(src,'mx.content'),'FORBIDDEN','Criação exclusiva de administradores')
    MX.require(not loadError,'STORAGE',loadError)
    if type(name)=='string' then name=name:match('^%s*(.-)%s*$') end
    if type(category)=='string' then category=category:match('^%s*(.-)%s*$') end
    MX.require(MX.text(name,1,48) and MX.text(category,1,24) and not name:find('%c') and not category:find('%c'),'NAME','Informe nome e categoria válidos')
    MX.require(GetPlayerRoutingBucket(src)==0,'SESSION','Crie o ponto no mundo aberto')
    local ped=GetPlayerPed(src) MX.require(ped~=0 and DoesEntityExist(ped),'PLAYER','Posição indisponível')
    local p=GetEntityCoords(ped)
    local id='custom_'..os.time() while points[id] or WorldConfig.destinations[id] do id='custom_'..(tonumber(id:sub(8))+1) end
    local d={id=id,name=name,category=category,validated=true,radius=100,slots={{x=p.x,y=p.y,z=p.z,h=GetEntityHeading(ped)%360}}}
    MX.require(valid(d),'POSITION','Posição inválida')
    local nextPoints=MX.copy(points) nextPoints[id]=d
    local encoded=json.encode(nextPoints)
    MX.require(SaveResourceFile(resource,path,encoded,-1) and LoadResourceFile(resource,path)==encoded,'DISK','Ponto não gravado; tente novamente')
    points=nextPoints WorldConfig.destinations[id]=d
    return {id=id,name=name,category=category}
end)
