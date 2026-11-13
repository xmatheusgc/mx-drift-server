-- One sampled controller action, independent of FPS and NUI focus changes.
ControllerNavigation={}
function ControllerNavigation.step(s,input,now)
    local x,y=input.x or 0,input.y or 0
    local neutral=not input.action and not input.left and not input.right and not input.up and not input.down and math.max(math.abs(x),math.abs(y))<.3
    if neutral then s.armed=true s.axis=nil s.key=nil return end
    if not s.armed then return end
    local key=input.action
    if not key then
        if input.left~=input.right and (input.left or input.right) then key=input.right and 'right' or 'left'
        elseif input.up~=input.down and (input.up or input.down) then key=input.down and 'down' or 'up'
        elseif s.axis then key=s.axis
        elseif math.max(math.abs(x),math.abs(y))>.6 then
            key=math.abs(x)>math.abs(y) and (x>0 and 'right' or 'left') or (y>0 and 'down' or 'up') s.axis=key
        end
        -- A held stick cannot oscillate between perpendicular directions.
        if s.axis and ((key=='left' and x>-.3) or (key=='right' and x<.3) or (key=='up' and y>-.3) or (key=='down' and y<.3)) then return end
    end
    if not key then return end
    if input.action then s.armed=false s.key=nil return key end
    local changed=s.key~=key
    if changed or now>=(s.next or 0) then
        s.key=key
        s.next=changed and now+350 or s.next+(math.floor((now-s.next)/140)+1)*140
        return key
    end
end

-- Keyboard-mapped frontend controls must not consume a controller edge.
function ControllerNavigation.sample(s,input,now,keyboard)
    if keyboard then return ControllerNavigation.step(s,{},now) end
    return ControllerNavigation.step(s,input,now)
end

-- Shared frontend navigation. Server action bindings never enter this registry.
InterfaceNavigation={controls={187,188,189,190,199,200,201,202,203,205,206}}
function InterfaceNavigation.read(gate,options)
    options=options or {}
    for _,control in ipairs(InterfaceNavigation.controls)do DisableControlAction(0,control,true)end
    local keyboard=IsInputDisabled(0)
    -- Text/caret editing belongs to CEF; it must not also navigate the screen.
    if keyboard and options.text then return ControllerNavigation.step(gate,{},GetGameTimer()) end
    local function down(control)return IsDisabledControlPressed(0,control)end
    local action=(down(200) or down(202) or options.pauseBack and down(199)) and 'back' or down(201) and 'enter'
        or options.character and down(203) and 'saveCharacter' or options.settings and down(203) and 'applySettings'
        or options.tabs and down(205) and 'tabPrev' or options.tabs and down(206) and 'tabNext'
    if not action and options.editor and not keyboard then
        action=down(75) and 'orbit' or down(203) and 'night' or down(230) and 'doors'
    end
    return ControllerNavigation.step(gate,{action=action,left=down(189),right=down(190),up=down(188),down=down(187),
        x=not keyboard and not options.freeCamera and GetDisabledControlNormal(0,218) or 0,
        y=not keyboard and not options.freeCamera and GetDisabledControlNormal(0,219) or 0},GetGameTimer())
end
