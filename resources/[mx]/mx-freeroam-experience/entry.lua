local busy=false local shown=nil
local function prompt(visible,keyboard)
    local key=visible and (keyboard and 'keyboard' or 'gamepad') or 'hidden'
    if key==shown then return end shown=key
    TriggerEvent('mx:experience:entryPrompt',{visible=visible,device=keyboard and 'keyboard' or 'gamepad',style=ExperienceConfig.controllerIcons})
end
CreateThread(function()
    while true do
        local ped=PlayerPedId()
        local inside=ExperienceRules.inEntry(GetEntityCoords(ped))
        local eligible=inside and not busy and not exports['mx-freeroam-experience']:InWorkshop() and not exports['mx-freeroam-experience']:InLobby() and not IsNuiFocused() and not IsPauseMenuActive() and not IsEntityDead(ped)
        prompt(eligible,IsInputDisabled(0))
        if eligible then
            DisableControlAction(0,51,true) -- INPUT_CONTEXT: E / D-pad right.
            if IsDisabledControlJustPressed(0,51) then
                busy=true prompt(false,IsInputDisabled(0))
                CreateThread(function()
                    local ok,result=pcall(function()return exports['mx-freeroam-experience']:EnterNearbyWorkshop()end)
                    if not ok or not result.ok then TriggerEvent('mx:notice',ok and result.message or 'Não foi possível entrar na oficina; tente novamente') end
                    busy=false
                end)
            end
        end
        Wait(inside and 0 or 250)
    end
end)
AddEventHandler('onClientResourceStop',function(resource) if resource==GetCurrentResourceName() then prompt(false,true) end end)
