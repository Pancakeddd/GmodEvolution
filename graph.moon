-- Graph = [Node | Graph] & Limit: Int

include "neuralnetwork.lua"

LIMIT_SIZE = 13
GRAPHS = 32
CONNI_RANGE = 200
MAXINGRAPH = 15

merge_table = (t1, t2) ->
  for to in *t2
    t1[#t1+1] = to
  t1

CreateGraphConnection = ->
  {(rand 1, GRAPHS), (rand 1, LIMIT_SIZE), (rand -128, 128), 1, randb!}

CreateGraphNode = (start=false) ->
  --if randb!
    --{"graph", (rand 1, GRAPHS), (rand 1, LIMIT_SIZE)}
  --else
  gene = NewRandomGene NN_SIZE
  node = {"node", gene, {}}
  limit = rand(1, MAX_CONS)
  for i = 1,  limit
    node[3][#node[3]+1] = CreateGraphConnection!

  node
  

export CreateGraph = (cons, min=1) ->
  graph = {}

  amount = rand min, cons

  for i = 1, amount
    graph[i] = CreateGraphNode i == 1

    if rand(1, amount) == 1
      break

  graph

export CreateGraphSystem = ->
  graphsystem = {
    generation: 1
  }

  for i = 1, GRAPHS
    graphsystem[i] = CreateGraphNode!

  graphsystem

export print_graphsystem = (gsys) ->
  for graph in *gsys
    a = "#{string.char _index_0 + 64}:"
    for conn in *graph[3]
      a ..= "{#{string.char conn[1] + 64}, #{conn[2]}, #{conn[3]}}"
    print a

mutate_graph = (g, mr, genes) ->
  mr *= 2
  mutate g[2], mr, genes
  
  for conn in *g[3]
    if did_mutate mr
      conn[1] = max 1, (conn[1] + rand(-2, 2)) % GRAPHS

    if did_mutate mr
      conn[2] = rand 1, LIMIT_SIZE

    if did_mutate mr
      conn[3] = rand -64, 64

    if did_mutate mr
      conn[4] = rand 1, 2

    if did_mutate mr
      conn[5] = not conn[5]

    --if did_mutate mr
    --  g = CreateGraphNode!

  if #g[3] < MAX_CONS and did_mutate mr/2
    print "ADD"
    g[3][#g[3]+1] =  CreateGraphConnection!

  if #g[3] > 1 and did_mutate mr/2
    print "SUB"
    table.remove(g[3], rand 1, #g[3])

export mutate_graphsystem = (gsystem, mr, genes) ->
  mr /= 15
  for graph in *gsystem
    mutate_graph graph, mr, genes

export CreateNetworkFromGraph = (graphsystem, graph, i) ->
  nodes = {}

  if graph[1] == "node"
    nodes[#nodes+1] = graph[2]
    for g in *graph[3]

      if g[5]
        nodes[#nodes].connections[_index_0].conni = #nodes + g[3]
      else
        nodes[#nodes].connections[_index_0].conni = abs max 1, g[3]
      nodes[#nodes].connections[_index_0].type = g[4]

      if i > g[2]
        return nodes
      -- CONNECTIONS NEED TO BE BY GRAPH NODE TO GRAPH CONNECTIO
      merge_table nodes, CreateNetworkFromGraph(graphsystem, graphsystem[g[1]], i+1)

  if i == 1
    size_dif = #nodes - NN_SIZE
    if size_dif > 0
      for j = #nodes, NN_SIZE+1, -1
        table.remove nodes, #nodes

    --if size_dif < 0
      
      --for j = #nodes, NN_SIZE-1
        --nodes[#nodes+1] = NewRandomGene NN_SIZE
        --for conn in *nodes[#nodes]
          --conn.conni = 0

    for j = 1, #nodes
      for conn in *nodes[j].connections
        if conn.type == 2
          conn.conni = max(1, conn.conni % INPUTS)
        else
          conn.conni = max(1, conn.conni % #nodes)

    print #nodes, "fr"
    --print_graphsystem graphsystem
        

  return nodes