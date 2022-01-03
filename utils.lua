rand = math.random
exp = math.exp
max = math.max
min = math.min
clamp = function(x, m, n)
  return min(max(x, m), n)
end
pow = math.pow
log = math.log
PI = math.pi
sin = math.sin
cos = math.cos
fmod = math.fmod
abs = math.abs
floor = math.floor
randf = function(r)
  return (rand() - 0.5) * r * 2.0
end
randb = function()
  return (rand(0, 1)) == 0
end
clamp01 = function(x)
  return clamp(x, 0, 1)
end
