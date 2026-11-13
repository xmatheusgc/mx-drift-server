-- Small local ownership contract. A stale token cannot release a newer owner.
local owner,sequence=nil,0
local suspended={}
exports('AcquireView',function(name)
    if owner and owner.name~=name and not (name=='workshop' and owner.name=='drivecam') then return nil end
    sequence=sequence+1 owner={name=name,token=sequence} return sequence
end)
exports('OwnsView',function(token) return owner and owner.token==token or false end)
exports('ReleaseView',function(token) if owner and owner.token==token then owner=nil return true end return false end)
exports('SuspendDrivecam',function(reason,value) suspended[reason]=value and true or nil end)
exports('DrivecamSuspended',function() return next(suspended)~=nil or (owner and owner.name~='drivecam') or false end)
exports('CurrentView',function() return owner and owner.name end)
