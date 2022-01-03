MAX_CONS = 4
local change_weight_hebbian
change_weight_hebbian = function(widx, start_neuron, end_neuron, abcd)
  return ((abcd[w][1] * start_neuron.state * start_end.state) + (abcd[w][2] * start_neuron.state) + (abcd[w][3] * end_neuron.state))
end
update_all_weights = function(genes)
  local mx = 0.0
  local _list_0 = genes.network
  for _index_0 = 1, #_list_0 do
    local neuron = _list_0[_index_0]
    local _list_1 = neuron.connections
    for _index_1 = 1, #_list_1 do
      local conn = _list_1[_index_1]
      local c = 0.20 * genes.coeff_types[conn.coeffs][5] * ((genes.coeff_types[conn.coeffs][1] * neuron.state * genes.network[conn.conni].state) + (genes.coeff_types[conn.coeffs][2] * neuron.state) + (genes.coeff_types[conn.coeffs][3] * genes.network[conn.conni].state)) + genes.coeff_types[conn.coeffs][4]
      conn.weight = conn.weight + c
      mx = max(mx, abs(conn.weight))
    end
  end
  local _list_1 = genes.network
  for _index_0 = 1, #_list_1 do
    local neuron = _list_1[_index_0]
    local _list_2 = neuron.connections
    for _index_1 = 1, #_list_2 do
      local conn = _list_2[_index_1]
      conn.weight = (conn.weight / mx)
    end
  end
end
