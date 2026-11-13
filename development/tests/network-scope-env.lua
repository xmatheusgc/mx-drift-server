NetworkScopeTest={visible=false,conversions=0,exists=true,id='owned',vehicle=true}
local T=NetworkScopeTest
function NetworkDoesEntityExistWithNetworkId() return T.visible end
function NetToVeh() T.conversions=T.conversions+1 return 10 end
function DoesEntityExist() return T.exists end
function IsEntityAVehicle() return T.vehicle end
function Entity() return {state={mxVehicle=T.id}} end
