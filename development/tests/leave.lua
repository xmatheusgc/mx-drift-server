local T=PresentationTest
T.entities[10].id='preview'
WorkshopPresentation.start('exit',10,'preview',{x=5,y=6,z=1.08,h=300,groundZ=0})
assert(GetVehiclePedIsIn(1,false)==10,'real presentation driver seated before exit')
local response=T.handlers.fade()
assert(response.ready and GetVehiclePedIsIn(1,false)==0,'exit acknowledgement requires detached driver')
assert(not WorkshopPresentation.session and T.entities[1].visible,'presentation stopped and actor restored')
assert(T.entities[10] and not T.entities[10].engine,'driver leaves before server may remove vehicle')
print('4 verificações do handler real de saída da apresentação aprovadas; natives simuladas')
