local subjects={}
for i=1,20 do subjects[i]={source=i,bucket=i<=10 and 0 or 1,group=i%3==0 and 'a' or nil,share=i%5~=0} end
local sent,comparisons=0,0
for tick=1,600 do
    for i=1,20 do
        local observer={source=i,bucket=subjects[i].bucket,group=subjects[i].group,blips=i%4==0 and 'group' or 'all'}
        for _,subject in ipairs(subjects) do
            comparisons=comparisons+1
            if SocialRules.visible(observer,subject) then
                assert(subject.source~=observer.source and subject.share and subject.bucket==observer.bucket)
                sent=sent+1
            end
        end
    end
end
print('Simulação: '..comparisons..' decisões de filtro, '..sent..' presenças elegíveis; nenhum pacote enviado')
