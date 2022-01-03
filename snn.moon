include "utils.lua"
include "hebbian.lua"

sigmoid = (x) ->
  1.0 / (1.0 + exp(-x))
  --clamp(x, 0, 1)

export INPUTS = 39
export OUTPUTS = 21
MAX_SLOTS = 39
COEFFTYPES = 10
export RAND_STATES_AMOUNT = 4
export NN_SIZE = 750

CreateCoeffs = (amount) ->
  x = {}

  for i = 1, amount
    x[i] = randf 1

  x

CreateCoeffTypes = (amounts) ->
  y = {}
  
  for i = 1, amounts
    y[i] = CreateCoeffs 8
  
  y

export NewConnection = (total_aoc) ->
  {
    conni: (rand 1, total_aoc)
    weight: randf 0.1
    notted: randb!
    coeffs: rand 1, COEFFTYPES
    over_weight: 1
  }

CreateConnections = (aoc, total_aoc, j = 1) ->
  cons = {}

  for i = 1, aoc
    cons[i] = NewConnection total_aoc

    cons[i].conni = rand OUTPUTS, total_aoc

  cons

export NewRandomGene = (amount, j) ->
  amount_of_cons = amount
  {
    :amount_of_cons

    connections: CreateConnections MAX_CONS, amount, j

    bias: rand! * 0.3
    threshhold: 0.5
    change: 0.2 + (rand! * 0.08)
    --type: 0
    --action_type: randb!

    state: 0.0
    target: 0.0
    potential: 0.0
    wait: CurTime!
    drop_wait: 0
    freq: rand! * 5
    upcome: false
    --target: 0.0
    --has_outputted: false
    has_run: false
  }

