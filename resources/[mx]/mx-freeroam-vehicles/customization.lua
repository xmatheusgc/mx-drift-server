-- Native discovery and application belong to vehicles. No vehicle is spawned here.
VehicleCustomization={}
local C=VehicleCustomization
local familyCache={}
-- Legacy Lua bindings return 0/1 for this native; OAL returns booleans.
-- Normalize only at the native boundary. Network/property contracts stay strict.
function C.extraEnabled(v,id)
    local value=IsVehicleExtraTurnedOn(v,id)
    MX.require(type(value)=='boolean' or value==0 or value==1,'EXTRA_NATIVE',('Não foi possível ler o estado do extra %s (retorno %s).'):format(tostring(id),type(value)))
    return value==true or value==1
end
local function count(n) return math.max(0,math.min(1024,n or 0)) end
local function wheelSnapshot(v)
    return {family=GetVehicleWheelType(v),front=GetVehicleMod(v,23),rear=GetVehicleMod(v,24),frontTyres=GetVehicleModVariation(v,23),rearTyres=GetVehicleModVariation(v,24),modLivery=GetVehicleMod(v,48),livery=GetVehicleLivery(v),roof=GetVehicleRoofLivery(v)}
end
local function restoreWheels(v,old)
    if GetVehicleWheelType(v)~=old.family then SetVehicleWheelType(v,old.family) end
    if GetVehicleMod(v,23)~=old.front or GetVehicleModVariation(v,23)~=old.frontTyres then SetVehicleMod(v,23,old.front,old.frontTyres) end
    if GetVehicleMod(v,24)~=old.rear or GetVehicleModVariation(v,24)~=old.rearTyres then SetVehicleMod(v,24,old.rear,old.rearTyres) end
    if GetVehicleMod(v,48)~=old.modLivery then SetVehicleMod(v,48,old.modLivery,false) end
    if old.modLivery<0 and old.livery>=0 and GetVehicleLiveryCount(v)>0 and GetVehicleLivery(v)~=old.livery then SetVehicleLivery(v,old.livery) end
    if old.roof>=0 and GetVehicleRoofLiveryCount(v)>0 and GetVehicleRoofLivery(v)~=old.roof then SetVehicleRoofLivery(v,old.roof) end
end
local function label(key,fallback)
    if type(key)~='string' or key=='' then return fallback end
    local text=GetLabelText(key)
    return text and text~='NULL' and text~='' and text:sub(1,96) or fallback
