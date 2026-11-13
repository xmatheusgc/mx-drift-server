-- Somente banco de teste. Fixtures SQL verificam a entrega durável, não simulam uma corrida validada.
local fixture
local report={}
local function check(condition,name) assert(condition,name) report[#report+1]={check=name,ok=true} print('[MX TEST PASS] '..name) end
local function q(sql,args) return exports['mx-freeroam-core']:Query(sql,args or {}) end
local function isolated()
    local name=q('SELECT DATABASE() AS name')[1].name
    assert(name:match('^mx_freeroam_test'), 'Recusado: banco não isolado')
end
RegisterCommand('mxtest',function(src,args)
    if src~=0 then return end
    CreateThread(function()
        local ok,err=pcall(function()
            isolated()
            if args[1]=='prepare' then
                report={}
                assert(GetResourceState('mx-freeroam-progression')~='started','Pare progression antes da fase prepare')
                local player=q('SELECT UUID() AS id')[1].id
                q('INSERT INTO players(identifier,name) VALUES (?,?)',{'verification:'..player,'Verificação'})
                local pid=q('SELECT id FROM players WHERE identifier=?',{'verification:'..player})[1].id
                fixture={player=pid,results={},track='verify-'..player:sub(1,12)}
                fixture.weekly='test-'..player:sub(1,12)
                q('INSERT INTO weekly_challenges(id,starts_at,ends_at,definition) VALUES (?,UTC_TIMESTAMP()-INTERVAL 1 DAY,UTC_TIMESTAMP()+INTERVAL 1 DAY,?)',{fixture.weekly,json.encode({enabled=true,track=fixture.track,revision=1,condition='complete',xp=50})})
                q('INSERT INTO weekly_challenges(id,starts_at,ends_at,definition) VALUES (?,UTC_TIMESTAMP()-INTERVAL 2 DAY,UTC_TIMESTAMP()-INTERVAL 1 DAY,?)',{fixture.weekly..'-expired',json.encode({enabled=true,track=fixture.track,revision=1,condition='complete',xp=50})})
                for _,entry in ipairs({{mode='timeattack',eligible=1,reason=''},{mode='drift',eligible=0,reason='drift_training'},{mode='timeattack',eligible=0,reason='checkpoint_missing'}}) do
                    local id=q('SELECT UUID() AS id')[1].id fixture.results[#fixture.results+1]=id
                    exports['mx-freeroam-core']:Transaction({{query=[[INSERT INTO activity_results(id,player_id,track_id,track_revision,direction,mode,rules,model,signature,conditions,duration_ms,eligible,reason,evidence,created_at) VALUES (?,?,?,1,'forward',?,'test-v1','futo','stock','clear',10000,?,?,'{"state":"completed"}',UTC_TIMESTAMP(3))]],values={id,pid,fixture.track,entry.mode,entry.eligible,entry.reason}}, {query='INSERT INTO activity_delivery(result_id) VALUES (?)',values={id}}})
                end
                check(tonumber(q('SELECT COUNT(*) AS n FROM activity_delivery WHERE processed=0 AND result_id IN (?,?,?)',fixture.results)[1].n)==3,'Resultados duráveis com progressão desligada')
                check(tonumber(q('SELECT COUNT(*) AS n FROM xp_ledger WHERE player_id=?',{pid})[1].n)==0,'Sem prêmio em memória ou ledger quando progressão está desligada')
            elseif args[1]=='process' then
                assert(fixture,'Execute prepare antes')
                exports['mx-freeroam-progression']:Reprocess() Wait(500)
                check(tonumber(q('SELECT COALESCE(SUM(delta),0) AS xp FROM xp_ledger WHERE player_id=?',{fixture.player})[1].xp)==150,'Somente resultado elegível premia; drift/invalidade não premiam')
                exports['mx-freeroam-progression']:Reprocess() Wait(500)
                check(tonumber(q('SELECT COUNT(*) AS n FROM xp_ledger WHERE player_id=?',{fixture.player})[1].n)==2,'Reprocessamento idempotente')
                check(tonumber(q('SELECT COUNT(*) AS n FROM challenge_claims WHERE player_id=?',{fixture.player})[1].n)==1,'Prêmio semanal único; desafio expirado não premia')
                check(tonumber(q('SELECT COUNT(*) AS n FROM progression_receipts WHERE result_id IN (?,?,?)',fixture.results)[1].n)==3,'Recibos duráveis para todos os resultados')
                local granted=q('SELECT granted FROM achievement_progress WHERE player_id=?',{fixture.player})[1].granted
                check(granted==1 or granted==true,'Conquista derivada concedida')
                local authorized=pcall(function() exports['mx-freeroam-progression']:AuthorizeCosmetics(fixture.player,{icon='flag',title='explorador'}) end)
                check(authorized,'Cosméticos elegíveis autorizados pelo estado persistido')
                local locked=pcall(function() exports['mx-freeroam-progression']:AuthorizeCosmetics(fixture.player,{icon='star',title='novato'}) end)
                check(not locked,'Ícone bloqueado rejeitado no domínio')
            elseif args[1]=='revoke' then
                assert(fixture,'Execute prepare antes')
                exports['mx-freeroam-activities']:Revoke(fixture.results[1],'verification_revoke')
                Wait(1000) exports['mx-freeroam-progression']:Reprocess() Wait(500)
                check(tonumber(q('SELECT COALESCE(SUM(delta),0) AS xp FROM xp_ledger WHERE player_id=?',{fixture.player})[1].xp)==0,'Compensação reconcilia XP')
                exports['mx-freeroam-activities']:Revoke(fixture.results[1],'verification_revoke_again')
                Wait(1000) exports['mx-freeroam-progression']:Reprocess() Wait(500)
                check(tonumber(q('SELECT COUNT(*) AS n FROM xp_ledger WHERE player_id=? AND delta<0',{fixture.player})[1].n)==2,'Compensações de rota e semanal únicas')
                local granted=q('SELECT granted FROM achievement_progress WHERE player_id=?',{fixture.player})[1].granted
                check(granted==0 or granted==false,'Conquista derivada retirada')
                local prior=tonumber(q('SELECT COUNT(*) AS n FROM xp_ledger WHERE player_id=?',{fixture.player})[1].n)
                local txOk=pcall(function() exports['mx-freeroam-core']:Transaction({{query="INSERT INTO xp_ledger(player_id,origin,delta,policy) VALUES (?,'rollback-check',10,'test')",values={fixture.player}}, {query="INSERT INTO player_preferences(player_id,document) VALUES (999999999,'{}')",values={}}}) end)
                check(not txOk and tonumber(q('SELECT COUNT(*) AS n FROM xp_ledger WHERE player_id=?',{fixture.player})[1].n)==prior,'Falha no meio da transação preserva ledger anterior')
            elseif args[1]=='replay' then
                assert(fixture,'Execute prepare antes')
                exports['mx-freeroam-progression']:Reprocess() Wait(500)
                check(tonumber(q('SELECT COALESCE(SUM(delta),0) AS xp FROM xp_ledger WHERE player_id=?',{fixture.player})[1].xp)==0,'Restart de atividades/progressão preserva compensação e não repremia')
            else error('Use prepare, process, revoke, replay') end
        end)
        if not ok then print('[MX TEST FAIL] '..tostring(err)) report[#report+1]={ok=false,error=tostring(err)} end
        SaveResourceFile(GetCurrentResourceName(),'report.local.json',json.encode(report),-1)
    end)
end,false)
