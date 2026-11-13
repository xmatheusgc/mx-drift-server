-- Exercise the actual SavedDisplayList export, without a database connection.
local oldDb,oldDecode=MX.db,json.decode
local model for name,item in pairs(VehicleConfig.catalog)do if not item.conflict and not item.asset then model=name break end end
assert(model,'stock model required for test')
local doc=VehicleProperties.defaults()
local calls=0
MX.db=function(sql,args)
 calls=calls+1
 assert(sql:find('WHERE player_id=? AND id<>? AND schema_version=?',1,true))
 assert(sql:find('LIMIT ?',1,true) and args[1]==71 and args[2]=='exclude-me' and args[3]==VehicleConfig.schema and args[4]==6,'bounded owner-scoped SQL')
 return {{id='invalid',model=model,properties='bad'},
  {id='missing',model='not-installed',properties=doc},
  {id='first',model=model,properties=doc,revision=2},
  {id='second',model=model,properties=doc,revision=3},
  {id='third',model=model,properties=doc}}
end
json.decode=function(v)if v=='bad'then error('corrupt document')end return v end
local result=PreviewTest.exports.SavedDisplayList(71,2,'exclude-me')
assert(calls==1 and #result==2 and result[1].id=='first' and result[2].id=='second','skip bad/missing models and bound result')
assert(not pcall(PreviewTest.exports.SavedDisplayList,71,8) and calls==1,'reject oversized read before SQL')
MX.db,json.decode=oldDb,oldDecode
print('Workshop saved query: actual export owner/exclusion/schema SQL, bounded document read and corrupt/unavailable filtering passed; SQL adapter only.')
