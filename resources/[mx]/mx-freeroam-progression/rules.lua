ProgressionRules={}
function ProgressionRules.level(xp)
    local level=1 for i,value in ipairs(ProgressionConfig.levels) do if xp>=value then level=i end end return level
end
function ProgressionRules.icon(id,level)
    if id=='auto' then id=level>=4 and 'star' or level>=2 and 'flag' or 'driver' end
    local icon=ProgressionConfig.icons[id]
    return icon and level>=icon.minLevel and icon or nil
end
function ProgressionRules.rewardable(r)
    return (r.eligible==1 or r.eligible==true) and not (r.revoked==1 or r.revoked==true) and (r.mode=='timeattack' or r.mode=='duel')
end
function ProgressionRules.origin(r) return 'route:'..r.track_id..':'..r.track_revision..':'..r.direction end
