VehicleProperties={}
local cosmetic={[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[14]=true,[23]=true,[24]=true,[25]=true,[26]=true,[27]=true,[28]=true,[29]=true,[30]=true,[31]=true,[32]=true,[33]=true,[34]=true,[35]=true,[36]=true,[37]=true,[38]=true,[39]=true,[40]=true,[41]=true,[42]=true,[43]=true,[44]=true,[45]=true,[46]=true,[47]=true,[48]=true,[49]=true}
local performance={[11]=true,[12]=true,[13]=true,[15]=true,[16]=true}
local optional={stance=false,customPrimary=false,customSecondary=false,primaryFinish=-1,secondaryFinish=-1,interiorColor=-1,dashboardColor=-1,roofLivery=-1,customRearTyres=false,xenonCustom=false,subwoofer=false,hydraulics=false}
function VehicleProperties.defaults() return {schemaVersion=1,primary=0,secondary=0,pearlescent=0,wheelColor=0,wheelType=0,mods={},extras={},livery=-1,plate='MX JDM',plateStyle=0,tint=-1,xenon=false,xenonColor=255,neon={false,false,false,false},neonColor={255,255,255},smokeColor={255,255,255},turbo=false,smoke=false,customTyres=false} end
function VehicleProperties.validate(p)
    local keys={schemaVersion=true,primary=true,secondary=true,pearlescent=true,wheelColor=true,wheelType=true,mods=true,extras=true,livery=true,plate=true,plateStyle=true,tint=true,xenon=true,xenonColor=true,neon=true,neonColor=true,smokeColor=true,turbo=true,smoke=true,customTyres=true}
    for k in pairs(optional) do keys[k]=true end
    MX.require(MX.keys(p,keys),'PROPERTIES')
    -- Additive schema-v1 fields: existing saved documents remain readable.
    for k,v in pairs(optional) do
        if p[k]==nil then
            if k=='customRearTyres' then p[k]=p.customTyres==true and type(p.mods)=='table' and tonumber(p.mods['24'] or p.mods[24] or -1)~=nil and tonumber(p.mods['24'] or p.mods[24] or -1)>=0
            else p[k]=v end
        end
    end
    p.stance=VehicleStanceRules.validate(p.stance)
    MX.require(p.schemaVersion==VehicleConfig.schema,'SCHEMA')
    for _,k in ipairs({'primary','secondary','pearlescent','wheelColor'}) do MX.require(MX.number(p[k],0,160,true),'COLOR') end
    MX.require(MX.number(p.wheelType,0,12,true) and MX.number(p.tint,-1,6,true) and MX.number(p.livery,-1,1023,true) and MX.number(p.plateStyle,0,12,true),'PROPERTIES')
    for _,k in ipairs({'primaryFinish','secondaryFinish'}) do MX.require(MX.number(p[k],-1,5,true),'PAINT') end
    for _,k in ipairs({'interiorColor','dashboardColor'}) do MX.require(MX.number(p[k],-1,160,true),'COLOR') end
    MX.require(MX.number(p.roofLivery,-1,1023,true),'LIVERY')
    for _,k in ipairs({'customRearTyres','subwoofer','hydraulics'}) do MX.require(type(p[k])=='boolean','PROPERTIES') end
    for _,k in ipairs({'customPrimary','customSecondary','xenonCustom'}) do
        local rgb=p[k]
        MX.require(rgb==false or (type(rgb)=='table' and MX.keys(rgb,{[1]=true,[2]=true,[3]=true}) and #rgb==3),'COLOR')
        if rgb~=false then for _,v in ipairs(rgb) do MX.require(MX.number(v,0,255,true),'COLOR') end end
    end
    MX.require(MX.text(p.plate,1,8) and p.plate:match('^[A-Z0-9 ]+$'),'PLATE','Use placa de até 8 letras maiúsculas/números')
    MX.require(type(p.xenon)=='boolean' and type(p.turbo)=='boolean' and type(p.smoke)=='boolean' and type(p.customTyres)=='boolean','PROPERTIES')
    MX.require(VehicleConfig.performance or not p.turbo,'PERFORMANCE','Mods de desempenho desabilitados')
    MX.require(MX.number(p.xenonColor,-1,255,true) and (p.xenonColor<=12 or p.xenonColor==255),'PROPERTIES')
    MX.require(type(p.mods)=='table' and type(p.extras)=='table','PROPERTIES')
    local count=0 for key,value in pairs(p.mods) do
        local slot=tonumber(key) count=count+1
        MX.require(slot and slot%1==0 and (type(key)=='number' or key==tostring(slot)) and (cosmetic[slot] or (slot>=19 and slot<=22) or (VehicleConfig.performance and performance[slot])) and MX.number(value,-1,1023,true),'MOD')
        MX.require(not (type(key)=='number' and p.mods[tostring(key)]~=nil),'MOD','Slot repetido')
    end MX.require(count<=49,'MOD')
    MX.require(not p.customTyres or (tonumber(p.mods['23'] or p.mods[23] or -1)>=0),'TYRES','Selecione rodas compatíveis antes de pneus personalizados')
    count=0 for key,value in pairs(p.extras) do count=count+1 MX.require(MX.number(tonumber(key),0,20,true) and type(value)=='boolean','EXTRA',('Configuração do extra %s inválida: esperado booleano, recebido %s. A aplicação não foi confirmada.'):format(tostring(key),type(value))) end MX.require(count<=21,'EXTRA','A configuração excede o limite de 21 extras')
    MX.require(type(p.neon)=='table' and MX.keys(p.neon,{[1]=true,[2]=true,[3]=true,[4]=true}) and #p.neon==4,'PROPERTIES')
    for _,v in ipairs(p.neon) do MX.require(type(v)=='boolean','PROPERTIES') end
    for _,rgb in ipairs({p.neonColor,p.smokeColor}) do MX.require(type(rgb)=='table' and MX.keys(rgb,{[1]=true,[2]=true,[3]=true}) and #rgb==3,'COLOR') for _,v in ipairs(rgb) do MX.require(MX.number(v,0,255,true),'COLOR') end end
    return p
end
function VehicleProperties.publish(entity,id,p)
    Entity(entity).state:set('mxStance',{id=id,value=p.stance or false},true)
    Entity(entity).state:set('mxXenon',{id=id,rgb=p.xenonCustom or false,index=p.xenonColor,enabled=p.xenon},true)
end
function VehicleProperties.signature(p)
    local fields={tostring(p.wheelType),tostring(p.mods['23'] or p.mods[23] or -1),tostring(p.mods['24'] or p.mods[24] or -1),tostring(p.customTyres),tostring(p.customRearTyres or false),tostring(p.turbo)}
    for _,slot in ipairs({11,12,13,15,16}) do fields[#fields+1]=tostring(p.mods[tostring(slot)] or p.mods[slot] or -1) end
    return 'native-v2:'..table.concat(fields,':')..VehicleStanceRules.signature(p.stance)
end
function VehicleProperties.allowedSlot(slot) return cosmetic[slot] or (VehicleConfig.performance and performance[slot]) end
function VehicleProperties.acceptStance(properties,result)
 local accepted=MX.copy(properties)
 if result.modsRecovered~=nil then
  MX.require(type(result.modsRecovered)=='table','APPLY','A recuperação das peças não foi confirmada')
  local n=0
  for key,value in pairs(result.modsRecovered) do
   local slot=tonumber(key) local requested=slot and (accepted.mods[tostring(slot)] or accepted.mods[slot])
   MX.require(type(key)=='string' and slot and key==tostring(slot) and VehicleProperties.allowedSlot(slot) and slot~=23 and slot~=24 and value==-1 and type(requested)=='number' and requested>=0,'APPLY','Recuperação de peça inválida')
   accepted.mods[slot]=nil accepted.mods[key]=-1 n=n+1
  end
  MX.require(n>0 and n<=49,'APPLY','Recuperação de peças vazia ou inválida')
 end
 -- Only the narrow, verified stock-wheel recovery can replace requested wheels.
 -- Do not accept arbitrary property patches from the client acknowledgement.
 if result.wheels~=nil then
  local w=result.wheels
  MX.require(type(w)=='table' and MX.keys(w,{wheelType=true,front=true,rear=true,customTyres=true,customRearTyres=true}) and w.wheelType==0 and w.front==-1 and w.rear==-1 and w.customTyres==false and w.customRearTyres==false,'APPLY','A recuperação das rodas não foi confirmada')
  accepted.wheelType=0 accepted.mods[23]=nil accepted.mods[24]=nil accepted.mods['23']=-1 accepted.mods['24']=-1
  accepted.customTyres=false accepted.customRearTyres=false
 end
 if result.stance~=nil then
  MX.require(type(result.stance)=='table' and result.stance.value~=nil,'APPLY','A suspensão aplicada não foi confirmada')
  accepted.stance=MX.copy(VehicleStanceRules.validate(result.stance.value))
 end
 return accepted
end
