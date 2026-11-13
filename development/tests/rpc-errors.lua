local ok,err=pcall(function() MX.fail('SLOTS','Ponto ocupado') end)
assert(not ok and type(err)=='table' and err.code=='SLOTS')
local wrapped='An error occurred while calling export ReservePresentationExit:\n'..tostring(err)..'\n---'
local failure=MX.error(wrapped)
assert(failure.code=='SLOTS' and failure.message=='Ponto ocupado','domain failure survives Cfx export string conversion')
local nested='An error occurred while calling export Run:\n'..wrapped
assert(MX.error(nested).code=='SLOTS','nested exports preserve domain failure')
assert(MX.error('attempt to index a nil value').code=='UNAVAILABLE','unexpected exceptions remain internal')
assert(not MX.error('secret SQL text').message:find('secret'),'technical details never returned to the player')
local detail=MX.diagnostic('mysql://name:password@localhost/db cfxk_secret')
assert(not detail:find('password') and not detail:find('cfxk_'),'diagnostics redact credentials')
assert(#MX.diagnostic(string.rep('x',3000))==2048)
print('7 verificações de erro RPC e conversão de exports aprovadas')
