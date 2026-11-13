-- Capture physical input without interpreting it as interface navigation.
BindingCapture={}
local C=BindingCapture
function C.new(kind,now)
    return {kind=kind,deadline=now+15000}
end
function C.read(state,now,keys,pads)
    if now>=state.deadline or keys.ESC then return {cancelled=true} end
    local any=next(keys)~=nil or next(pads)~=nil
    if not state.armed then
        if any then state.neutral=nil
        elseif not state.neutral then state.neutral=now
        elseif now-state.neutral>=100 then state.armed=true end
        return nil
    end
    local down=state.kind=='key' and keys or pads
    local value,count=nil,0
    for name in pairs(down) do value=name count=count+1 end
    if count==1 then return {cancelled=false,value=value} end
    -- Chords are ambiguous: require release before choosing again.
    if count>1 then state.armed=false state.neutral=nil end
end
function C.sample()
    local keys,pads={},{}
    for name,key in pairs(MenuBindings.candidates('key')) do if IsRawKeyDown(key) then keys[name]=true end end
    if IsRawKeyDown(160) or IsRawKeyDown(161) then keys.SHIFT=true end
    if IsRawKeyDown(27) then keys.ESC=true end
    if IsRawKeyDown(119) then keys.F8=true end -- Reserved, reported to the validator.
    if not IsInputDisabled(0) then
        for name,control in pairs(MenuBindings.candidates('pad')) do
            if IsControlPressed(0,control) or IsDisabledControlPressed(0,control) then pads[name]=true end
        end
        if IsControlPressed(0,85) or IsDisabledControlPressed(0,85) then pads.LEFT=true end
        if pads.LEFT then pads.VIEW=nil end
    end
    return keys,pads
end
