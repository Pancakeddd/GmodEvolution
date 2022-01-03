include("neuralnetwork.lua")
local GENE_TYPES = 4
CreateGeneList = function(amount)
  local x = { }
  for i = 1, amount do
    x[i] = rand(1, GENE_TYPES)
  end
  return x
end
LoadRange = function(genes, i, s)
  local true_i = i * s
  if true_i > #genes.genes then
    return 
  end
  local j = 1
  for idx = (true_i - s) + 1, true_i do
    for x = 1, GENE_TYPES do
      add_input(genes.nn, j, (genes.genes[idx] == x) and 1 or 0)
      j = j + 1
    end
  end
end
BuildGenes = function(creator_genes, eff_genes)
  for i = 1, #creator_genes.genes do
    local j = 1
    for z = 1, MAX_CONS do
      LoadRange(creator_genes, i, 2)
      update_all_weights(creator_genes.nn)
      run_all_neurons(creator_genes.nn)
      local ytab = {
        -1,
        nil
      }
      for y = 1, COEFFTYPES do
        local output = get_output(creator_genes.nn, y)
        if output > ytab[1] then
          ytab = {
            output,
            y
          }
        end
      end
      j = j + COEFFTYPES
      eff_genes[i].connections[z].coeffs = ytab[2]
      for y = 1, COEFFTYPES do
        local output = get_output(creator_genes.nn, j + 1)
        eff_genes.coeff_types[clamp(i, 0, COEFFTYPES)][y] = output
      end
    end
  end
end
mutate_builder = function(builder_genes)
  return mutate_genes(builder_genes.nn)
end
