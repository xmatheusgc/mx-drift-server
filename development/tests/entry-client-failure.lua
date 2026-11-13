local T=EntryClientFailureTest
assert(not T.exports.OpenGarage().ok,'entry failure is propagated')
assert(T.control and not T.frozen,'a failed request must not call pause() and freeze the player again')
assert(T.exports.RecoverEntry().recovered and T.control and not T.frozen,'recovery is safe and idempotent when no scene was entered')
print('Actual OpenGarage regression: failed request preserves movement instead of re-pausing; repeated recovery is safe (native adapters).')
function GetVehiclePedIsIn()return 0 end
exports['mx-freeroam-world']={SetLobbyTime=function()end}
T.exports.ShowLobby()
assert(not T.control and T.frozen,'initial failed lobby must retain its protected player')
local held=T.exports.RecoverEntry()
assert(held.held and not held.recovered and not T.control and T.frozen,'initial recovery cannot release an unprepared player into the world')
T.handlers.finish()
assert(T.control and not T.frozen,'a completed departure releases the initial protection')
print('Initial lobby failure/recovery keeps the ped frozen and controls blocked until departure; native adapters only.')
