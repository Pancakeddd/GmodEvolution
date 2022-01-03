include "neuralnetwork.lua"

GENE_TYPES = 4

export CreateGeneList = (amount) ->
  x = {}

  for i = 1, amount
    x[i] = rand 1, GENE_TYPES

  x

export LoadRange = (genes, i, s) ->
  true_i = i * s

  if true_i > #genes.genes
    return

  j = 1
  for idx = (true_i - s)+1, true_i
    for x = 1, GENE_TYPES
      add_input genes.nn, j, (genes.genes[idx] == x) and 1 or 0 
      j += 1

export BuildGenes = (creator_genes, eff_genes) ->
  for i = 1, #creator_genes.genes
    j = 1
    for z = 1, MAX_CONS
      LoadRange creator_genes, i, 2
  
      update_all_weights creator_genes.nn

      run_all_neurons creator_genes.nn

      ytab = {
        -1, nil
      }

      for y = 1, COEFFTYPES
        output = get_output creator_genes.nn, y
        

        if output > ytab[1]
          ytab = {output, y}

      j += COEFFTYPES

      eff_genes[i].connections[z].coeffs = ytab[2]

      for y = 1, COEFFTYPES
        output = get_output creator_genes.nn, j+1

        eff_genes.coeff_types[clamp(i, 0, COEFFTYPES)][y] = output

export mutate_builder = (builder_genes) ->
  mutate_genes builder_genes.nn