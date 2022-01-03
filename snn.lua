include("utils.lua")
include("hebbian.lua")
local sigmoid
sigmoid = function(x)
  return 1.0 / (1.0 + exp(-x))
end
INPUTS = 39
OUTPUTS = 21
local MAX_SLOTS = 39
local COEFFTYPES = 10
RAND_STATES_AMOUNT = 4
NN_SIZE = 750
local CreateCoeffs
CreateCoeffs = function(amount)
  local x = { }
  for i = 1, amount do
    x[i] = randf(1)
  end
  return x
end
local CreateCoeffTypes
CreateCoeffTypes = function(amounts)
  local y = { }
  for i = 1, amounts do
    y[i] = CreateCoeffs(8)
  end
  return y
end
NewConnection = function(total_aoc)
  return {
    conni = (rand(1, total_aoc)),
    weight = randf(0.1),
    notted = randb(),
    coeffs = rand(1, COEFFTYPES),
    over_weight = 1
  }
end
local CreateConnections
CreateConnections = function(aoc, total_aoc, j)
  if j == nil then
    j = 1
  end
  local cons = { }
  for i = 1, aoc do
    cons[i] = NewConnection(total_aoc)
    cons[i].conni = rand(OUTPUTS, total_aoc)
  end
  return cons
end
NewRandomGene = function(amount, j)
  local amount_of_cons = amount
  return {
    amount_of_cons = amount_of_cons,
    connections = CreateConnections(MAX_CONS, amount, j),
    bias = rand() * 0.3,
    threshhold = 0.5,
    change = 0.2 + (rand() * 0.08),
    state = 0.0,
    target = 0.0,
    potential = 0.0,
    wait = CurTime(),
    drop_wait = 0,
    freq = rand() * 5,
    upcome = false,
    has_run = false
  }
