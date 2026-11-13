local total=0
local function check(ok,name) assert(ok,name) total=total+1 end
local R,M=ExperienceRules,DrivecamMath
check(R.inEntry({x=120,y=-3050,z=6}) and R.inEntry({x=160,y=-3007,z=10}),'workshop entry includes normalized boundaries')
for _,point in ipairs({{x=119.99,y=-3020,z=7},{x=160.01,y=-3020,z=7},{x=140,y=-3050.01,z=7},{x=140,y=-3006.99,z=7},{x=140,y=-3020,z=5.99},{x=140,y=-3020,z=10.01}}) do check(not R.inEntry(point),'entry excludes positions outside each axis') end
check(R.phase({character_completed=0,vehicle_completed=0},false,false)=='character','creation before vehicle')
check(R.phase({character_completed=1,vehicle_completed=0},false,false)=='firstCar','partial onboarding resumes')
check(R.phase({character_completed=1,vehicle_completed=1},false,false)=='empty','deleting last does not reset onboarding')
check(R.phase({character_completed=1,vehicle_completed=1},false,true)=='unavailable','missing assets preserved')
check(R.phase({character_completed=1,vehicle_completed=1},true,true)=='workshop','valid selection')
check(R.uuid('12345678-1234-1234-1234-123456789abc'),'UUID valid')
check(not R.uuid(string.rep('a',36)),'UUID malformed')
for _,model in ipairs({'mp_m_freemode_01','mp_f_freemode_01'}) do check(pcall(R.appearance,R.preset(model)),'preset validates') end
local a=R.preset() a.features[1]=0/0 check(not pcall(R.appearance,a),'NaN rejected')
a=R.preset() a.components[1].drawable=1001 check(not pcall(R.appearance,a),'oversized drawable rejected')
a=R.preset() a.economy=1 check(not pcall(R.appearance,a),'unknown appearance fields rejected')
check(math.abs(math.deg(M.angle(math.rad(-179)-math.rad(179)))-2)<0.00001,'shortest positive arc')
check(math.abs(math.deg(M.angle(math.rad(179)-math.rad(-179)))+2)<0.00001,'shortest negative arc')
for _,fps in ipairs({30,60,144}) do
    local result=0 for _=1,fps do result=M.decay(result,10,0.12,1/fps) end
    check(math.abs(result-M.decay(0,10,0.12,1))<0.00001,'same decay in one second at '..fps)
end
-- Chase trajectory and force behavior is exercised by drivecam.mjs against
-- the active KirbyCam adaptation, replacing the previous slip-limit tests.
-- Exercise the actual ownership implementation with exported functions.
CameraTestExports={} exports=setmetatable({}, {__call=function(_,name,fn) CameraTestExports[name]=fn end})
-- camera.lua is loaded by the JS harness below, keeping its private state private.
print(total..' verificações de experiência e matemática aprovadas')
