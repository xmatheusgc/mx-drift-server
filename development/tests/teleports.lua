local T=ManagementTest local create=T.exports.CreateTeleport
T.grant(1,'content')
T.invoker='other-resource' assert(not pcall(create,1,'Circuit','Circuito'),'untrusted resource cannot author teleports') T.invoker='mx-freeroam-admin'
T.ace['1:mx.admin']=false assert(not pcall(create,1,'Circuit','Circuito'),'world independently checks admin ACE') T.grant(1,'admin')
T.bucket=10001 assert(not pcall(create,1,'Circuit','Circuito'),'private-scene position cannot be published') T.bucket=0
T.failDisk=true assert(not pcall(create,1,'Circuit','Circuito') and next(WorldConfig.destinations)==nil,'failed write cannot publish teleport') T.failDisk=false
local result=create(1,'Circuit','Circuito',{x=999})
assert(WorldConfig.destinations[result.id].slots[1].x==100,'coordinates are server-observed, extra client args ignored')
assert(WorldConfig.destinations[result.id].category=='Circuito','category is preserved')
local second=create(1,'Touge','Touge') assert(result.id~=second.id,'same-second creations cannot overwrite each other')
assert(not pcall(create,1,'\n','Circuito'),'invalid labels rejected')
T.trackId=result.id
print('Teleport authoring: trusted caller, independent ACE, public bucket, disk failure, server coordinates, labels and unique IDs passed (adapters).')
