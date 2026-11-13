RegisterCommand('mxtestexperience',function(src)
    if src~=0 then return end
    CreateThread(function()
        local results={} local player
        local function yes(x) return x==true or x==1 end
        local function no(x) return x==false or x==0 end
        local function q(sql,args) return exports['mx-freeroam-core']:Query(sql,args or {}) end
        local function check(value,name) assert(value,name) results[#results+1]={name=name,ok=true} print('[MX EXPERIENCE PASS] '..name) end
        local ok,err=pcall(function()
            assert(q('SELECT DATABASE() name')[1].name:match('^mx_freeroam_test'),'Banco não isolado: recusado')
            local identity='experience:'..q('SELECT UUID() id')[1].id
            q('INSERT INTO players(identifier,name) VALUES (?,?)',{identity,'Verificação experiência'})
            player=q('SELECT id FROM players WHERE identifier=?',{identity})[1].id
            q('INSERT INTO player_experience(player_id) VALUES (?)',{player})
            local actor={id=player} local operation=q('SELECT UUID() id')[1].id
            local request={operation=operation,appearance={version=1},token='first-session'}
            local function commit(d,fn) return exports['mx-freeroam-experience']:CommitOperation(actor,d,'character-test',fn) end
            commit(request,function() return {
                {query='INSERT INTO player_appearance(player_id,document) VALUES (?,?)',values={player,'{"version":1}'}},
                {query='UPDATE player_experience SET character_completed=1 WHERE player_id=?',values={player}}
            },{revision=1} end)
            check(yes(q('SELECT character_completed FROM player_experience WHERE player_id=?',{player})[1].character_completed),'Aparência e conclusão persistidas juntas')
            request.token='reconnected-session'
            local replay=commit(request,function() error('Retry executou gravação novamente') end)
            check(replay.revision==1,'Confirmação perdida: mesmo resultado após troca de sessão sem regravar')
            request.appearance.version=2
            check(not pcall(commit,request,function() return {},{} end),'ID reutilizado com conteúdo diferente rejeitado')
            request.appearance.version=1 request.operation=q('SELECT UUID() id')[1].id
            check(not pcall(commit,request,function() return {
                {query='UPDATE player_experience SET vehicle_completed=1 WHERE player_id=?',values={player}},
                {query='INSERT INTO player_appearance(player_id,document) VALUES (999999999,\'{}\')',values={}}
            },{} end),'Falha de FK interrompe transação')
            check(no(q('SELECT vehicle_completed FROM player_experience WHERE player_id=?',{player})[1].vehicle_completed) and #q('SELECT operation_id FROM experience_operations WHERE player_id=? AND operation_id=?',{player,request.operation})==0,'Rollback conserva etapa pendente e não cria recibo')
            local id=q('SELECT UUID() id')[1].id
            local prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'add',{id=id,model='futo',name='Primeiro'})
            prepared.queries[#prepared.queries+1]={query='UPDATE player_experience SET selected_id=?,vehicle_completed=1 WHERE player_id=?',values={id,player}}
            exports['mx-freeroam-core']:Transaction(prepared.queries)
            check(exports['mx-freeroam-vehicles']:Saved(player,id).name=='Primeiro','Primeiro carro é criação comum persistida')
            check(not pcall(function() exports['mx-freeroam-vehicles']:Saved(player+100000,id) end),'Propriedade de configuração conferida')
            local copy=q('SELECT UUID() id')[1].id
            prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'duplicate',{id=copy,sourceId=id}) exports['mx-freeroam-core']:Transaction(prepared.queries)
            check(#exports['mx-freeroam-vehicles']:SavedList(player)==2,'Duas versões do mesmo modelo com IDs independentes')
            local properties=exports['mx-freeroam-vehicles']:Saved(player,copy).properties
            properties.customPrimary={12,34,56} properties.xenonCustom={40,50,60} properties.primaryFinish=3 properties.dashboardColor=12 properties.mods['23']=250 properties.stance={version=1,height=-.04,frontCamber=-6,rearCamber=-3,frontOffset=.04,rearOffset=.03,wheelSize=1.1,wheelWidth=1.2}
            prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'save',{id=copy,revision=1,properties=properties}) exports['mx-freeroam-core']:Transaction(prepared.queries)
            local recovered=exports['mx-freeroam-vehicles']:Saved(player,copy).properties
            check(recovered.customPrimary[2]==34 and recovered.xenonCustom[3]==60 and recovered.primaryFinish==3 and recovered.dashboardColor==12 and recovered.mods['23']==250 and recovered.stance.frontCamber==-6 and recovered.stance.wheelSize==1.1,'Campos de personalização e stance gravados e recuperados pelos exports reais (sem validar natives)')
            prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'rename',{id=copy,revision=2,name='Outra criação'}) exports['mx-freeroam-core']:Transaction(prepared.queries)
            check(not pcall(function() exports['mx-freeroam-vehicles']:PrepareSaved(player,'delete',{id=copy,revision=1}) end),'Revisão antiga não exclui criação')
            prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'delete',{id=id,revision=1}) exports['mx-freeroam-core']:Transaction(prepared.queries)
            prepared=exports['mx-freeroam-vehicles']:PrepareSaved(player,'delete',{id=copy,revision=3}) exports['mx-freeroam-core']:Transaction(prepared.queries)
            check(#exports['mx-freeroam-vehicles']:SavedList(player)==0 and yes(q('SELECT vehicle_completed FROM player_experience WHERE player_id=?',{player})[1].vehicle_completed),'Excluir todos preserva conclusão do primeiro carro')
        end)
        if not ok then results[#results+1]={ok=false,error=tostring(err)} print('[MX EXPERIENCE FAIL] '..tostring(err)) end
        if player then for _,tableName in ipairs({'garage_usage','experience_operations','player_appearance','player_experience','garage_presets','players'}) do
            if tableName=='garage_usage' then pcall(q,'DELETE u FROM garage_usage u JOIN garage_presets p ON p.id=u.preset_id WHERE p.player_id=?',{player})
            else pcall(q,'DELETE FROM '..tableName..' WHERE '..(tableName=='players' and 'id' or 'player_id')..'=?',{player}) end
        end end
        SaveResourceFile(GetCurrentResourceName(),'experience-report.local.json',json.encode({kind='FXServer real domain exports and MariaDB; no game clients',checks=results}),-1)
    end)
end,false)
RegisterCommand('mxtestworkshopexit',function(src,args)
    if src~=0 then return end
    CreateThread(function()
        local world=exports['mx-freeroam-world'] local slot local target=tonumber(args[1])
        if not target then target=tonumber(GetPlayers()[1]) end
        if not target or not exports['mx-freeroam-core']:Profile(target) then
            SaveResourceFile(GetCurrentResourceName(),'exit-report.local.json',json.encode({status='pending',gameClients=0,note='Reservation native requires a connected player source; console source 0 is not a player. Run mxtestworkshopexit <source> with a client in the isolated test server.'}),-1)
            print('[MX EXIT PENDING] Reserva/saída precisa de source real de cliente conectado') return
        end
        local ok,err=pcall(function()
            local name=exports['mx-freeroam-core']:Query('SELECT DATABASE() name',{})[1].name
            assert(name:match('^mx_freeroam_test'),'Somente banco de teste')
            local settings=exports['mx-freeroam-experience']:PresentationSettings()
            assert(settings.presentation.x==178.62 and settings.exit.x==178.62 and settings.exit.y==-3088.07 and settings.exit.z==5.0 and settings.exit.h==300.0,'Coordenadas temporárias')
            slot=world:ReservePresentationExit(target,settings.exit)
            assert(slot and slot.point.x==settings.exit.x and slot.point.h==settings.exit.h,'Reserva na saída configurada')
            local duplicate=pcall(function() world:ReservePresentationExit(target,settings.exit) end)
            assert(not duplicate,'Reserva concorrente no mesmo espaço deve falhar')
            world:Release(slot.key,target) slot=world:ReservePresentationExit(target,settings.exit)
            assert(slot,'Vaga liberada pode ser reservada novamente')
        end)
        if slot then world:Release(slot.key,target) end
        SaveResourceFile(GetCurrentResourceName(),'exit-report.local.json',json.encode({ok=ok,error=not ok and tostring(err) or nil,gameClients=0,note='Real server slot reservation only; no model streaming or game transition tested'}),-1)
        print(ok and '[MX EXIT PASS] Coordenadas, reserva exclusiva e liberação reais no servidor' or '[MX EXIT FAIL] '..tostring(err))
    end)
end,false)
