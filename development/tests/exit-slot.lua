local exit=ExitSlotTest.exports.ReservePresentationExit
local point={x=163.2,y=-3024.11,z=6.05,h=268.29}
for _,src in ipairs({1,2,1})do
 local result=exit(src,point)
 assert(result.ghost and result.point.x==point.x and result.point~=point,'simultaneous/occupied exits are independent and request ghost protection')
end
assert(not pcall(exit,1,{x=1/0,y=0,z=0,h=0}),'arbitrary invalid coordinates remain rejected')
print('Workshop exit slots: no occupancy lookup/reservation contention, copied server destination and coordinate validation passed (adapters).')
