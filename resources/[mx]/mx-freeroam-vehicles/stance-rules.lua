-- Visual stance relative to native model/tuning-wheel defaults, never handling.
VehicleStanceRules={ranges={height={-.15,.15,.005},frontCamber={-12,12,.5},rearCamber={-12,12,.5},frontOffset={-.12,.20,.005},rearOffset={-.12,.20,.005},wheelSize={.8,1.25,.01},wheelWidth={.7,1.35,.01}}}
local S=VehicleStanceRules
function S.defaults() return {version=1,height=0,frontCamber=0,rearCamber=0,frontOffset=0,rearOffset=0,wheelSize=1,wheelWidth=1} end
function S.validate(value)
 if value==nil or value==false then return false end
 local keys={version=true} for k in pairs(S.ranges) do keys[k]=true end
 MX.require(MX.keys(value,keys) and value.version==1,'STANCE','Configuração de suspensão incompatível')
 for k,range in pairs(S.ranges) do MX.require(MX.number(value[k],range[1],range[2]),'STANCE','Ajuste de suspensão fora do limite: '..k) end
 return value
end
function S.signature(value)
 if not value then return '' end
 local fields={} for _,k in ipairs({'height','frontCamber','rearCamber','frontOffset','rearOffset','wheelSize','wheelWidth'}) do fields[#fields+1]=('%.4f'):format(value[k]) end
 return ':stance-v1:'..table.concat(fields,':')
end
