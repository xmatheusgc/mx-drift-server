DrivecamMath={}
function DrivecamMath.queryFresh(q,generation,vehicle,now,originError,targetError,travelAllowance)
    local allowance=travelAllowance or 0
    return q.generation==generation and q.vehicle==vehicle and now-q.at<150 and originError<1.5+allowance and targetError<2.0+allowance
end
function DrivecamMath.angle(x) return (x+math.pi)%(2*math.pi)-math.pi end
function DrivecamMath.clamp(x,a,b) return math.max(a,math.min(b,x)) end
function DrivecamMath.decay(current,target,half,dt) return target+(current-target)*2^(-dt/half) end
function DrivecamMath.angleDecay(current,target,half,dt) return current+DrivecamMath.angle(target-current)*(1-2^(-dt/half)) end
