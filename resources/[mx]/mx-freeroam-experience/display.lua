WorkshopDisplay={session=nil,override=nil}
local D=WorkshopDisplay
local function maximum()
    local cfg=ExperienceConfig.display
    return cfg.enabled and math.min(7,#cfg.points,D.override or cfg.maxVehicles)or 0
end
local function valid(s)return D.session==s and s.alive and D.hooks and D.hooks.valid(s.token)and maximum()>0 end
local function clear()
    if GetResourceState('mx-freeroam-vehicles')=='started'then
        local ok,err=pcall(function()exports['mx-freeroam-vehicles']:ClearWorkshopDisplay()end)
        if not ok then print('[MX:DISPLAY] '..tostring(err))end
    end
end
function D.stop()
    if D.session then D.session.alive=false D.session=nil end
    clear()
end
local function sync(s)
    if not valid(s) or not s.rows then return end
    local rows={}
    for slot=1,maximum()do
        local row=s.rows[slot]
        if row then local item=MX.copy(row)item.slot=slot rows[#rows+1]=item end
    end
    local cfg=MX.copy(ExperienceConfig.display)cfg.maxVehicles=maximum()
    local ok,err=pcall(function()exports['mx-freeroam-vehicles']:SyncWorkshopDisplay(s.token,rows,cfg)end)
    if not ok then print('[MX:DISPLAY] '..tostring(err))end
end
function D.preview(row,current)
    local s=D.session if not s or not valid(s)then return end
    local previous=s.main
    s.main=row and MX.copy(row)or nil s.version=(s.version or 0)+1
    s.anchor=current and current.id and MX.copy(current)or nil
    if not s.rows or not row or not ExperienceConfig.display.excludeCurrent then return end
    local slot,seen
    for i,item in pairs(s.rows)do if item.id==row.id then slot=i end end
    if not slot then return end
    local replacement=previous or s.anchor
    if replacement and replacement.id~=row.id then
        for i,item in pairs(s.rows)do if i~=slot and item.id==replacement.id then seen=true break end end
    else seen=true end
    s.rows[slot]=not seen and replacement and MX.copy(replacement)or nil
    sync(s)
end
local function receive(s,data,version)
    if (s.version or 0)~=version then s.dirty=true return end -- A newer preview owns the layout.
    D.preview(data.current,data.selected)
    local excluded=ExperienceConfig.display.excludeCurrent and s.main and s.main.id
    local candidates,byId={},{}
    for _,row in ipairs(data.vehicles or {})do
        if row.id~=excluded and not byId[row.id]then byId[row.id]=row candidates[#candidates+1]=row end
    end
    local rows,used={},{}
    for slot,row in pairs(s.rows or {})do
        if slot<=maximum() and byId[row.id]then rows[slot]=MX.copy(byId[row.id])used[row.id]=true end
    end
    for _,row in ipairs(candidates)do if not used[row.id]then
        for slot=1,maximum()do if not rows[slot]then rows[slot]=MX.copy(row)used[row.id]=true break end end
    end end
    s.rows=rows sync(s)
end
function D.refresh()
    local s=D.session if not s or not valid(s)then return end
    s.dirty=true if s.worker then return end s.worker=true
    CreateThread(function()
        Wait(s.initial and ExperienceConfig.display.startDelay or 250) s.initial=false
        local retries=0
        while s.dirty and valid(s)do
            s.dirty=false
            local version=s.version or 0
            local ok,r=pcall(MX.request,'experience','displayVehicles',{token=s.token})
            if not valid(s)then break end
            if ok and r.ok then
                receive(s,r.data,version)
            elseif ok and r.code=='BUSY' and retries<2 then retries=retries+1 s.dirty=true Wait(500)
            else print('[MX:DISPLAY] '..tostring(ok and (r.code or 'UNAVAILABLE')or r))end
        end
        s.worker=false
    end)
end
function D.start(value)
    if maximum()<1 then D.stop()return end
    if D.session and D.session.token==value and valid(D.session)then return end
    D.stop()D.session={token=value,alive=true,initial=true}D.refresh()
end
function D.tick()
    local s=D.session
    if s and valid(s)then
        local scale=ExperienceConfig.display.worldLodScale
        if MX.number(scale,.25,1)then OverrideLodscaleThisFrame(scale+0.0)end
    end
end
RegisterNetEvent('mx:experience:displayChanged',function(value)
    if source==65535 and D.session and value==D.session.token then D.refresh()end
end)
RegisterCommand('mxdisplay',function(_,args)
    local count=tonumber(args[1])
    if not MX.number(count,0,7,true)then TriggerEvent('mx:notice','Use mxdisplay 0 a 7 para limitar os carros de cenário.')return end
    D.override=count D.stop()
    if D.hooks and D.hooks.valid(D.hooks.token())then D.start(D.hooks.token())end
end,false)
RegisterCommand('mxdisplayinfo',function()
    if GetResourceState('mx-freeroam-vehicles')=='started'then print('[MX:DISPLAY] '..json.encode(exports['mx-freeroam-vehicles']:WorkshopDisplayStats()))end
end,false)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName()or name=='mx-freeroam-vehicles'or name=='mx-freeroam-menu'then D.stop()end
end)
