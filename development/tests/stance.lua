local S,R,T=VehicleStance,VehicleStanceRules,StanceTest local n=0
local function check(v,m) assert(v,m) n=n+1 end
local function close(a,b) return math.abs(a-b)<.00001 end
local p=R.defaults() p.height=-.04 p.frontCamber=-6 p.rearCamber=-3 p.frontOffset=.04 p.rearOffset=.03 p.wheelSize=1.1 p.wheelWidth=1.2
check(R.validate(false)==false and R.validate(p)==p,'old documents and bounded stance supported')
for key,range in pairs(R.ranges) do local bad=MX.copy(p) bad[key]=range[2]+1 check(not pcall(R.validate,bad),'range rejected '..key) end
local bad=MX.copy(p) bad.owner=12 check(not pcall(R.validate,bad),'unknown fields rejected')
local original=VehicleProperties.validate(VehicleProperties.defaults()) local legacy=VehicleProperties.signature(original)
original.stance=p check(VehicleProperties.signature(original)~=legacy and legacy:find('native%-v2:'),'ranking signature includes visual wheel configuration; old signature preserved')
S.apply(7,'stance-a',p,true) local e=T.entities[7]
check(close(e.height,.05) and close(e.size,.66) and close(e.width,.30),'height direction and scale relative to native defaults')
check(close(e.offset[0],-.84) and close(e.offset[1],.84) and close(e.offset[2],-.85),'symmetric outward offsets per axle')
check(close(e.rotation[0],.02+math.rad(6)) and close(e.rotation[1],-.02-math.rad(6)),'camber mirrored left/right')
e.offset[0]=0 S.refresh(7) check(close(e.offset[0],-.84),'per-frame refresh reapplies native wheel offset')
e.size=.6 e.width=.25 S.refresh(7) check(close(e.size,.66) and close(e.width,.30),'repair/tuning reset recovers intended wheel scale')
e.family=12 S.apply(7,'stance-a',p,true) check(close(e.height,.05) and close(e.offset[0],-.84),'wheel-family change cannot compound baseline')
T.handlers.mxStance('bag',nil,{id='stance-a',value=false}) check(S.current(7)~=false,'late old server state cannot override pending local authoritative apply')
T.handlers.mxStance('bag',nil,{id='stance-a',value=p}) T.handlers.mxStance('bag',nil,{id='stance-a',value=false})
check(not S.current(7) and close(e.offset[0],-.8) and close(e.rotation[0],.02) and close(e.size,.6) and close(e.height,.01),'accepted reset restores actual model baseline')
e.mod=-1 check(not pcall(S.check,7,p),'size/width unavailable with stock wheels') e.mod=2
e.wheels=6 check(not S.supported(7) and not pcall(S.check,7,p),'unsupported axle layout rejected') e.wheels=4
check(not pcall(S.apply,7,'unrelated',p),'identity must match managed entity')
T.failWidth=true local size=e.size check(not pcall(S.apply,7,'stance-a',p) and close(e.size,size),'native scale failure rolls back and does not report success') T.failWidth=false
S.apply(7,'stance-a',p,true) e.id='unmanaged' local before=e.offset[0] S.restore(7) check(e.offset[0]==before,'reused handle is not reset')
e.id='stance-a' T.events.onClientResourceStop('mx-freeroam-vehicles') check(close(e.size,.6) and close(e.height,.01),'resource stop restores local baseline')
local neutral=R.defaults() neutral.height=-.005 neutral.frontCamber=3 neutral.rearCamber=3 neutral.frontOffset=.04 neutral.rearOffset=.065
T.entities[8]=MX.copy(e) T.entities[8].id='neutral-elegy' T.entities[8].model='elegy' T.entities[8].mod=15
local sizeCalls,widthCalls=T.sizeCalls or 0,T.widthCalls or 0
T.failSize=true T.failWidth=true
check(pcall(S.apply,8,'neutral-elegy',neutral,true),'saved neutral wheel dimensions cannot block Elegy height/camber when resizing natives reject')
check((T.sizeCalls or 0)==sizeCalls and (T.widthCalls or 0)==widthCalls,'neutral application never calls resizing setters')
check(close(T.entities[8].height,.015) and close(T.entities[8].offset[0],-.84),'height and offset still applied with native wheel dimensions')
S.refresh(8) S.restore(8)
check((T.sizeCalls or 0)==sizeCalls and (T.widthCalls or 0)==widthCalls,'neutral refresh and restoration do not introduce unsupported resizing')
local widthOnly=MX.copy(neutral) widthOnly.wheelWidth=1.2
check(not pcall(S.apply,8,'neutral-elegy',widthOnly,true),'actual unsupported custom width remains an error')
check((T.sizeCalls or 0)==sizeCalls,'custom width does not require changing neutral size')
T.failSize=false T.failWidth=false
S.apply(8,'neutral-elegy',widthOnly,true)
check(close(T.entities[8].width,.30),'supported custom width is applied')
S.apply(8,'neutral-elegy',neutral,true)
check(close(T.entities[8].width,.25),'return from custom width to neutral restores original width')
local limited=MX.copy(p) limited.wheelWidth=1.15
T.entities[9]=MX.copy(e) local car=T.entities[9] car.id='limited' car.model='sc300a' car.mod=3 car.size=.6 car.width=.25
T.failSize=true
local ack=S.ensure(9,'limited',limited,true)
check(ack.value.wheelSize==1 and close(ack.value.wheelWidth,1.15) and ack.warning,'diameter refusal preserves accepted width and other stance fields')
check(S.options(9).unavailable.wheelSize and not S.options(9).unavailable.wheelWidth,'capabilities isolate the rejected dimension')
check(close(car.height,.05) and close(car.offset[0],-.84),'optional wheel failure does not block height/camber/offset')
local calls=T.sizeCalls S.ensure(9,'limited',limited,true) S.refresh(9)
check(T.sizeCalls==calls,'known unsupported resizing is not retried on every application/frame')
local requested=VehicleProperties.defaults() requested.stance=limited
local accepted=VehicleProperties.acceptStance(requested,{stance=ack})
check(accepted.stance.wheelSize==1 and requested.stance.wheelSize==1.1,'only observed stance is acknowledged, without mutating the request')
check(not pcall(VehicleProperties.acceptStance,requested,{stance={}}),'malformed stance ACK cannot silently erase a requested stance')
car.mod=4 T.failSize=false
check(S.ensure(9,'limited',limited,true).value.wheelSize==1.1 and not S.options(9).unavailable.wheelSize,'changing wheels permits a fresh capability check')
T.failSize=true T.failWidth=true limited.wheelSize=1.2 limited.wheelWidth=1.3
ack=S.ensure(9,'limited',limited,true)
check(close(ack.value.wheelSize,1.1) and close(ack.value.wheelWidth,1.15),'refused size and width restore the actual preceding dimensions')
check(not pcall(S.ensure,9,'forged',limited,true),'recovery does not bypass entity identity')
local invalid=MX.copy(limited) invalid.height=10
check(not pcall(S.ensure,9,'limited',invalid,true),'invalid payloads remain rejected')
T.failSize=false T.failWidth=false
-- GetVehicleWheelSize/Width may return zero for original wheels. A visual
-- height edit must not pin that zero as the future tuning-wheel baseline.
T.entities[10]=MX.copy(e) local stock=T.entities[10]
stock.id='stock-to-tuning' stock.mod=-1 stock.size=0 stock.width=0
local zeroSize,zeroWidth=T.zeroSizeCalls or 0,T.zeroWidthCalls or 0
S.ensure(10,stock.id,neutral,true)
stock.mod=5 stock.size=.64 stock.width=.24
local changed=S.ensure(10,stock.id,p,true)
check(close(stock.size,.704) and close(stock.width,.288),'stock zero baseline is initialized from the first valid modified wheel geometry')
check(changed.value.wheelSize==1.1 and changed.value.wheelWidth==1.2 and not changed.warning,'stock-to-tuning transition does not falsely disable diameter or width')
check((T.zeroSizeCalls or 0)==zeroSize and (T.zeroWidthCalls or 0)==zeroWidth,'stock zero baseline is never submitted as a resize target after installing tuning wheels')
S.ensure(10,stock.id,p,true)
check(close(stock.size,.704) and close(stock.width,.288),'lazy tuning baseline does not compound on repeated application')
S.ensure(10,stock.id,neutral,true)
check(close(stock.size,.64) and close(stock.width,.24),'neutral restores valid tuning dimensions instead of the earlier stock zero reading')
-- Reproduce the owner's actual values with native BOOL exposed as Lua integer.
T.entities[11]=MX.copy(e) local reported=T.entities[11]
reported.id='native-one' reported.mod=58 reported.size=.62013345956802 reported.width=.44171878695488
T.nativeResult=1
local resized=MX.copy(neutral)resized.wheelSize=1.01 resized.wheelWidth=1.02
local confirmed=S.ensure(11,reported.id,resized,true)
check(not confirmed.warning and confirmed.value.wheelSize==1.01 and confirmed.value.wheelWidth==1.02,'native BOOL 1 is success for both dimensions, as reported in F8')
check(close(reported.size,.6263347864151) and close(reported.width,.45055314898491),'observed float32-sized differences remain within native readback tolerance')
T.ignoreSize=true resized.wheelSize=1.1
confirmed=S.ensure(11,reported.id,resized,true)
check(confirmed.warning and close(confirmed.value.wheelSize,1.01),'success return without matching geometry still fails safely')
T.ignoreSize=false T.nativeResult=nil
print(n..' verificações de stance (validação real + controlador com natives simuladas; sem jogo)')
