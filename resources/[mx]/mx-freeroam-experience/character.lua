Character={}
local applied,pedApplied=nil,nil
-- Model bounds are independent of idle animation and breathing.
function Character.anchors()
    local ped=PlayerPedId() local low,high=GetModelDimensions(GetEntityModel(ped))
    local right,top,bottom,count=0,1,0,0
    for _,x in ipairs({low.x,high.x}) do for _,y in ipairs({low.y,high.y}) do for _,z in ipairs({low.z,high.z}) do
        local point=GetOffsetFromEntityInWorldCoords(ped,x,y,z)
        local visible,sx,sy=GetScreenCoordFromWorldCoord(point.x,point.y,point.z)
        if visible then right=math.max(right,sx) top=math.min(top,sy) bottom=math.max(bottom,sy) count=count+1 end
    end end end
    local anchors={}
    for name,fraction in pairs({head=.1,torso=.38,legs=.68,feet=.94}) do anchors[name]={visible=count==8,x=right+.025,y=top+(bottom-top)*fraction} end
    return anchors
end
function Character.capabilities()
    local ped=PlayerPedId() local c={components={},props={},overlays={}}
    for i=0,11 do local drawable=GetPedDrawableVariation(ped,i) c.components[i+1]={count=GetNumberOfPedDrawableVariations(ped,i),textures=GetNumberOfPedTextureVariations(ped,i,drawable)} end
    for i=0,7 do local drawable=GetPedPropIndex(ped,i) c.props[i+1]={count=GetNumberOfPedPropDrawableVariations(ped,i),textures=drawable>=0 and GetNumberOfPedPropTextureVariations(ped,i,drawable) or 0} end
    for i=0,12 do c.overlays[i+1]=GetPedHeadOverlayNum(i) end return c
end
function Character.apply(a,force)
    ExperienceRules.appearance(a)
    local hash=joaat(a.model)
    local changed=GetEntityModel(PlayerPedId())~=hash
    if changed then
        RequestModel(hash) local deadline=GetGameTimer()+ExperienceConfig.timeout
        while not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(30) end
        MX.require(HasModelLoaded(hash),'MODEL','Personagem indisponível')
        SetPlayerModel(PlayerId(),hash) SetModelAsNoLongerNeeded(hash)
    end
    local ped=PlayerPedId()
    local previous=not force and not changed and pedApplied==ped and applied and applied.model==a.model and applied or nil
    local function differs(key,index)
        if not previous then return true end
        local x,y=a[key],previous[key]
        if index then x,y=x[index],y[index] end
        if type(x)~='table' then return x~=y end
        for k,v in pairs(x) do if v~=y[k] then return true end end return false
    end
    -- Validate complete draft first; do not half-apply an unsupported outfit.
    for i,v in ipairs(a.components) do
        MX.require(v.drawable<GetNumberOfPedDrawableVariations(ped,i-1) and v.texture<GetNumberOfPedTextureVariations(ped,i-1,v.drawable),'CLOTHES','Peça indisponível para este personagem')
    end
    for i,v in ipairs(a.props) do if v.drawable>=0 then MX.require(v.drawable<GetNumberOfPedPropDrawableVariations(ped,i-1) and v.texture<GetNumberOfPedPropTextureVariations(ped,i-1,v.drawable),'CLOTHES','Acessório indisponível') end end
    for i,v in ipairs(a.overlays) do MX.require(v.index<GetPedHeadOverlayNum(i-1),'APPEARANCE','Opção facial indisponível') end
    if differs('shapeFirst') or differs('shapeSecond') or differs('skinFirst') or differs('skinSecond') or differs('shapeMix') or differs('skinMix') then SetPedHeadBlendData(ped,a.shapeFirst,a.shapeSecond,0,a.skinFirst,a.skinSecond,0,a.shapeMix,a.skinMix,0.0,false) end
    for i,v in ipairs(a.features) do if differs('features',i) then SetPedFaceFeature(ped,i-1,v+0.0) end end
    for i,v in ipairs(a.overlays) do
        if differs('overlays',i) then
            SetPedHeadOverlay(ped,i-1,v.index<0 and 255 or v.index,v.opacity+0.0)
            SetPedHeadOverlayColor(ped,i-1,(i==5 or i==6 or i==9) and 2 or 1,v.color,v.color)
        end
    end
    for i,v in ipairs(a.components) do if differs('components',i) then SetPedComponentVariation(ped,i-1,v.drawable,v.texture,0) end end
    for i,v in ipairs(a.props) do if differs('props',i) then if v.drawable<0 then ClearPedProp(ped,i-1) else SetPedPropIndex(ped,i-1,v.drawable,v.texture,true) end end end
    if differs('hairColor') or differs('hairHighlight') or differs('components',3) then SetPedHairColor(ped,a.hairColor,a.hairHighlight) end
    if differs('eyeColor') then SetPedEyeColor(ped,a.eyeColor) end
    applied=MX.copy(a) pedApplied=ped
    return Character.capabilities(),changed
end

