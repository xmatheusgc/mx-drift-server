-- Local preferences and one effective environment, rendered by world's existing loop.
WorldEnvironment={}
local E=WorldEnvironment
local identity
local choices={
 {id='EXTRASUNNY',label='Ensolarado'},{id='CLEAR',label='Limpo'},
 {id='CLOUDS',label='Nuvens'},{id='OVERCAST',label='Encoberto'},
 {id='FOGGY',label='Neblina'},{id='SMOG',label='Névoa urbana'},
 {id='RAIN',label='Chuva'},{id='THUNDER',label='Tempestade'},
 {id='CLEARING',label='Chuva passando'},{id='NEUTRAL',label='Neutro'},
 {id='SNOW',label='Neve'},{id='SNOWLIGHT',label='Neve leve'},
 {id='BLIZZARD',label='Nevasca'},{id='XMAS',label='Natal'}
}
local known={} for _,c in ipairs(choices)do known[c.id]=true end
local allowed={syncWeather=true,syncTime=true,weather=true,hour=true,minute=true}
local function server()
 local shared=GlobalState and GlobalState.mxEnvironment
 if type(shared)=='table' and known[shared.weather] and MX.number(shared.hour,0,23,true) and MX.number(shared.minute,0,59,true) then return shared end
 return {weather=known[WorldConfig.weather] and WorldConfig.weather or 'CLEAR',hour=MX.number(WorldConfig.hour,0,23,true) and WorldConfig.hour or 14,minute=MX.number(WorldConfig.minute,0,59,true) and WorldConfig.minute or 0}
end
local function defaults()local s=server()return {syncWeather=true,syncTime=true,weather=s.weather,hour=s.hour,minute=s.minute}end
local personal=defaults()
local function valid(value)
 return MX.keys(value,allowed) and type(value.syncWeather)=='boolean' and type(value.syncTime)=='boolean' and known[value.weather] and MX.number(value.hour,0,23,true) and MX.number(value.minute,0,59,true)
end
function E.effective(presentation)
 local s=server()
 if presentation then return {weather=presentation.weather or s.weather,hour=presentation.hour,minute=presentation.minute,second=0} end
 local blend=MX.number(s.weatherBlend,0,1) and s.weatherBlend or 1
 return {weather=personal.syncWeather and s.weather or personal.weather,
     weatherFrom=personal.syncWeather and known[s.weatherFrom] and s.weatherFrom or nil,weatherBlend=blend,
     hour=personal.syncTime and s.hour or personal.hour,minute=personal.syncTime and s.minute or personal.minute,
     second=personal.syncTime and MX.number(s.second,0,59,true) and s.second or 0}
end
function E.get()
 return {syncWeather=personal.syncWeather,syncTime=personal.syncTime,weather=personal.weather,hour=personal.hour,minute=personal.minute,server=MX.copy(server()),choices=MX.copy(choices)}
end
function E.set(patch)
 MX.require(GetInvokingResource()=='mx-freeroam-menu','RESOURCE','Origem de configuração inválida')
 MX.require(identity and MX.keys(patch,allowed),'ENVIRONMENT','Configuração pessoal indisponível ou inválida')
 local nextValue=MX.copy(personal) for k,v in pairs(patch)do nextValue[k]=v end
 local s=server()
 if personal.syncWeather and nextValue.syncWeather==false and patch.weather==nil then nextValue.weather=s.weather end
 if personal.syncTime and nextValue.syncTime==false then
  if patch.hour==nil then nextValue.hour=s.hour end
  if patch.minute==nil then nextValue.minute=s.minute end
 end
 MX.require(valid(nextValue),'ENVIRONMENT','Escolha um clima válido, hora de 0 a 23 e minuto de 0 a 59')
 local encoded=json.encode(nextValue) local key='environment:'..identity
 SetResourceKvp(key,encoded)
 MX.require(GetResourceKvpString(key)==encoded,'DISK','A configuração pessoal não foi gravada')
 personal=nextValue return E.get()
end
exports('PersonalEnvironment',E.get)
exports('SetPersonalEnvironment',E.set)
AddEventHandler('mx:profile:local',function(profile)
 identity=tostring(profile.id) personal=defaults()
 local raw=GetResourceKvpString('environment:'..identity)
 if raw then local ok,value=pcall(json.decode,raw) if ok and valid(value) then personal=value end end
end)
