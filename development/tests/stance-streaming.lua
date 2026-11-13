-- Cold render dimensions and observer state bags must recover without opening UI.
local S,R,T=VehicleStance,VehicleStanceRules,StanceTest
local oldSize,oldWidth,oldBag=SetVehicleWheelSize,SetVehicleWheelWidth,GetEntityFromStateBagName
function SetVehicleWheelSize(v,size)
    local ok=oldSize(v,size)if ok==true or ok==1 then T.entities[v].renderSize=size end return ok
end
function SetVehicleWheelWidth(v,width)
    local ok=oldWidth(v,width)if ok==true or ok==1 then T.entities[v].renderWidth=width end return ok
end
local function car(index)
    local e=MX.copy(T.entities[7])e.id='streaming:'..index e.model='streaming-model:'..index
    e.mod=58 e.size=0 e.width=0 e.renderSize=.6 e.renderWidth=.25 T.entities[index]=e return e
end
local wanted=R.defaults()wanted.wheelSize=1.1 wanted.wheelWidth=1.2
local oldTimer,oldWait=GetGameTimer,Wait
local time=0
GetGameTimer=function()return time end
local warm=car(20)
Wait=function()time=time+16 if time>=48 then warm.size=.6 warm.width=.25 end end
assert(S.awaitReady(20,warm.id,wanted,750) and time==48,'owner spawn waits briefly for initial render dimensions')
S.ensure(20,warm.id,wanted,true)
assert(math.abs(warm.renderSize-.66)<.00001,'ready owner dimensions applied before spawn ACK')
local unavailable=car(24)local started=time
Wait=function()time=time+16 end
assert(not S.awaitReady(24,unavailable.id,wanted,64) and time-started==64,'unready wheels have bounded wait and remain eligible for frame recovery')
local replaced=car(25)local originalId=replaced.id
Wait=function()time=time+16 replaced.id='replaced-during-wait'end
assert(not pcall(S.awaitReady,25,originalId,wanted,750),'wait cannot apply to a replaced entity')
GetGameTimer,Wait=oldTimer,oldWait
local e=car(21)
S.ensure(21,e.id,wanted,true)
local zeroSize,zeroWidth=T.zeroSizeCalls or 0,T.zeroWidthCalls or 0
e.size=.6 e.width=.25
S.refresh(21)
assert(math.abs(e.renderSize-.66)<.00001 and math.abs(e.renderWidth-.3)<.00001,'cold owner spawn picks up late native dimensions without another apply or editor')
for _=1,60 do S.refresh(21)end
assert(math.abs(e.size-.66)<.00001 and wanted.wheelSize==1.1,'late initialization never compounds or edits the saved factor')

local observer=car(22)
GetEntityFromStateBagName=function()return 22 end
T.handlers.mxStance('entity:22',nil,{id=observer.id,value=wanted})
observer.size=.64 observer.width=.24
S.refresh(22)
assert(math.abs(observer.renderSize-.704)<.00001 and math.abs(observer.renderWidth-.288)<.00001,'observer stream-in restores saved dimensions from the replicated intent')
observer.renderSize=.64 observer.renderWidth=.24
T.handlers.mxStance('entity:22',nil,{id=observer.id,value=wanted})
assert(math.abs(observer.renderSize-.704)<.00001,'same-signature bag update still repairs a rebuilt mesh')
observer.renderSize=.64 S.refresh(22)
assert(math.abs(observer.renderSize-.704)<.00001,'frame refresh repairs a post-ground-placement/departure visual reset')

local delayed=car(23)delayed.mod=-1
GetEntityFromStateBagName=function()return 23 end
T.handlers.mxStance('entity:23',nil,{id=delayed.id,value=wanted})
delayed.mod=58 delayed.size=.6 delayed.width=.25
T.handlers.mxStance('entity:23',nil,{id=delayed.id,value=wanted})
assert(math.abs(delayed.renderSize-.66)<.00001,'state before wheel mods is reconciled when the mods stream in')
assert((T.zeroSizeCalls or 0)==zeroSize and (T.zeroWidthCalls or 0)==zeroWidth,'unready dimensions are never submitted as zero resize targets')
local calls=T.sizeCalls observer.id='reused-streamed-handle' S.refresh(22)
assert(T.sizeCalls==calls,'late refresh respects replaced entity identity')
SetVehicleWheelSize,SetVehicleWheelWidth,GetEntityFromStateBagName=oldSize,oldWidth,oldBag
print('Stance streaming: delayed zero dimensions, owner spawn, observer state bags, mods arriving late, mesh rebuild/departure, no compounding and identity guards passed (native adapters).')
