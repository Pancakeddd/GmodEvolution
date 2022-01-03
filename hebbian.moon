export MAX_CONS = 4

change_weight_hebbian = (widx, start_neuron, end_neuron, abcd) ->
  ((abcd[w][1] * start_neuron.state * start_end.state) + (abcd[w][2] * start_neuron.state) + (abcd[w][3] * end_neuron.state))

export update_all_weights = (genes) ->
  mx = 0.0

  for neuron in *genes.network
    for conn in *neuron.connections
      --PrintTable genes
      --for kw in *genes.coeff_types[conn.coeffs]
      --  print kw
      --conn.conni = floor(_index_0 + (neuron.amount_of_cons * genes.coeff_types[conn.coeffs][6])) % neuron.amount_of_cons
      --conn.conni = conn.conni > 0 and conn.conni or conn.conni + 1

      c = 0.20 * genes.coeff_types[conn.coeffs][5] * ((genes.coeff_types[conn.coeffs][1] * neuron.state * genes.network[conn.conni].state) + (genes.coeff_types[conn.coeffs][2] * neuron.state) + (genes.coeff_types[conn.coeffs][3] * genes.network[conn.conni].state)) + genes.coeff_types[conn.coeffs][4]

      conn.weight = conn.weight + c
      mx = max(mx, abs conn.weight)

  for neuron in *genes.network
    for conn in *neuron.connections
      conn.weight = (conn.weight / mx)
      --print conn.weight
      --conn.weight *= 2