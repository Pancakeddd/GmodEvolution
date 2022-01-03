AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"

include "shared.lua"
include "neuralnetwork.lua"
include "graph.lua"

LEARNING_RATE = 0.01
DISCOUNT = 0.95
MAX_NUTR = 3500

S_MUL = 2

ENT.Initialize = (new_genes) =>
  @SetModel "models/props_c17/clock01.mdl"
  @PhysicsInit SOLID_VPHYSICS
  @SetMoveType MOVETYPE_VPHYSICS
  @SetSolid SOLID_VPHYSICS

  with @GetPhysicsObject!
    if \IsValid!
      \Wake!

  @angle = rand! * PI*2
  @energy = 10
  @water = 0
  @health = 100.0
  @time_alive = 0
  @previous_pos = @GetPos!
  @gnutrient = 0.0
  @anutrient = 0.0
  @bnutrient = 0.0
  @nutrient_delay = 0.0
  @inited_genes = false
  @sectraces = {}
  @random_states = {}
  @sex = randb!
  @reset_already = false
  @mr = 5.0
  @repcounter = 0

  for i = 1, RAND_STATES_AMOUNT
    @random_states[i] = 0

  @random_states[rand(1, RAND_STATES_AMOUNT)] = 1

ENT.ChangeInPos ==>
  @previous_pos - @GetPos!

ENT.Scale ==>
  @SetModelScale @scale
  @Activate!

ENT.ScaleNormalized ==>
  @scale/S_MUL

ENT.GetTraceColor = (mattype) =>
  switch mattype
    when 68
      Color 255, 0, 0
    else
      Color 0, 255, 255

ENT.AddInputs ==>
  --print "oo", @GetVelocity!.x/1000, clamp(@GetVelocity!.x/1000, -1.0, 1.0)
  add_input @genes, 0, rand!
  add_input @genes, 1, clamp01 abs(@ChangeInPos!.x/25)
  add_input @genes, 2, clamp01 abs(@ChangeInPos!.y/25)
  add_input @genes, 3, fmod(@angle, PI*2) / PI*2
  add_input @genes, 4, (@time_alive % 2) and 1 or 0
  add_input @genes, 5, abs(cos @time_alive * 2)
  add_input @genes, 6, abs(sin @time_alive * 10)

  if @trace.Hit
    add_input @genes, 7, 1
    add_input @genes, 8, 1 - @trace.Fraction

    if @trace.hit_entity
      if @trace.is_learner
        add_input @genes, 9, @trace.Entity\GetColor!.r/255
        add_input @genes, 10, @trace.Entity\GetColor!.g/255
        add_input @genes, 11, @trace.Entity\GetColor!.b/255
        add_input @genes, 12, clamp01 @trace.Entity.energy/500
      else
        col = @GetTraceColor @trace
        add_input @genes, 9, col.r/255
        add_input @genes, 10, col.g/255
        add_input @genes, 11, col.b/255
      
      if @trace.Entity.gnutrient
        add_input @genes, 13, @trace.Entity.gnutrient/MAX_NUTR
    else
      add_input @genes, 15, 1

  add_input @genes, 14, clamp01 @energy/800
  add_input @genes, 16, clamp01 #ents.FindInSphere(@GetPos!, 100)/10
  add_input @genes, 17, clamp01 @health/200
  add_input @genes, 18, clamp01 @time_alive/100
  add_input @genes, 19, @sex and 1 or 0

  i = 20

  for sectrace in *@sectraces
    if sectrace.Hit
      add_input @genes, i, 1 - sectrace.Fraction
      if IsValid sectrace.Entity
        if sectrace.Entity\GetClass! == "learner"
          add_input @genes, i+1, (sectrace.Entity\GetColor!.r/255)
          add_input @genes, i+2, (sectrace.Entity\GetColor!.g/255)
          add_input @genes, i+3, (sectrace.Entity\GetColor!.b/255)
        else
          trcolor = @GetTraceColor sectrace
          add_input @genes, i+1, (trcolor.r/255)
          add_input @genes, i+2, (trcolor.g/255)
          add_input @genes, i+3, (trcolor.b/255)
 
    i += 4

  for r in *@random_states
    add_input @genes, i, r
    i += 1