end
function C.inspect(v)
    SetVehicleModKit(v,0)
    local mods,extras={},{}
    for slot=0,49 do
        local n=count(GetNumVehicleMods(v,slot))
        if VehicleProperties.allowedSlot(slot) and n>0 then mods[#mods+1]={slot=slot,count=n,label=label(GetModSlotName(v,slot),nil)} end
    end
    for id=0,20 do if DoesExtraExist(v,id) then extras[#extras+1]=id end end
    local low,high=GetModelDimensions(GetEntityModel(v))
    local neon={} for i,bone in ipairs({'neon_l','neon_r','neon_f','neon_b'}) do neon[i]=GetEntityBoneIndexByName(v,bone)~=-1 end
    local model=GetEntityModel(v) local wheelTypes=familyCache[model]
    if not wheelTypes then wheelTypes={} local old=wheelSnapshot(v)
        for family=0,12 do SetVehicleWheelType(v,family) if GetNumVehicleMods(v,23)>0 or GetNumVehicleMods(v,24)>0 then wheelTypes[#wheelTypes+1]=family end end
        restoreWheels(v,old) familyCache[model]=wheelTypes
    end
    -- Discovery cycles wheel families after spawn/stance application. Restoring
    -- the family/index alone does not restore its custom visual dimensions.
    VehicleStance.refresh(v)
    return {mods=mods,extras=extras,liveries=count(GetVehicleLiveryCount(v)),roofLiveries=count(GetVehicleRoofLiveryCount(v)),
        plateStyles=GetGameBuildNumber()>=3095 and 13 or 6,performance=VehicleConfig.performance,neon=neon,wheelTypes=wheelTypes,
        subwoofer=GetNumVehicleMods(v,19)>0,hydraulics=GetNumVehicleMods(v,38)>0 or GetNumVehicleMods(v,21)>0,
        stance=VehicleStance.options(v),
        dimensions={length=high.y-low.y,width=high.x-low.x,height=high.z-low.z}}
end
function C.options(v,slot,id)
    MX.require(MX.number(slot,0,49,true) and VehicleProperties.allowedSlot(slot),'MOD')
    if not HasThisAdditionalTextLoaded('mod_mnu',10) then
        RequestAdditionalText('mod_mnu',10)
        local deadline=GetGameTimer()+1000
        while not HasThisAdditionalTextLoaded('mod_mnu',10) and GetGameTimer()<deadline do Wait(0) end
    end
    MX.require(DoesEntityExist(v) and Entity(v).state.mxVehicle==id,'OBSOLETE')
    SetVehicleModKit(v,0)
    local names={}
    for i=0,count(GetNumVehicleMods(v,slot))-1 do names[#names+1]=label(GetModTextLabel(v,slot,i),'Opção '..(i+1)) end
    return {slot=slot,wheelType=GetVehicleWheelType(v),names=names}
end
function C.preflight(v,p)
    SetVehicleModKit(v,0)
    local old=wheelSnapshot(v)
    local recoveredMods={}
    -- Counts for wheel slots depend on wheel family. No yield, always restore.
    if old.family~=p.wheelType then SetVehicleWheelType(v,p.wheelType) end
    local ok,err=pcall(function()
        local function validWheels()
            for _,slot in ipairs({23,24}) do
                local value=p.mods[tostring(slot)] or p.mods[slot] or -1
                if value>=0 and value>=count(GetNumVehicleMods(v,slot)) then return false end
            end
            return true
        end
        -- A streamed pack/modkit can expose stale counts. Retry discovery once
        -- before treating a saved wheel index as removed. Never remap by index.
        if not validWheels() then
            familyCache[GetEntityModel(v)]=nil
            SetVehicleModKit(v,0) SetVehicleWheelType(v,p.wheelType)
            if not validWheels() then C.stockWheels(p) end
        end
        for key,value in pairs(p.mods) do
            local slot=tonumber(key)
            if VehicleProperties.allowedSlot(slot) and slot~=23 and slot~=24 then
                if value>=0 and value>=count(GetNumVehicleMods(v,slot)) then
                    SetVehicleModKit(v,0)
                    if value>=count(GetNumVehicleMods(v,slot)) then
                        p.mods[key]=-1 recoveredMods[tostring(slot)]=-1
                    end
                end
            end
        end
        -- Extra availability may depend on installed body parts. Check after mods.
        MX.require(p.livery<math.max(0,GetVehicleLiveryCount(v)),'LIVERY')
        MX.require(p.roofLivery<math.max(0,GetVehicleRoofLiveryCount(v)),'LIVERY')
        MX.require(p.plateStyle<(GetGameBuildNumber()>=3095 and 13 or 6),'PLATE')
        MX.require(not p.subwoofer or GetNumVehicleMods(v,19)>0,'MOD','Subwoofer indisponível')
        MX.require(not p.hydraulics or GetNumVehicleMods(v,38)>0 or GetNumVehicleMods(v,21)>0,'MOD','Hidráulica indisponível')
        MX.require(not p.customRearTyres or (tonumber(p.mods['24'] or p.mods[24] or -1)>=0),'TYRES')
        for i,bone in ipairs({'neon_l','neon_r','neon_f','neon_b'}) do MX.require(not p.neon[i] or GetEntityBoneIndexByName(v,bone)~=-1,'NEON','Neon indisponível nesta região do modelo') end
    end)
    restoreWheels(v,old)
    if not ok then error(err,0) end
    return next(recoveredMods) and recoveredMods or nil
end
function C.stockWheels(p)
    p.wheelType=0 p.mods[23]=nil p.mods[24]=nil p.mods['23']=-1 p.mods['24']=-1
    p.customTyres=false p.customRearTyres=false
end
function C.installWheels(v,p)
    local function matches()
        if GetVehicleWheelType(v)~=p.wheelType then return false end
        for _,slot in ipairs({23,24}) do
            local value=p.mods[tostring(slot)] or p.mods[slot] or -1
            if GetVehicleMod(v,slot)~=value then return false end
            local variation=GetVehicleModVariation(v,slot)
            if value>=0 and (variation==true or variation==1)~=(slot==23 and p.customTyres or slot==24 and p.customRearTyres or false) then return false end
        end
        return true
    end
    local function install(force)
        if force or GetVehicleWheelType(v)~=p.wheelType then SetVehicleWheelType(v,p.wheelType) end
        for _,slot in ipairs({23,24}) do
            local value=p.mods[tostring(slot)] or p.mods[slot] or -1
            local variation=slot==23 and p.customTyres or slot==24 and p.customRearTyres or false
            local actual=GetVehicleModVariation(v,slot)
            if force or GetVehicleMod(v,slot)~=value or (value>=0 and (actual==true or actual==1)~=variation) then SetVehicleMod(v,slot,value,variation) end
        end
    end
    install(false)
    if matches() then return false end
    -- Retry a native refusal once, then use verified stock wheels. This runs
    -- before body parts/liveries/paint so family resets cannot erase those mods.
    SetVehicleModKit(v,0) install(true)
    if matches() then return false end
    familyCache[GetEntityModel(v)]=nil
    C.stockWheels(p) install(true)
    MX.require(matches(),'WHEELS','Não foi possível restaurar as rodas originais; a aplicação não foi confirmada.')
    return true
end
function C.paint(v,p,base)
    ClearVehicleCustomPrimaryColour(v) ClearVehicleCustomSecondaryColour(v)
    if p.primaryFinish>=0 then SetVehicleModColor_1(v,p.primaryFinish,p.primary,p.pearlescent) end
    if p.secondaryFinish>=0 then SetVehicleModColor_2(v,p.secondaryFinish,p.secondary) end
    -- Finish natives also write palette indices. Restore the requested indices
    -- afterwards, then apply RGB overrides last.
    SetVehicleColours(v,p.primary,p.secondary)
    SetVehicleExtraColours(v,p.pearlescent,p.wheelColor)
    if p.customPrimary then SetVehicleCustomPrimaryColour(v,table.unpack(p.customPrimary)) end
    if p.customSecondary then SetVehicleCustomSecondaryColour(v,table.unpack(p.customSecondary)) end
    SetVehicleInteriorColor(v,p.interiorColor>=0 and p.interiorColor or base.interiorColor)
    SetVehicleDashboardColor(v,p.dashboardColor>=0 and p.dashboardColor or base.dashboardColor)
    ClearVehicleXenonLightsCustomColor(v)
    SetVehicleXenonLightsColor(v,p.xenonColor)
    if p.xenonCustom then SetVehicleXenonLightsCustomColor(v,table.unpack(p.xenonCustom)) end
    ToggleVehicleMod(v,19,p.subwoofer) ToggleVehicleMod(v,21,p.hydraulics)
end
function C.confirmPaint(v,p)
    local primary,secondary=GetVehicleColours(v)
    for _,channel in ipairs({
        {name='principal',rgb=p.customPrimary,index=p.primary,actual=primary,custom=GetIsVehiclePrimaryColourCustom,read=GetVehicleCustomPrimaryColour},
        {name='secundária',rgb=p.customSecondary,index=p.secondary,actual=secondary,custom=GetIsVehicleSecondaryColourCustom,read=GetVehicleCustomSecondaryColour}
    }) do
        local custom=channel.custom(v) local enabled=custom==true or custom==1
        if channel.rgb then
            local r,g,b=channel.read(v) local expected=table.concat(channel.rgb,',')
            MX.require(enabled and r==channel.rgb[1] and g==channel.rgb[2] and b==channel.rgb[3],
                'APPLY',('Pintura %s RGB não confirmada no modelo %s: solicitado %s; recebido %s,%s,%s (RGB ativo: %s). Recarregue o estado antes de outra gravação.'):format(channel.name,tostring(GetEntityModel(v)),expected,tostring(r),tostring(g),tostring(b),tostring(enabled)))
        else
            MX.require(not enabled and channel.actual==channel.index,'APPLY',
                ('Pintura %s não confirmada no modelo %s: índice solicitado %s; recebido %s (RGB ativo: %s). Recarregue o estado antes de outra gravação.'):format(channel.name,tostring(GetEntityModel(v)),channel.index,tostring(channel.actual),tostring(enabled)))
        end
    end
end
function C.extras(v,p,base)
    for id=0,20 do
        if DoesExtraExist(v,id) then
            local value=p.extras[tostring(id)] if value==nil then value=p.extras[id] end
            if value==nil then value=base[id] end
            if value~=nil and C.extraEnabled(v,id)~=value then SetVehicleExtra(v,id,value and 0 or 1) end
        end
    end
    for key,value in pairs(p.extras) do
        MX.require(not value or DoesExtraExist(v,tonumber(key)),'EXTRA',('O extra %s não está disponível com as peças instaladas. Desative-o em Interior & detalhes > Extras.'):format(tostring(key)))
    end
end
function C.liveries(v,p,base)
    local mod=p.mods['48'] or p.mods[48]
    if mod==nil and p.livery<0 then mod=base.modLivery end
    -- Some addons expose only modkit slot 48. Native livery -1 must not reset it.
    if (mod==nil or mod<0) and GetVehicleLiveryCount(v)>0 then
        local value=p.livery>=0 and p.livery or base.livery
        if value and value>=0 and GetVehicleLivery(v)~=value then SetVehicleLivery(v,value) end
    end
    if GetVehicleRoofLiveryCount(v)>0 then
        local value=p.roofLivery>=0 and p.roofLivery or base.roofLivery
        if value and value>=0 and GetVehicleRoofLivery(v)~=value then SetVehicleRoofLivery(v,value) end
    end
end
