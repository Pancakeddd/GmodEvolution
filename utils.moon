export rand = math.random
export exp = math.exp
export max = math.max
export min = math.min
export clamp = (x, m, n) ->
  min(max(x, m), n)
export pow = math.pow
export log = math.log
export PI = math.pi
export sin = math.sin
export cos = math.cos
export fmod = math.fmod
export abs = math.abs
export floor = math.floor

export randf = (r) ->
  (rand! - 0.5) * r * 2.0

export randb = ->
  (rand 0, 1) == 0

export clamp01 = (x) -> clamp x, 0, 1