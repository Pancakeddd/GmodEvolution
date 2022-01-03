include("neuralnetwork.lua")
local LIMIT_SIZE = 13
local GRAPHS = 32
local CONNI_RANGE = 200
local MAXINGRAPH = 15
local merge_table
merge_table = function(t1, t2)
  for _index_0 = 1, #t2 do
    local to = t2[_index_0]
    t1[#t1 + 1] = to
  end
  return t1
end
local CreateGraphConnection
CreateGraphConnection = function()
  return {
    (rand(1, GRAPHS)),
    (rand(1, LIMIT_SIZE)),
    (rand(-128, 128)),
    1,
    randb()
  }
end
local CreateGraphNode
CreateGraphNode = function(start)
  if start == nil then
    start = false
  end
  local gene = NewRandomGene(NN_SIZE)
  local node = {
    "node",
    gene,
    { }
  }
  local limit = rand(1, MAX_CONS)
  for i = 1, limit do
    node[3][#node[3] + 1] = CreateGraphConnection()
  end
  return node
end
CreateGraph = function(cons, min)
  if min == nil then
    min = 1
  end
  local graph = { }
  local amount = rand(min, cons)
  for i = 1, amount do
    graph[i] = CreateGraphNode(i == 1)
    if rand(1, amount) == 1 then
      break
    end
  end
  return graph
end
CreateGraphSystem = function()
  local graphsystem = {
    generation = 1
  }
  for i = 1, GRAPHS do
    graphsystem[i] = CreateGraphNode()
  end
  return graphsystem
end
print_graphsystem = function(gsys)
  for _index_0 = 1, #gsys do
    local graph = gsys[_index_0]
    local a = tostring(string.char(_index_0 + 64)) .. ":"
    local _list_0 = graph[3]
    for _index_1 = 1, #_list_0 do
      local conn = _list_0[_index_1]
      a = a .. "{" .. tostring(string.char(conn[1] + 64)) .. ", " .. tostring(conn[2]) .. ", " .. tostring(conn[3]) .. "}"
    end
    print(a)
  end
end
local mutate_graph
mutate_graph = function(g, mr, genes)
  mr = mr * 2
  mutate(g[2], mr, genes)
  local _list_0 = g[3]
  for _index_0 = 1, #_list_0 do
    local conn = _list_0[_index_0]
    if did_mutate(mr) then
      conn[1] = max(1, (conn[1] + rand(-2, 2)) % GRAPHS)
    end
    if did_mutate(mr) then
      conn[2] = rand(1, LIMIT_SIZE)
    end
    if did_mutate(mr) then
      conn[3] = rand(-64, 64)
    end
    if did_mutate(mr) then
      conn[4] = rand(1, 2)
    end
    if did_mutate(mr) then
      conn[5] = not conn[5]
    end
  end
  if #g[3] < MAX_CONS and did_mutate(mr / 2) then
    print("ADD")
    g[3][#g[3] + 1] = CreateGraphConnection()
  end
  if #g[3] > 1 and did_mutate(mr / 2) then
    print("SUB")
    return table.remove(g[3], rand(1, #g[3]))
  end
end
mutate_graphsystem = function(gsystem, mr, genes)
  mr = mr / 15
  for _index_0 = 1, #gsystem do
    local graph = gsystem[_index_0]
    mutate_graph(graph, mr, genes)
  end
end
CreateNetworkFromGraph = function(graphsystem, graph, i)
  local nodes = { }
  if graph[1] == "node" then
    nodes[#nodes + 1] = graph[2]
    local _list_0 = graph[3]
    for _index_0 = 1, #_list_0 do
      local g = _list_0[_index_0]
      if g[5] then
        nodes[#nodes].connections[_index_0].conni = #nodes + g[3]
      else
        nodes[#nodes].connections[_index_0].conni = abs(max(1, g[3]))
      end
      nodes[#nodes].connections[_index_0].type = g[4]
      if i > g[2] then
        return nodes
      end
      merge_table(nodes, CreateNetworkFromGraph(graphsystem, graphsystem[g[1]], i + 1))
    end
  end
  if i == 1 then
    local size_dif = #nodes - NN_SIZE
    if size_dif > 0 then
      for j = #nodes, NN_SIZE + 1, -1 do
        table.remove(nodes, #nodes)
      end
    end
    for j = 1, #nodes do
      local _list_0 = nodes[j].connections
      for _index_0 = 1, #_list_0 do
        local conn = _list_0[_index_0]
        if conn.type == 2 then
          conn.conni = max(1, conn.conni % INPUTS)
        else
          conn.conni = max(1, conn.conni % #nodes)
        end
      end
    end
    print(#nodes, "fr")
  end
  return nodes
end