get_gnutrient_from = (ent, a) ->
  if ent.gnutrient == nil or (ent.rejuv and ent.rejuv < CurTime!)
    ent.rejuv = nil
    ent.gnutrient = 200 * clamp (abs sin(CurTime!/250)), 0.3, 1
    ent.started_color = ent.gnutrient

  taken = ent.gnutrient
  ent.gnutrient = max(ent.gnutrient - a, 0)

  z = ent.gnutrient/(ent.started_color or 1)
  ent\SetColor Color z*255, z*255, z*255, z*255

  if ent.gnutrient <= 0 and ent.rejuv == nil
    ent.rejuv = CurTime! + 50

  taken - ent.gnutrient

ENT.TakeEnergy = (amount) =>
  b_amount = @energy
  @energy = max @energy - amount, 0

  b_amount - @energy

ENT.ActOutputs ==>
  angle_0 = get_output @genes, 0
  angle_1 = get_output @genes, 1
  speed = get_output @genes, 2
  asexual_or_sexual = get_output @genes, 3
  generate_energy = get_output @genes, 4
  r = get_output @genes, 5
  g = get_output @genes, 6
  b = get_output @genes, 7
  gather_nutrient = get_output @genes, 8
  give_nutrient = get_output @genes, 9
  take_nutrient = get_output @genes, 10
  @want_to_breed = get_output @genes, 11
  use = get_output @genes, 12
  push = get_output @genes, 13
  pull = get_output @genes, 14
  boost = get_output @genes, 15
  bulk_up = get_output @genes, 16
  create_anutrient = get_output @genes, 17
  create_bnutrient = get_output @genes, 18
  photosynth = get_output @genes, 19
  brake = get_output @genes, 20
  want_to_rep = get_output @genes, 21

  if @bnutrient < 0
    @boost = 0
  else
    @bnutrient -= boost * 0.3

  invers_dis = 1.0 - @trace.Fraction

  @SetColor(Color(r * 255, g * 255, b * 255, 255))

  a_change = (PI/6) * (use-angle_1) * (1-@ScaleNormalized!)
  --print angle_0, angle_1
  with @GetPhysicsObject!
    \AddAngleVelocity Vector 0, a_change, 0
  --print angle_1
  
  s = ((speed + boost) * 55) * (1+@ScaleNormalized!)

  @MoveByAngle s

  @energy -= (speed + boost) * 0.001 * pow(@ScaleNormalized!, 2)
  

  --@gnutrient -= s/300
  
  --with @GetPhysicsObject!
  --  \ApplyForceCenter @GetVelocity! * -brake * \GetMass!

  --if (use > 0.5)
  --  if (@trace.hit_entity)
  --    @trace.Entity\Use @

  if (bulk_up > 0.5 and @anutrient > 0)
    @health += @anutrient
    @anutrient = 0

  if (push > 0.5 and @anutrient > 0)
    if (@trace.hit_entity)
      with @trace.Entity\GetPhysicsObject!
        print "Feshtung"
        \ApplyForceCenter @GetDir! * \GetMass! * invers_dis * 150 * @ScaleNormalized! * (1 - pull)
        @anutrient -= 0.025 * abs(push - pull)
  
  --if (want_to_rep > 0.5 and @energy >= 20)
  --  print "Birth!"
  --  child = @CreateChild!
  --  child = @energy * 0.4
  --  @energy -= @energy * (@sex and 0.4 or 0.7)
    
  if (gather_nutrient > 0.5)
    if @nutrient_delay < CurTime! and @trace.hit_entity and not @trace.is_learner
        --print "Mat: #{@trace.MatType}"
        oi = invers_dis * @ScaleNormalized!
        switch @trace.MatType
          when 68
            --print "Agua"
            @water += get_gnutrient_from @trace.Entity, oi * 3
            @anutrient += get_gnutrient_from @trace.Entity, oi * 1
            --@energy -= gather_nutrient * 0.005
            @nutrient_delay = CurTime!
          else
            @gnutrient += 2 * get_gnutrient_from @trace.Entity, oi * 15 * (1 + (@anutrient * 0.10))
            --@energy -= gather_nutrient * 0.3
            @nutrient_delay = CurTime!

  if (give_nutrient > 0.5 and @gnutrient > 0)
    if @trace.is_learner
      e = @gnutrient * 0.05
      we = @water * 0.05
      @trace.Entity.gnutrient += e
      @trace.Entity.water += we
      @gnutrient -= e
      @water -= we

  if (take_nutrient > 0.5)
    if @trace.is_learner
      with @trace.Entity
        e = @ScaleNormalized! * invers_dis
        .health -= e * 3
        @energy -= e * 0.01

        if .health <= 0
          .health -= 10
          print "SLOMP"
          @EmitSound "ambient/levels/canals/drip#{rand(1, 4)}.wav", 50
          @energy += .energy * 0.3
          @gnutrient += .gnutrient * 0.3
          @anutrient += .anutrient * 0.3
          @bnutrient += .bnutrient * 0.3
          @water += .water * 0.3
          .energy -= .energy * 0.35
          .gnutrient -= .gnutrient * 0.35
          .anutrient -= .anutrient * 0.35
          .bnutrient -= .bnutrient * 0.35
          .water -= .water * 0.35

  if (generate_energy > 0.5)  
    if (photosynth > 0.5 and @water > 0 and @gnutrient > 0)
      wloss = @water * 0.1
      gloss = @gnutrient * 0.1
      --print gloss, wloss
      e = max(0, 100 * wloss * gloss * (abs (sin CurTime!/25)) * (1 + (@GetColor!.g/255)) * @ScaleNormalized!)
      @water -= wloss
      @energy += e
      @gnutrient -= gloss
      if e > 1
        print "photosynth: #{e}, #{(abs (sin CurTime!/25))}, #{@water}, #{@gnutrient}"
    else
      e = (@gnutrient * generate_energy * 0.1)
      @energy += e * 1.2
      --print "Energy: #{@energy}, e: #{e}"
      @gnutrient = max(@gnutrient - e, 0) 
  

  --if (asexual_or_sexual > 0.5 and rand! < 0.1 and @repcounter < CurTime!)
  --  if (@want_to_breed > 0.5 and @sex and @energy >= 213)
  --    if @trace.is_learner and @trace.Entity.sex != @sex and (@trace.Entity.want_to_breed or 0) > 0.5
  --      --  print "Birth!"
  --      child = @CreateChild!
  --      crossbreed child.genes, @trace.Entity.genes
  --      child.energy = @energy * 0.3
  --      @energy -= @energy * 0.3
  --      print "crossbreed! Birth!"
  --      @already_bread = true

  if @energy > (@ScaleNormalized! * 10) * 2 and @repcounter < CurTime! and want_to_rep > 0.5
    print (@ScaleNormalized! * 10), "riu"
    child = @CreateChild!
    child\EnableConstraints true

    child.energy = (@ScaleNormalized! * 10)
    @energy -= (@ScaleNormalized! * 10) * 1.2
    @repcounter = CurTime! + (@ScaleNormalized! * 5)

  if (@gnutrient >= 5)
    e = abs -(cos (PI * @time_alive) / 50) * create_anutrient * 0.001
    --print "transfer A #{e}"
    @anutrient += e
    @gnutrient -= e

  if (@gnutrient >= 5)
    e = create_bnutrient * @gnutrient * 0.001
    --print "transfer B #{e}"
    @bnutrient += e
    @gnutrient -= e

  @gnutrient = max(0, @gnutrient)
  @anutrient = max(0, @anutrient)
  @bnutrient = max(0, @bnutrient)
  @water = max(0, @water)

     

