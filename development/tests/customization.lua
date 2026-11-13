-- Contract tests for actual vehicle validation/discovery, with explicit native doubles.
local n=0
local function check(v,msg) assert(v,msg) n=n+1 end
local function reject(fn) local ok=pcall(fn) check(not ok,'must reject invalid customization') end
local p=VehicleProperties.validate(VehicleProperties.defaults())
check(p.customPrimary==false and p.roofLivery==-1 and p.primaryFinish==-1,'old schema-v1 defaults')
local old=VehicleProperties.defaults() old.customTyres=true old.mods={['23']=1,['24']=1}
check(VehicleProperties.validate(old).customRearTyres==true,'legacy shared tyre variation preserved when rear wheels exist')
p.customPrimary={20,30,40} p.customSecondary={0,255,255} p.xenonCustom={255,10,0}
p.mods['23']=250 p.mods['38']=2 p.mods['49']=1 p.plateStyle=12 p.roofLivery=3 p.primaryFinish=3
check(VehicleProperties.validate(p)==p,'new fields and indices beyond 100')
local function invalid(k,v) local d=VehicleProperties.validate(VehicleProperties.defaults()) d[k]=v reject(function() VehicleProperties.validate(d) end) end
invalid('customPrimary',{256,0,0}) invalid('customSecondary',{0,0,0,0}) invalid('xenonCustom','red')
invalid('primaryFinish',6) invalid('dashboardColor',161) invalid('plateStyle',13) invalid('hydraulics',1)
invalid('mods',{['23']=1024}) invalid('mods',{['23']=1,[23]=2}) invalid('mods',{['023']=1}) invalid('mods',{['17']=0})
local wheelType=0
function SetVehicleModKit() end
function GetVehicleWheelType() return wheelType end
function GetVehicleMod() return -1 end
function GetVehicleModVariation() return false end
function SetVehicleWheelType(_,w) wheelType=w end
function GetNumVehicleMods(_,s) if s==23 then return wheelType==12 and 300 or 40 end return ({[0]=3,[38]=4,[49]=2})[s] or 0 end
function GetVehicleLiveryCount() return 4 end
function GetVehicleRoofLiveryCount() return 5 end
function GetVehicleLivery() return 0 end
function GetVehicleRoofLivery() return 0 end
function GetGameBuildNumber() return 3258 end
function DoesExtraExist(_,id) return id==1 end
function GetEntityModel() return 'futo' end
function GetModelDimensions() return {x=-1,y=-2,z=0},{x=1,y=2,z=1.4} end
function GetModSlotName(_,s) return 'slot:'..s end
function GetModTextLabel(_,s,i) return i==0 and 'native:part' or '' end
function GetLabelText(key) return key=='native:part' and 'Named native part' or 'NULL' end
function GetEntityBoneIndexByName(_,b) return b=='neon_l' and -1 or 1 end
function HasThisAdditionalTextLoaded() return true end
function DoesEntityExist() return true end
function Entity() return {state={mxVehicle='test-vehicle'}} end
VehicleStance={supported=function() return true end,refresh=function()end}
VehicleStance.options=function(v)return {available=true,tuningWheels=GetVehicleMod(v,23)>=0,ranges=VehicleStanceRules.ranges}end
local caps=VehicleCustomization.inspect(7)
check(wheelType==0 and #caps.wheelTypes==13,'discovery restores wheel family')
check(caps.neon[1]==false and caps.neon[2]==true and caps.roofLiveries==5,'model-specific capabilities')
local found={} for _,m in ipairs(caps.mods) do found[m.slot]=true end
check(found[38] and found[49] and not found[11] and not found[19],'visual slots and performance policy')
local options=VehicleCustomization.options(7,0,'test-vehicle')
check(options.names[1]=='Named native part' and options.names[2]=='Opção 2','native label and index fallback')
reject(function() VehicleCustomization.options(7,0,'obsolete') end)
p.wheelType=12 p.extras={['1']=true}
VehicleCustomization.preflight(7,p) check(wheelType==0,'wheel availability checked in requested family then restored')
p.wheelType=0 VehicleCustomization.preflight(7,p)
check(p.mods['23']==-1 and p.mods['24']==-1 and not p.customTyres and wheelType==0,'unavailable saved wheels recover to stock and restore discovery family')
p.wheelType=12 p.neon[1]=true reject(function() VehicleCustomization.preflight(7,p) end)
p.neon[1]=false p.extras['2']=true
reject(function() VehicleCustomization.extras(7,p,{}) end)
p.extras['2']=false
function IsVehicleExtraTurnedOn()return true end
function SetVehicleExtra()end
VehicleCustomization.extras(7,p,{}) check(true,'disabled absent extra does not block leaving garage')
local calls={}
for _,name in ipairs({'ClearVehicleCustomPrimaryColour','ClearVehicleCustomSecondaryColour','SetVehicleColours','SetVehicleModColor_1','SetVehicleModColor_2','SetVehicleExtraColours','SetVehicleCustomPrimaryColour','SetVehicleCustomSecondaryColour','SetVehicleInteriorColor','SetVehicleDashboardColor','SetVehicleRoofLivery','ClearVehicleXenonLightsCustomColor','SetVehicleXenonLightsColor','SetVehicleXenonLightsCustomColor','ToggleVehicleMod'}) do _G[name]=function(...) calls[name]={...} end end
VehicleCustomization.paint(7,p,{interiorColor=4,dashboardColor=5,roofLivery=0})
VehicleCustomization.liveries(7,p,{livery=0,roofLivery=0,modLivery=-1})
check(calls.SetVehicleCustomPrimaryColour[2]==20 and calls.SetVehicleRoofLivery[2]==3,'custom paint and roof applied')
check(calls.SetVehicleInteriorColor[2]==4 and calls.SetVehicleDashboardColor[2]==5,'original interior fallback')
p.customPrimary=false p.customSecondary=false p.xenonCustom=false p.roofLivery=-1
calls={} VehicleCustomization.paint(7,p,{interiorColor=4,dashboardColor=5,roofLivery=0})
GetVehicleRoofLivery=function()return 3 end
VehicleCustomization.liveries(7,p,{livery=0,roofLivery=0,modLivery=-1})
check(calls.ClearVehicleCustomPrimaryColour and not calls.SetVehicleCustomPrimaryColour and calls.ClearVehicleXenonLightsCustomColor,'cancel/reset clears RGB overrides')
check(calls.SetVehicleRoofLivery[2]==0,'original roof restored')
local liveryWrites=0
function SetVehicleLivery()liveryWrites=liveryWrites+1 end
p.mods['48']=2 p.livery=-1
VehicleCustomization.liveries(7,p,{livery=1,roofLivery=0,modLivery=1})
check(liveryWrites==0,'modkit livery never overwritten by native livery default')
p.mods['48']=nil p.livery=0
VehicleCustomization.liveries(7,p,{livery=1,roofLivery=0,modLivery=-1})
check(liveryWrites==0,'unchanged native livery is not reapplied while navigating')
print(n..' verificações de personalização com natives simuladas (não é validação FiveM)')
