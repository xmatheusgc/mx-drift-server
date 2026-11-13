local T=PresentationTest local P=WorkshopPresentation
function GetEntityBoneIndexByName()return 1 end
T.vehicle=nil T.entities[10].id='preview' T.rpmWrites=0
P.start('lighting',10,'preview',{x=5,y=6,z=1.08,h=300,groundZ=0})
local function preview(enabled,layout)
    return P.previewNeon({id='lighting',enabled=enabled,layout=layout or {true,true,true,true},color={30,80,160},restore={false,true,false,false},restoreColor={10,20,30}})
end
ExperienceConfig.neonPreview.engine=false
preview(true) P.tick(.016)
assert(T.entities[10].neon[1] and T.entities[10].lights==2 and not T.entities[10].engine,'neon-only preview supports engine-off mode')
ExperienceConfig.neonPreview.engine=true
P.tick(.016)
assert(T.entities[10].engine and T.controls[71]==0 and T.rpmWrites==0,'neon power idles without rev input or RPM injection during startup')
preview(true,{false,true,false,false}) P.tick(.016)
assert(not T.entities[10].neon[1] and T.entities[10].neon[2] and not T.entities[10].neon[3],'layout preview respects selected sides')
assert(P.previewNeon({id='old-editor',enabled=false}).ignored and P.session.neon,'stale editor cannot disable current preview')
preview(true,{false,false,false,false}) P.tick(.016)
assert(not T.entities[10].engine,'all sides disabled do not require preview engine power')
preview(false) P.tick(.016)
assert(not T.entities[10].engine and T.entities[10].neonColor[1]==10 and not T.entities[10].neon[1] and T.entities[10].neon[2],'leaving restores confirmed neon and stops preview-only power')
-- Cranking alone gates input. Once the native says running, no extra delay.
T.cranking=true P.rev('lighting',true)
function GetIsVehicleEngineRunning(v)return T.cranking and 0 or (T.entities[v].engine and 1 or 0)end
for _=1,20 do T.time=T.time+50 P.rev('lighting',true) P.tick(.05)end
assert(T.controls[71]==0 and T.rpmWrites==0,'cranking does not receive throttle or forced RPM')
T.cranking=false T.time=T.time+1 P.tick(.001)
assert(T.controls[71]==1 and T.rpmWrites==0,'native engine ACK releases throttle immediately with no artificial warmup')
P.rev('lighting',.25) P.tick(.05)
assert(T.controls[71]==.25 and T.rpmWrites==0,'partial trigger remains analog without RPM writes')
for _=1,20 do T.time=T.time+20 P.rev('lighting',.25) P.tick(.02) end
assert(T.controls[71]==.25 and T.rpmWrites==0,'GTA retains control over RPM throughout analog input')
P.rev('lighting',0) P.tick(.05)
assert(T.controls[71]==0 and P.session.revUntil==0,'zero analog input releases immediately; Lua zero is not a pressed boolean')
P.rev('lighting',.03) P.tick(.05)
assert(T.controls[71]==0,'trigger noise is ignored')
P.rev('lighting',2) P.tick(.05)
assert(T.controls[71]==1,'analog input clamps at full throttle')
P.rev('lighting',-.5) P.tick(.05)
assert(T.controls[71]==0,'negative trigger input cannot accelerate')
preview(true) P.tick(.016) P.stop('lighting')
assert(not T.entities[10].engine and T.entities[10].neonColor[1]==10 and not T.entities[10].neon[1],'editor close restores neon and stops engine')
print('Neon/engine-start/analog regressions passed with native doubles; actual emitted light and sound require FiveM.')
