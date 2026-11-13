-- Independent key state avoids unbinding commands belonging to other resources.
MenuBindings={}
local B=MenuBindings
local specs={
 {'menu','Menu do modo livre','M','VIEW'}, {'repair','Reparar veículo','R'},
 {'noclip','Alternar noclip','F2'}, {'saveCheckpoint','Criar checkpoint','F3'}, {'returnCheckpoint','Voltar ao checkpoint','F4'},
 {'clean','Limpar veículo',''}, {'flip','Desvirar veículo',''}, {'engine','Ligar / desligar motor','G','LEFT'}, {'doors','Abrir / fechar portas',''}, {'stop','Parar o carro',''}, {'lock','Trancar / destrancar veículo',''}, {'eject','Expulsar ocupantes',''}, {'respawn','Recriar veículo',''}, {'drift','Handling de drift',''},
 {'indicatorLeft','Seta esquerda','LEFT'}, {'indicatorRight','Seta direita','RIGHT'}, {'hazards','Pisca-alerta','DOWN'},
 {'garage','Voltar para a garagem',''}, {'recover','Recuperar a pé',''}, {'clearCheckpoint','Remover checkpoint',''}, {'drivecam','Câmera de condução','F7'},
 {'cycleSpeed','Noclip: velocidade','SHIFT','A'}, {'up','Noclip: subir','Q','RB'}, {'down','Noclip: descer','Z','DOWN'}, {'cameraMode','Noclip: orientação','H','RIGHT'}
}
local keys={SHIFT=16,SPACE=32,TAB=9,LEFT=37,UP=38,RIGHT=39,DOWN=40}
for n=65,90 do keys[string.char(n)]=n end
for n=48,57 do keys[string.char(n)]=n end
for n=1,12 do if n~=8 then keys['F'..n]=111+n end end
local pads={VIEW=244,LB=205,RB=206,LS=28,RS=29,A=201,B=202,X=203,Y=204,UP=188,DOWN=187,LEFT=189,RIGHT=190}
local values,identity={},nil
local function defaults() local result={} for _,s in ipairs(specs) do result[s[1]]={key=s[3],pad=s[4] or ''} end return result end
values=defaults()
local function known(action) for _,s in ipairs(specs) do if s[1]==action then return true end end end
local function encodeBindings(bindings)
    local saved=MX.copy(bindings) saved._version=3 return json.encode(saved)
end
function B.candidates(kind) return MX.copy(kind=='key' and keys or pads) end
function B.keyInput(action,held)
    local v=values[action] if not v then return false end
    if v.key=='SHIFT' then
        for _,k in ipairs({16,160,161}) do if held and IsRawKeyDown(k) or not held and IsRawKeyPressed(k) then return true end end
        return false
    end
    local k=keys[v.key]
    return k~=nil and (held and IsRawKeyDown(k) or not held and IsRawKeyPressed(k))
end
function B.list()
    local result={}
    for _,s in ipairs(specs) do result[#result+1]={id=s[1],label=s[2],key=values[s[1]].key,pad=values[s[1]].pad,default=s[3]} end
    return result
end
function B.update(action,kind,value)
    MX.require(identity and known(action) and (kind=='key' or kind=='pad'),'BIND','Ação de controle inválida')
    MX.require(type(value)=='string','BIND','Informe uma tecla') value=value:upper()
    MX.require(value=='' or (kind=='key' and keys[value] or kind=='pad' and pads[value]),'BIND','Tecla ou botão não suportado. ESC e F8 são reservados.')
    for id,v in pairs(values) do MX.require(id==action or value=='' or v[kind]~=value,'BIND_CONFLICT','Este botão já está atribuído a outra função') end
    local nextValues=MX.copy(values) nextValues[action][kind]=value
    local encoded=encodeBindings(nextValues)
    SetResourceKvp('bindings:'..identity,encoded)
    MX.require(GetResourceKvpString('bindings:'..identity)==encoded,'DISK','Atalho não gravado')
    values=nextValues
    return B.list()
end
function B.padInput(action,held)
    local v=values[action] if not v or IsInputDisabled(0) then return false end
    local c=pads[v.pad] if not c then return false end
    -- Some controller layouts also report interaction while pressing D-pad left.
    if c==244 and (IsControlPressed(0,189) or IsDisabledControlPressed(0,189) or IsControlPressed(0,85) or IsDisabledControlPressed(0,85)) then return false end
    if c==189 then
        if held and (IsControlPressed(0,85) or IsDisabledControlPressed(0,85)) or not held and (IsControlJustPressed(0,85) or IsDisabledControlJustPressed(0,85)) then return true end
    end
    if held then return IsControlPressed(0,c) or IsDisabledControlPressed(0,c) end
    return IsControlJustPressed(0,c) or IsDisabledControlJustPressed(0,c)
end
function B.input(action,held)
    local v=values[action] if not v then return false end
    local k=keys[v.key]
    -- Windows exposes the physical left/right modifiers on some clients.
    -- Keep the configured SHIFT binding (and respect removal/remapping).
    if v.key=='SHIFT' then
        for _,modifier in ipairs({16,160,161}) do
            if held and IsRawKeyDown(modifier) or not held and IsRawKeyPressed(modifier) then return true end
        end
        k=nil
    end
    if k and (held and IsRawKeyDown(k) or not held and IsRawKeyPressed(k)) then return true end
    return B.padInput(action,held)
end
exports('BindingInput',B.input)
AddEventHandler('mx:profile:local',function(profile)
    identity=tostring(profile.id) values=defaults()
    local raw=GetResourceKvpString('bindings:'..identity)
    if raw then
        local ok,saved=pcall(json.decode,raw)
        if ok and type(saved)=='table' then
            for id,v in pairs(saved) do if known(id) and type(v)=='table' and (v.key=='' or keys[v.key]) and (v.pad=='' or pads[v.pad]) then values[id]={key=v.key,pad=v.pad} end end
            -- Old profiles saved an empty menu pad before a default existed.
            -- Versioned saves preserve explicit removal/remapping thereafter.
            if saved._version~=2 and saved._version~=3 then
                if values.menu.pad=='' then values.menu.pad='VIEW' end
            end
            if saved._version~=3 then
                -- Populate the former empty engine defaults only when free.
                for kind,value in pairs({key='G',pad='LEFT'}) do
                    local free=values.engine[kind]==''
                    for id,v in pairs(values) do
                        if id~='engine' and v[kind]==value then
                            free=false
                            if not saved.engine and values.engine[kind]==value then values.engine[kind]='' end
                        end
                    end
                    if free then values.engine[kind]=value end
                end
                local encoded=encodeBindings(values)
                SetResourceKvp('bindings:'..identity,encoded)
                MX.require(GetResourceKvpString('bindings:'..identity)==encoded,'DISK','Atalhos migrados não foram gravados')
            end
        end
    end
    SendNUIMessage({type='bindings',data=B.list()})
end)
