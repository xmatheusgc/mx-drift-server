local T=TrainerMenuTest
local poll=T.threads[2]
function GetVehiclePedIsIn()return 0 end
T.nui('close')
T.workshop=false
local key,pad=false,false
MenuBindings={list=function()return {{id='engine'}}end,input=function()return key or pad end,keyInput=function()return key end,padInput=function()return pad end}
local function step(ms)T.time=T.time+ms;T.tick(poll)end
local function lastCommand()T.tick(T.threads[#T.threads])end
step(500)
local before=#T.requests
pad=true step(0)step(699)
assert(#T.requests==before,'short pad press cannot toggle engine')
step(1)lastCommand()
assert(#T.requests==before+1 and T.requests[#T.requests].data.kind=='engine','700ms pad hold uses authorized vehicle service')
step(1500)assert(#T.requests==before+1,'long hold fires once')
pad=false step(0)
key=true step(500)lastCommand()
assert(#T.requests==before+2,'keyboard engine acts immediately')
key=false step(0)
pad=true step(100)
T.commands.mxmenu()step(500)T.nui('close')step(1000)
assert(#T.requests==before+2,'holding engine across menu cannot fire')
pad=false step(1)
local vehicle=77
function GetVehiclePedIsIn()return vehicle end
T.disabled={}VehicleInput.block()
for _,id in ipairs({81,82,83,84,85,332,333,37,99,100})do assert(T.disabled[id],'blocked radio/weapon control '..id)end
assert(not T.disabled[71] and not T.disabled[72] and not T.disabled[59] and not T.disabled[0],'driving and camera preserved')
vehicle=0 T.disabled={}VehicleInput.block()assert(not next(T.disabled),'no vehicle-specific block on foot')
print('Vehicle input: engine hold/keyboard/one-shot/menu isolation and in-vehicle radio/weapon blocks passed.')
T.commands.mxmenu()
local raw=nil
function IsRawKeyDown(k)return raw==k end
function IsControlPressed()return false end
function IsDisabledControlPressed()return false end
MenuBindings.candidates=function(kind)return kind=='key' and {LEFT=37,G=71} or {A=201,LEFT=189}end
local reply
T.callbacks.captureBinding({kind='key'},function(r)reply=r end)
local capture=T.threads[#T.threads]
T.tick(capture)T.time=T.time+101 T.tick(capture)
raw=37 T.tick(capture)
assert(not reply,'capture waits for selected button release')
raw=nil T.tick(capture)
assert(reply.ok and reply.data.value=='LEFT' and T.focused,'actual capture callback restores focused menu')
T.callbacks.captureBinding({kind='pad'},function(r)reply=r end)
capture=T.threads[#T.threads]T.tick(capture)
T.nui('cancelBindingCapture')T.tick(capture)
assert(reply.ok and reply.data.cancelled and T.focused,'mouse/ESC cancel leaves menu open')
print('Actual binding capture callback: physical key sampling, release swallowing, focus restoration and cancellation passed.')