ENT.GetDir = (offset = 0) =>
  --Vector cos(@angle + offset), sin(@angle + offset), 0 
  a = @GetForward!
  a\Rotate Angle 0, offset*30, 0
  a

ENT.Trace = =>
  @trace = util.TraceLine {
    start: @GetPos!
    endpos: @GetPos! + @GetDir! * 200 * @ScaleNormalized!
    filter: (ent) ->
      ent != @ 
  }

  debugoverlay.Line @GetPos!, @GetPos! + @GetDir! * 200 * @ScaleNormalized!, 0.1, Color @trace.Fraction*255, @trace.Fraction*255, @trace.Fraction*255

  @trace.is_learner = false
  @trace.hit_entity = false

  if IsValid @trace.Entity
    @trace.is_learner = @trace.Entity\GetClass! == "learner"
    @trace.hit_entity = true

ENT.SecondaryTrace = (i, ang_off) =>
  @sectraces[i] = util.TraceLine {
    start: @GetPos!
    endpos: @GetPos! + @GetDir(ang_off) * 200 * @ScaleNormalized!
    filter: (ent) ->
      ent != @ 
  }

  debugoverlay.Line @GetPos!, @GetPos! + @GetDir(ang_off) * 200 * @scale/2, 0.1, Color @sectraces[i].Fraction*255, @sectraces[i].Fraction*255, @sectraces[i].Fraction*255


