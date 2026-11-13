local T=ManagementTest
local function apply(action,audit) return AdminModeration.apply(1,{target=2,action=action,reason='Test reason'},'request-1',audit or function()end) end
assert(not pcall(apply,'ban') and #T.drops==0 and T.writes==0,'client cannot bypass admin gate')
T.grant(1,'ban') assert(not pcall(apply,'ban'),'action ACE alone cannot grant admin membership')
T.grant(1,'admin')
assert(not pcall(apply,'kick'),'admin membership does not bypass per-action permissions')
assert(not pcall(function()AdminModeration.apply(1,{target='test-player',action='ban',reason='Test reason'},'',function()end)end),'fixture cannot reach real moderation')
assert(not pcall(apply,'ban',function()T.players[2]='license:reused'end),'source reuse after audit is rejected') T.players[2]='license:target'
assert(not pcall(apply,'ban',function()T.actor={id=11,epoch='new-epoch'}end),'admin session reuse after audit is rejected') T.actor={id=10,epoch='admin-epoch'}
T.grant(2,'admin') assert(not pcall(apply,'ban'),'administrators are protected targets') T.ace['2:mx.admin']=false
T.failDisk=true assert(not pcall(apply,'ban') and #T.drops==0,'failed durable write cannot claim or execute ban') T.failDisk=false
assert(apply('ban').applied and #T.drops==1,'ban persists before disconnect')
assert(T.exports.CheckConnection('license:target'):find('Test reason') and not T.exports.CheckConnection('license:other'),'connection gate checks stable identity')
T.grant(1,'warn') assert(apply('warn').applied and #T.notices==1 and #T.drops==1,'warning only notifies selected real player')
T.grant(1,'kick') assert(apply('kick').applied and #T.drops==2,'authorized kick disconnects selected player')
print('Moderation: admin + action ACE, mock rejection, target/admin source reuse, protected admin, durable-write failure, ban, kick, warning and connection checks passed (adapters).')
