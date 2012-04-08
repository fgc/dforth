  set a,1
  add b,a
  ifn a, b
:die 
  set pc, die
  set i,10
  set push, i
  set x,pop
  set push, ret
  set pc, function
:ret
  set pc, die
:function
  set i,5
  set[0 + i],255
  ife i, 0
  set pc, pop
  set pc, function