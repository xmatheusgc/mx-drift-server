CycleTest={oldConfig=WorldConfig,oldThread=CreateThread,oldWait=Wait,oldTimer=GetGameTimer,oldGlobal=GlobalState,time=0}
function CreateThread(fn)CycleTest.thread=coroutine.create(fn)end
function Wait()coroutine.yield()end
function GetGameTimer()return CycleTest.time end
GlobalState={}
