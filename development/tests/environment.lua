local T,E=EnvironmentTest,WorldEnvironment
assert(not pcall(E.set,{hour=3}),'personal settings require a known profile')
T.events['mx:profile:local']({id=11})
assert(E.effective().hour==18 and E.effective().weather=='OVERCAST','default follows server-published weather and time')
E.set({syncWeather=false,weather='RAIN'})
assert(E.effective().weather=='RAIN' and E.effective().hour==18,'weather can be personal while clock remains synchronized')
E.set({syncTime=false,hour=23,minute=45})
assert(E.effective().hour==23 and E.effective().minute==45 and GlobalState.mxEnvironment.hour==18,'personal time does not alter server state')
assert(E.effective({weather='FOGGY',hour=23,minute=0}).weather=='FOGGY','lobby weather wins over personal rain')
assert(E.effective({hour=12,minute=0}).weather=='OVERCAST','garage lighting does not inherit personal weather')
assert(E.effective().weather=='RAIN' and E.effective().minute==45,'leaving presentation restores personal environment')
assert(not pcall(E.set,{hour=24}) and not pcall(E.set,{minute=-1}) and not pcall(E.set,{weather='CUSTOM'}),'invalid native arguments are rejected')
assert(not pcall(E.set,{extra=true}) and not pcall(E.set,{syncTime='false'}),'unknown fields and nonboolean synchronization are rejected')
T.invoker='other' assert(not pcall(E.set,{hour=1}),'only the menu can invoke the settings setter') T.invoker='mx-freeroam-menu'
T.failWrite=true assert(not pcall(E.set,{hour=1}) and E.effective().hour==23,'failed KVP write does not change effective state') T.failWrite=false
T.events['mx:profile:local']({id=12}) assert(E.get().syncTime and E.get().syncWeather,'profiles do not inherit custom environment')
T.events['mx:profile:local']({id=11}) assert(E.effective().hour==23 and E.effective().weather=='RAIN','personal settings survive a profile reload')
GlobalState.mxEnvironment={weather='CLEAR',hour=8,minute=5}
GlobalState.mxEnvironment.weatherFrom='RAIN' GlobalState.mxEnvironment.weatherBlend=.4 GlobalState.mxEnvironment.second=30
assert(E.effective().weatherFrom==nil and E.effective().second==0,'personal weather and time ignore server progression')
E.set({syncWeather=true,syncTime=true}) assert(E.effective().hour==8 and E.effective().weather=='CLEAR','resynchronizing follows current server state')
assert(E.effective().weatherFrom=='RAIN' and E.effective().weatherBlend==.4 and E.effective().second==30,'sync restores current server clock and weather transition')
E.set({syncTime=false}) assert(E.effective().hour==8 and E.effective().minute==5,'starting a personal clock copies current server time')
T.kvp['environment:11']='corrupt' T.events['mx:profile:local']({id=11})assert(E.get().syncTime,'corrupt preference safely falls back to synchronization')
GlobalState=nil MX.copy=T.oldCopy json=T.oldJson
print('Personal environment: independent sync, native argument validation, presentation precedence, current server state, per-profile persistence and write failure passed with KVP adapters.')
