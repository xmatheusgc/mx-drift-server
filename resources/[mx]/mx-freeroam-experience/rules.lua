ExperienceRules={}
function ExperienceRules.inEntry(point)
    local area=ExperienceConfig.entry
    return point.x>=area.min.x and point.x<=area.max.x and point.y>=area.min.y and point.y<=area.max.y and point.z>=area.min.z and point.z<=area.max.z
end
function ExperienceRules.phase(state,valid,hasCars)
    if not state.character_completed or state.character_completed==0 then return 'character' end
    if not state.vehicle_completed or state.vehicle_completed==0 then return 'firstCar' end
    return valid and 'workshop' or (hasCars and 'unavailable' or 'empty')
end
function ExperienceRules.uuid(id) return type(id)=='string' and #id==36 and id:match('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$')~=nil end
function ExperienceRules.appearance(a)
    MX.require(MX.keys(a,{version=true,model=true,shapeFirst=true,shapeSecond=true,skinFirst=true,skinSecond=true,shapeMix=true,skinMix=true,features=true,overlays=true,hairColor=true,hairHighlight=true,eyeColor=true,components=true,props=true}),'APPEARANCE')
    MX.require(a.version==1 and (a.model=='mp_m_freemode_01' or a.model=='mp_f_freemode_01'),'APPEARANCE')
    for _,k in ipairs({'shapeFirst','shapeSecond','skinFirst','skinSecond'}) do MX.require(MX.number(a[k],0,45,true),'APPEARANCE') end
    for _,k in ipairs({'shapeMix','skinMix'}) do MX.require(MX.number(a[k],0,1),'APPEARANCE') end
    MX.require(MX.number(a.hairColor,0,63,true) and MX.number(a.hairHighlight,0,63,true) and MX.number(a.eyeColor,0,31,true),'APPEARANCE')
    MX.require(type(a.features)=='table' and #a.features==20,'APPEARANCE')
    for _,v in ipairs(a.features) do MX.require(MX.number(v,-1,1),'APPEARANCE') end
    MX.require(type(a.overlays)=='table' and #a.overlays==13,'APPEARANCE')
    for _,v in ipairs(a.overlays) do
        MX.require(MX.keys(v,{index=true,opacity=true,color=true}) and MX.number(v.index,-1,54,true) and MX.number(v.opacity,0,1) and MX.number(v.color,0,63,true),'APPEARANCE')
    end
    for key,slots in pairs({components=12,props=8}) do
        MX.require(type(a[key])=='table' and #a[key]==slots,'APPEARANCE')
        for _,v in ipairs(a[key]) do MX.require(MX.keys(v,{drawable=true,texture=true}) and MX.number(v.drawable,key=='props' and -1 or 0,1000,true) and MX.number(v.texture,0,100,true),'APPEARANCE') end
    end
    return a
end
function ExperienceRules.preset(model,outfit)
    local a={version=1,model=model or 'mp_m_freemode_01',shapeFirst=0,shapeSecond=21,skinFirst=0,skinSecond=21,shapeMix=0.5,skinMix=0.5,features={},overlays={},hairColor=1,hairHighlight=1,eyeColor=0,components={},props={}}
    for i=1,20 do a.features[i]=0 end
    for i=1,13 do a.overlays[i]={index=-1,opacity=1,color=1} end
    for i=1,12 do a.components[i]={drawable=0,texture=0} end
    for i=1,8 do a.props[i]={drawable=-1,texture=0} end
    a.components[3].drawable=1
    local female=a.model=='mp_f_freemode_01'
    a.components[4].drawable=0; a.components[5].drawable=female and 0 or 10
    a.components[7].drawable=female and 1 or 10; a.components[9].drawable=female and 14 or 15
    a.components[12].drawable=female and 0 or 5
    if outfit==1 then a.components[5].drawable=1 a.components[12].drawable=female and 0 or 0 end
    return a
end