ENT.CreateChild ==>
  new_child = ents.Create "learner"
  with new_child
    new_child\Initialize!
    new_child.genes = nil
    new_child.gsystem = nil
    new_child\SetPos(@GetPos! + @GetDir! * -15)
    new_child.genes = table.Copy @genes
    new_child.gsystem = table.Copy @gsystem
    new_child\SetAngles new_child\GetPhysicsObject!\RotateAroundAxis (Vector 0, 1, 0), (rand!*360)
    --mutate_graphsystem new_child.gsystem, new_child.genes.mr, new_child.genes
    mutate_genes new_child.genes
    new_child.parent = @
    --new_child.genes.network = CreateNetworkFromGraph new_child.gsystem, new_child.gsystem[1], 1
    ResetWeights new_child.genes
    
    new_child.genes.generation = @genes.generation + 1
    --new_child.gsystem.generation = (@gsystem.generation or 0) + 1
    print "MR: #{new_child.genes.mr}, Gen: #{new_child.genes.generation}"
    new_child\Spawn!
    return new_child

ENT.MoveByAngle = (amount) =>
  with @GetPhysicsObject!
    \ApplyForceCenter \GetMass! * @GetDir! * amount

ENT.Think ==>
  if @energy <= 0 or @health <= -100
    @Remove!

    return 

  --if @gsystem == nil
  --  @gsystem = CreateGraphSystem!

  --if @gsystem.name == nil
  --  @gsystem.name = string.char(rand(64, 100), rand(64, 100))

  if @genes == nil
    @genes = CreateGenes 250
    --@genes.network = CreateNetworkFromGraph @gsystem, @gsystem[1], 1
  
  if @scale == nil
    @scale = max 0.3, @genes.normal_values.scale * S_MUL
    @Scale!
    @health = pow(@ScaleNormalized!, 5) * 200

    if @parent and false
      @EnableConstraints true
      constraint.Rope @parent, @, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 5, 0, 0, 2, "", false, Color 0, 0, 0

  --if not @inited_genes
    --@inited_genes = true
    --@SetByGenes!
    --@Activate!

  @energy -= pow(@ScaleNormalized!*0.001, 2 - (clamp01 @water/10)) 

  --if ((@time_alive % 4) == 0)
  
  @Trace!
  @SecondaryTrace 1, -0.70
  @SecondaryTrace 2, -0.30
  @SecondaryTrace 3, 0.30
  @SecondaryTrace 4, 0.70

  reset_neurons @genes

  @AddInputs!

  update_all_weights @genes

  for i = 1, 3
    run_all_neurons @genes

  @ActOutputs!

  @time_alive += 1

  @previous_pos = @GetPos!

  @NextThink( CurTime! + 0.10 )
  return true

ENT.TakePhysicsDamage = =>