export CreateGenes = (amount) ->
  genes = {
    mr: 2.0
    generation: 1
    network: {}

    normal_values: {
      scale: rand!
      food_type: rand!
    }

    coeff_types: CreateCoeffTypes COEFFTYPES
  }

  for i = 1, amount
    genes.network[#genes.network+1] = NewRandomGene amount, i


  genes

export ResetWeights = (genes) ->
  for neuron in *genes.network
    neuron.state = 0.0
    for conn in *neuron.connections
      conn.weight = randf 0.1

calculateAND = (total_neurons) =>
  accum = 1.0

  for conn in *@connections
    v = total_neurons[conn.conni].state

    if conn.notted
      v = 1.0 - v

    accum *= v

  e = accum * @bias
  @target = e

calculateOR = (total_neurons) =>
  accum = 0.0
  for conn in *@connections
    
    v = total_neurons[conn.conni].state

    if conn.notted
      v = 1.0 - v

    accum += v * (conn.weight * conn.over_weight) * 2

  e = accum + @bias

  @target = sigmoid e

export calculate_neuron = (total_neurons) =>
  --if (@has_run)
  --  return @state

  --@has_run = true
  --print @potential, @threshhold, @wait, CurTime!
  --print "#{@threshhold}"

  potential = 0.0

  if @has_run
    return

  @has_run = true

  -- Integrate my nuts

  

  if @state > @threshhold and not @upcome
    print "FIRE, #{@state}"
    @upcome = true
    for conn in *@connections
      total_neurons[conn.conni].state += conn.weight
      total_neurons[conn.conni].upcome = true
    
    for conn in *@connections
      calculate_neuron total_neurons[conn.conni], total_neurons

    @state = 1

      --inp = 0.0
      --if conn.notted
        --v =  1-v
      --print "V: #{v}"
      
      --print "#{v}, #{conn.weight}"

  if @upcome
    --print "RESET"
    @state = 0
    @upcome = false
    return
      


    
  --print "potential #{potential}"
  --print state_inf, "state_inf"
  --print @state
  

  
 -- print @state
  --print @target
  --print @state, state_inf

  
    --print "FIRE! #{@state}"
    --@state = 1.0

  --if @state > @threshhold
  --  print "Spike! #{@state}"
  --  
--
  --  @state = @bias * 0.5
  --  --print @target
  --  @wait = CurTime! + @freq
  --else
   -- @state = 0

    --print @target 

  --@potential = 0.0

  --@state = clamp01 @state
  --@target = clamp01 @target
  --@target += (@bias - @target) * 0.3
  --@target = @state

  --@state

push_state = =>
  
  R_M = 0.1
  TAU = 1
  @state = max 0, ((@state)*0.3)
  --print @state
  --@state = @target
  @has_run = false

reset_neuron = (ns) =>
  @has_run = false
  @has_outputted = false

  if ns
    @state = ns
    @has_run = true

export run_all_neurons = (neurons) ->
  for n in *neurons.network[,INPUTS]
    calculate_neuron n, neurons.network

  for n in *neurons.network
    push_state n

export reset_neurons = (neurons) ->

  --for n in *neurons.network[,INPUTS]
  --  reset_neuron n, 0.0

  --for n in *neurons[INPUTS,]
  --  reset_neuron n

export add_input = (neurons, slot, value) ->
  --if slot > INPUTS
  --  print "Aids! #{slot}"
  
  --print "#{neurons.network[slot+1].wait}, #{CurTime!}"


  if neurons.network[slot+1].wait <= CurTime!
    neurons.network[slot+1].state = 5
    neurons.network[slot+1].upcoming = false
    --print neurons.network[slot+1].state
    neurons.network[slot+1].wait = CurTime! + 1 - clamp01 value
    neurons.network[slot+1].has_run = true
    neurons.network[slot+1].type = 1

export get_output = (neurons, slot) ->

  --print neurons.network[#neurons.network].state

  with neurons.network[#neurons.network-slot]
    if .i == nil
      .i = 1
      .accum = .state
    else
      .i += 1
      .accum += .state

      if .i > 32
        .i = 1
        .accum = .state

  
    return .accum/.i

export did_mutate = (mr) ->
  if rand!*1000.0 < mr
    print "RECHT"
    return true

export mutate = (mr, genes) =>
  --if did_mutate mr
  --  @ = NewRandomGene #@
  -- connection mutations

  for conn in *@connections
    if did_mutate mr
      conn.conni = conn.conni + (rand -2, 2)
      conn.conni = max(1, conn.conni % #genes.network)

    if did_mutate mr
      conn.conni = rand 1, #genes.network
    if did_mutate mr*3
      conn.over_weight = max 1, conn.over_weight + (randf 0.25)
      print conn.over_weight
    if did_mutate mr
      conn.notted = randb!
    if did_mutate mr
      conn.coeff = rand 1, COEFFTYPES   

    --if did_mutate mr
    --  conn = NewConnection #@

  --if did_mutate mr
  --  @type = rand 0, 2

  if did_mutate mr
    @change = clamp(@change + (randf 0.25), 0.001, 1)

  --if did_mutate mr
  --  @action_type = not @action_type

  if did_mutate mr*3
    @bias = clamp01 @bias + (randf 0.25)

  --if did_mutate mr*3
    --@threshhold += randf 0.5

  if did_mutate mr*3
    @freq = clamp01 @freq + randf 0.25

export mutate_genes = (genes) ->
  if did_mutate genes.mr*2
    genes.mr = clamp(genes.mr + (randf 7.0), 0, 1000)


  for k, v in pairs genes.normal_values
    if did_mutate genes.mr*3
      print "ASS"
      genes.normal_values[k] = clamp01 genes.normal_values[k] + randf 0.25
      
  for coeff in *genes.coeff_types
    for x in *coeff
      --PrintTable x
      if did_mutate genes.mr*2
        x = clamp x + randf(0.25), -1, 1

  for n in *genes.network
    mutate n, genes.mr*2, genes

export crossbreed = (genes1, genes2) ->
  if randb!
    genes1.mr = genes2.mr

  which_parent = false

  for v in *genes1
    if rand(0, #genes1) == 0
      which_parent = not which_parent

    if which_parent
      v = genes2[_index_0]

