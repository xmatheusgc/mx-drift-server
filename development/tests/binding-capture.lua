local C=BindingCapture
local state=C.new('key',0)
assert(not C.read(state,0,{G=true},{}),'opening key ignored')
assert(not C.read(state,100,{},{}))assert(not C.read(state,200,{},{}))
assert(C.read(state,210,{LEFT=true},{}).value=='LEFT','keyboard arrow captured after neutral')
state=C.new('pad',0)
C.read(state,0,{},{});C.read(state,100,{},{});
assert(not C.read(state,110,{G=true},{}),'wrong device ignored')
assert(C.read(state,120,{}, {X=true}).value=='X','controller captured')
state=C.new('key',0);C.read(state,0,{},{});C.read(state,100,{},{});
assert(not C.read(state,110,{G=true,R=true},{}),'chords do not select arbitrary key')
assert(not C.read(state,120,{R=true},{}),'remaining chord key ignored until release')
C.read(state,130,{},{});C.read(state,230,{},{});
assert(C.read(state,240,{R=true},{}).value=='R')
assert(C.read(C.new('pad',0),1,{ESC=true},{}).cancelled,'ESC cancels either device')
assert(C.read(C.new('key',0),15000,{},{}).cancelled,'capture expires')
print('Capture state machine: release guard, both devices, arrows, chord rejection, cancel and timeout passed.')