end
CreateGenes = function(amount)
  local genes = {
    mr = 2.0,
    generation = 1,
    network = { },
    normal_values = {
      scale = rand(),
      food_type = rand()
    },
    coeff_types = CreateCoeffTypes(COEFFTYPES)
  }
  for i = 1, amount do
    genes.network[#genes.network + 1] = NewRandomGene(amount, i)
  end
  return genes
end
ResetWeights = function(genes)
  local _list_0 = genes.network
  for _index_0 = 1, #_list_0 do
    local neuron = _list_0[_index_0]
    neuron.state = 0.0
    local _list_1 = neuron.connections
    for _index_1 = 1, #_list_1 do
      local conn = _list_1[_index_1]
      conn.weight = randf(0.1)
    end
  end
end
local calculateAND
calculateAND = function(self, total_neurons)
  local accum = 1.0
  local _list_0 = self.connections
  for _index_0 = 1, #_list_0 do
    local conn = _list_0[_index_0]
    local v = total_neurons[conn.conni].state
    if conn.notted then
      v = 1.0 - v
    end
    accum = accum * v
  end
  local e = accum * self.bias
  self.target = e
end
local calculateOR
calculateOR = function(self, total_neurons)
  local accum = 0.0
  local _list_0 = self.connections
  for _index_0 = 1, #_list_0 do
    local conn = _list_0[_index_0]
    local v = total_neurons[conn.conni].state
    if conn.notted then
      v = 1.0 - v
    end
    accum = accum + (v * (conn.weight * conn.over_weight) * 2)
  end
  local e = accum + self.bias
  self.target = sigmoid(e)
end
calculate_neuron = function(self, total_neurons)
  local potential = 0.0
  if self.has_run then
    return 
  end
  self.has_run = true
  if self.state > self.threshhold and not self.upcome then
    print("FIRE, " .. tostring(self.state))
    self.upcome = true
    local _list_0 = self.connections
    for _index_0 = 1, #_list_0 do
      local conn = _list_0[_index_0]
      total_neurons[conn.conni].state = total_neurons[conn.conni].state + conn.weight
      total_neurons[conn.conni].upcome = true
    end
    local _list_1 = self.connections
    for _index_0 = 1, #_list_1 do
      local conn = _list_1[_index_0]
      calculate_neuron(total_neurons[conn.conni], total_neurons)
    end
    self.state = 1
  end
  if self.upcome then
    self.state = 0
    self.upcome = false
    return 
  end
end
local push_state
push_state = function(self)
  local R_M = 0.1
  local TAU = 1
  self.state = max(0, ((self.state) * 0.3))
  self.has_run = false
end
local reset_neuron
reset_neuron = function(self, ns)
  self.has_run = false
  self.has_outputted = false
  if ns then
    self.state = ns
    self.has_run = true
  end
end
run_all_neurons = function(neurons)
  local _list_0 = neurons.network
  local _max_0 = INPUTS
  for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
    local n = _list_0[_index_0]
    calculate_neuron(n, neurons.network)
  end
  local _list_1 = neurons.network
  for _index_0 = 1, #_list_1 do
    local n = _list_1[_index_0]
    push_state(n)
  end
end
reset_neurons = function(neurons) end
add_input = function(neurons, slot, value)
  if neurons.network[slot + 1].wait <= CurTime() then
    neurons.network[slot + 1].state = 5
    neurons.network[slot + 1].upcoming = false
    neurons.network[slot + 1].wait = CurTime() + 1 - clamp01(value)
    neurons.network[slot + 1].has_run = true
    neurons.network[slot + 1].type = 1
  end
end
get_output = function(neurons, slot)
  do
    local _with_0 = neurons.network[#neurons.network - slot]
    if _with_0.i == nil then
      _with_0.i = 1
      _with_0.accum = _with_0.state
    else
      _with_0.i = _with_0.i + 1
      _with_0.accum = _with_0.accum + _with_0.state
      if _with_0.i > 32 then
        _with_0.i = 1
        _with_0.accum = _with_0.state
      end
    end
    return _with_0.accum / _with_0.i
  end
end
did_mutate = function(mr)
  if rand() * 1000.0 < mr then
    print("RECHT")
    return true
  end
end
mutate = function(self, mr, genes)
  local _list_0 = self.connections
  for _index_0 = 1, #_list_0 do
    local conn = _list_0[_index_0]
    if did_mutate(mr) then
      conn.conni = conn.conni + (rand(-2, 2))
      conn.conni = max(1, conn.conni % #genes.network)
    end
    if did_mutate(mr) then
      conn.conni = rand(1, #genes.network)
    end
    if did_mutate(mr * 3) then
      conn.over_weight = max(1, conn.over_weight + (randf(0.25)))
      print(conn.over_weight)
    end
    if did_mutate(mr) then
      conn.notted = randb()
    end
    if did_mutate(mr) then
      conn.coeff = rand(1, COEFFTYPES)
    end
  end
  if did_mutate(mr) then
    self.change = clamp(self.change + (randf(0.25)), 0.001, 1)
  end
  if did_mutate(mr * 3) then
    self.bias = clamp01(self.bias + (randf(0.25)))
  end
  if did_mutate(mr * 3) then
    self.freq = clamp01(self.freq + randf(0.25))
  end
end
mutate_genes = function(genes)
  if did_mutate(genes.mr * 2) then
    genes.mr = clamp(genes.mr + (randf(7.0)), 0, 1000)
  end
  for k, v in pairs(genes.normal_values) do
    if did_mutate(genes.mr * 3) then
      print("ASS")
      genes.normal_values[k] = clamp01(genes.normal_values[k] + randf(0.25))
    end
  end
  local _list_0 = genes.coeff_types
  for _index_0 = 1, #_list_0 do
    local coeff = _list_0[_index_0]
    for _index_1 = 1, #coeff do
      local x = coeff[_index_1]
      if did_mutate(genes.mr * 2) then
        x = clamp(x + randf(0.25), -1, 1)
      end
    end
  end
  local _list_1 = genes.network
  for _index_0 = 1, #_list_1 do
    local n = _list_1[_index_0]
    mutate(n, genes.mr * 2, genes)
  end
end
crossbreed = function(genes1, genes2)
  if randb() then
    genes1.mr = genes2.mr
  end
  local which_parent = false
  for _index_0 = 1, #genes1 do
    local v = genes1[_index_0]
    if rand(0, #genes1) == 0 then
      which_parent = not which_parent
    end
    if which_parent then
      v = genes2[_index_0]
    end
  end
end
