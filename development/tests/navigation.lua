local N=ControllerNavigation
local gate={}
assert(not N.step(gate,{right=true},0),'held input cannot enter a new context')
N.step(gate,{},10)
assert(N.step(gate,{right=true},20)=='right')
assert(not N.step(gate,{right=true},100))
assert(N.step(gate,{right=true},370)=='right')
assert(not N.step(gate,{right=true},380))
assert(N.step(gate,{right=true},510)=='right')
N.step(gate,{},520)
assert(N.step(gate,{left=true},530)=='left')
N.step(gate,{},540)
assert(N.step(gate,{action='enter'},550)=='enter')
assert(not N.step(gate,{action='enter'},900),'confirmation held across screen boundary is ignored')
N.step(gate,{},1000)
assert(not N.step(gate,{x=.15,y=-.1},1100),'stick drift stays neutral')
assert(N.step(gate,{x=.8,y=.1},1200)=='right')
assert(not N.step(gate,{x=.55,y=.7},1210),'diagonal cannot produce perpendicular bounce')
assert(not N.step(gate,{x=-.7},1250),'opposite stick requires return to centre')
N.step(gate,{},1300)
assert(N.step(gate,{x=-.8},1310)=='left')
local function repeated(dt)
 local g={} N.step(g,{},-1) local count=0
 for time=0,1980,dt do if N.step(g,{right=true},time) then count=count+1 end end
 return count
end
assert(repeated(1)==repeated(16) and repeated(16)==repeated(33),'repeat schedule independent of FPS')
N.step(gate,{},1400)
assert(not N.step(gate,{left=true,right=true},1410),'opposite directions cannot both fire')
print('16 controller gate checks passed: edge, delay, repeats, centre, noise, diagonal, boundary, FPS.')
local switching={}
assert(not N.sample(switching,{action='enter'},1500,true),'keyboard mapping cannot consume controller acceptance')
assert(N.sample(switching,{action='enter'},1516,false)=='enter','first controller press after keyboard is delivered')
assert(not N.sample(switching,{action='enter'},1532,false),'held controller confirm remains blocked')
N.sample(switching,{right=true},1548,true)
assert(N.sample(switching,{right=true},1564,false)=='right','switching back from keyboard preserves directional edge')
print('4 keyboard/controller switching assertions passed; input mode is simulated.')
