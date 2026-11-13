-- State of one private presentation. No entity/natives are abstracted here.
PreviewState={}
function PreviewState.new(token,epoch,bucket) return {token=token,epoch=epoch,bucket=bucket,generation=0,alive=true,entities={}} end
function PreviewState.intent(s,id) s.generation=s.generation+1 s.intent=id return s.generation end
function PreviewState.valid(s,generation,token,epoch,bucket)
    return s.alive and s.generation==generation and s.token==token and s.epoch==epoch and s.bucket==bucket
end
function PreviewState.cancel(s) s.alive=false s.generation=s.generation+1 s.current=nil end
