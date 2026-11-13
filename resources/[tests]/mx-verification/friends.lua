RegisterCommand('mxtestfriends',function(src)
 if src~=0 then return end
 CreateThread(function()
  local ids={} local results={} local social=exports['mx-freeroam-social']
  local function q(sql,args) return exports['mx-freeroam-core']:Query(sql,args or {}) end
  local function check(value,name) assert(value,name) results[#results+1]={ok=true,name=name} print('[MX FRIENDS PASS] '..name) end
  local ok,err=pcall(function()
   assert(q('SELECT DATABASE() name')[1].name:match('^mx_freeroam_test'),'Banco não isolado')
   for i=1,3 do local key='friends:'..q('SELECT UUID() id')[1].id q('INSERT INTO players(identifier,name) VALUES (?,?)',{key,'Amigo teste '..i}) ids[i]=q('SELECT id FROM players WHERE identifier=?',{key})[1].id end
   local a,b,c=ids[1],ids[2],ids[3]
   check(not pcall(function() social:FriendSend(0,{target=a},{id=a}) end),'Auto-solicitação rejeitada')
   check(not pcall(function() social:FriendSend(0,{target=b},{id=a}) end),'Envio para jogador offline não simula sucesso')
   q('INSERT INTO player_friendships(low_player_id,high_player_id,requested_by) VALUES (?,?,?)',{a,b,a})
   check(social:FriendSend(0,{target=b},{id=a}).status=='pending' and #q('SELECT * FROM player_friendships WHERE low_player_id=? AND high_player_id=?',{a,b})==1,'Reenvio idempotente de solicitação persistida')
   check(#social:FriendState(a).outgoing==1 and #social:FriendState(b).incoming==1,'Listas separadas de solicitações enviadas e recebidas')
   check(not pcall(function() social:FriendRespond(0,{target=b,accept=true},{id=a}) end),'Remetente não aceita a própria solicitação')
   check(not pcall(function() social:FriendRespond(0,{target=a,accept=true},{id=c}) end),'Terceiro não aceita solicitação alheia')
   check(social:FriendRespond(0,{target=a,accept=true},{id=b}).status=='accepted','Aceite por destinatário grava relação real')
   check(social:FriendRespond(0,{target=a,accept=true},{id=b}).status=='accepted','Repetição do aceite não duplica relação')
   check(#social:FriendState(a).friends==1 and #social:FriendState(b).friends==1 and not social:FriendState(a).friends[1].online,'Amigos offline recuperados por ambos os IDs persistentes')
   q('INSERT INTO player_friendships(low_player_id,high_player_id,requested_by) VALUES (?,?,?)',{a,c,c})
   check(social:FriendRespond(0,{target=c,accept=false},{id=a}).status=='declined' and #social:FriendState(a).incoming==0,'Recusa remove somente a solicitação recebida')
   check(not pcall(function() q('INSERT INTO player_friendships(low_player_id,high_player_id,requested_by) VALUES (?,?,?)',{b,a,a}) end),'Banco impede par invertido')
  end)
  if not ok then results[#results+1]={ok=false,error=tostring(err)} print('[MX FRIENDS FAIL] '..tostring(err)) end
  for _,id in ipairs(ids) do pcall(q,'DELETE FROM players WHERE id=?',{id}) end
  SaveResourceFile(GetCurrentResourceName(),'friends-report.local.json',json.encode({kind='real SQL and social exports; online delivery requires two game clients',checks=results}),-1)
 end)
end,false)
