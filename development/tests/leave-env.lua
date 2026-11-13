function GetResourceKvpInt() return 0 end
WorkshopCameraDev={stop=function()end,start=function()end} -- Authoring controller has a dedicated native-adapter suite.
WorkshopDisplay={stop=function()end,start=function()end,tick=function()end,preview=function()end}
function RegisterCommand() end
function RegisterKeyMapping() end
function DoScreenFadeOut() end
function IsPedInAnyVehicle() return (PresentationTest.vehicle or 0)~=0 end
MX.clients=function(domain,handlers) PresentationTest.handlers=handlers end
