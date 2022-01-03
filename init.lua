AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("neuralnetwork.lua")
include("graph.lua")
local LEARNING_RATE = 0.01
local DISCOUNT = 0.95
local MAX_NUTR = 3500
local S_MUL = 2
ENT.Initialize = function(self, new_genes)
  self:SetModel("models/props_c17/clock01.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  do
    local _with_0 = self:GetPhysicsObject()
    if _with_0:IsValid() then
      _with_0:Wake()
    end
  end
  self.angle = rand() * PI * 2
  self.energy = 10
  self.water = 0
  self.health = 100.0
  self.time_alive = 0
  self.previous_pos = self:GetPos()
  self.gnutrient = 0.0
  self.anutrient = 0.0
  self.bnutrient = 0.0
  self.nutrient_delay = 0.0
  self.inited_genes = false
  self.sectraces = { }
  self.random_states = { }
  self.sex = randb()
  self.reset_already = false
  self.mr = 5.0
  self.repcounter = 0
  for i = 1, RAND_STATES_AMOUNT do
    self.random_states[i] = 0
  end
  self.random_states[rand(1, RAND_STATES_AMOUNT)] = 1
end
ENT.ChangeInPos = function(self)
  return self.previous_pos - self:GetPos()
end
ENT.Scale = function(self)
  self:SetModelScale(self.scale)
  return self:Activate()
end
ENT.ScaleNormalized = function(self)
  return self.scale / S_MUL
end
ENT.GetTraceColor = function(self, mattype)
  local _exp_0 = mattype
  if 68 == _exp_0 then
    return Color(255, 0, 0)
  else
    return Color(0, 255, 255)
  end
end
ENT.AddInputs = function(self)
  add_input(self.genes, 0, rand())
  add_input(self.genes, 1, clamp01(abs(self:ChangeInPos().x / 25)))
  add_input(self.genes, 2, clamp01(abs(self:ChangeInPos().y / 25)))
  add_input(self.genes, 3, fmod(self.angle, PI * 2) / PI * 2)
  add_input(self.genes, 4, (self.time_alive % 2) and 1 or 0)
  add_input(self.genes, 5, abs(cos(self.time_alive * 2)))
  add_input(self.genes, 6, abs(sin(self.time_alive * 10)))
  if self.trace.Hit then
    add_input(self.genes, 7, 1)
    add_input(self.genes, 8, 1 - self.trace.Fraction)
    if self.trace.hit_entity then
      if self.trace.is_learner then
        add_input(self.genes, 9, self.trace.Entity:GetColor().r / 255)
        add_input(self.genes, 10, self.trace.Entity:GetColor().g / 255)
        add_input(self.genes, 11, self.trace.Entity:GetColor().b / 255)
        add_input(self.genes, 12, clamp01(self.trace.Entity.energy / 500))
      else
        local col = self:GetTraceColor(self.trace)
        add_input(self.genes, 9, col.r / 255)
        add_input(self.genes, 10, col.g / 255)
        add_input(self.genes, 11, col.b / 255)
      end
      if self.trace.Entity.gnutrient then
        add_input(self.genes, 13, self.trace.Entity.gnutrient / MAX_NUTR)
      end
    else
      add_input(self.genes, 15, 1)
    end
  end
  add_input(self.genes, 14, clamp01(self.energy / 800))
  add_input(self.genes, 16, clamp01(#ents.FindInSphere(self:GetPos(), 100) / 10))
  add_input(self.genes, 17, clamp01(self.health / 200))
  add_input(self.genes, 18, clamp01(self.time_alive / 100))
  add_input(self.genes, 19, self.sex and 1 or 0)
  local i = 20
  local _list_0 = self.sectraces
  for _index_0 = 1, #_list_0 do
    local sectrace = _list_0[_index_0]
    if sectrace.Hit then
      add_input(self.genes, i, 1 - sectrace.Fraction)
      if IsValid(sectrace.Entity) then
        if sectrace.Entity:GetClass() == "learner" then
          add_input(self.genes, i + 1, (sectrace.Entity:GetColor().r / 255))
          add_input(self.genes, i + 2, (sectrace.Entity:GetColor().g / 255))
          add_input(self.genes, i + 3, (sectrace.Entity:GetColor().b / 255))
        else
          local trcolor = self:GetTraceColor(sectrace)
          add_input(self.genes, i + 1, (trcolor.r / 255))
          add_input(self.genes, i + 2, (trcolor.g / 255))
          add_input(self.genes, i + 3, (trcolor.b / 255))
        end
      end
    end
    i = i + 4
  end
  local _list_1 = self.random_states
  for _index_0 = 1, #_list_1 do
    local r = _list_1[_index_0]
    add_input(self.genes, i, r)
    i = i + 1
  end
end
local get_gnutrient_from
get_gnutrient_from = function(ent, a)
  if ent.gnutrient == nil or (ent.rejuv and ent.rejuv < CurTime()) then
    ent.rejuv = nil
    ent.gnutrient = 200 * clamp((abs(sin(CurTime() / 250))), 0.3, 1)
    ent.started_color = ent.gnutrient
  end
  local taken = ent.gnutrient
  ent.gnutrient = max(ent.gnutrient - a, 0)
  local z = ent.gnutrient / (ent.started_color or 1)
  ent:SetColor(Color(z * 255, z * 255, z * 255, z * 255))
  if ent.gnutrient <= 0 and ent.rejuv == nil then
    ent.rejuv = CurTime() + 50
  end
  return taken - ent.gnutrient
end
ENT.TakeEnergy = function(self, amount)
  local b_amount = self.energy
  self.energy = max(self.energy - amount, 0)
  return b_amount - self.energy
end
ENT.ActOutputs = function(self)
  local angle_0 = get_output(self.genes, 0)
  local angle_1 = get_output(self.genes, 1)
  local speed = get_output(self.genes, 2)
  local asexual_or_sexual = get_output(self.genes, 3)
  local generate_energy = get_output(self.genes, 4)
  local r = get_output(self.genes, 5)
  local g = get_output(self.genes, 6)
  local b = get_output(self.genes, 7)
  local gather_nutrient = get_output(self.genes, 8)
  local give_nutrient = get_output(self.genes, 9)
  local take_nutrient = get_output(self.genes, 10)
  self.want_to_breed = get_output(self.genes, 11)
  local use = get_output(self.genes, 12)
  local push = get_output(self.genes, 13)
  local pull = get_output(self.genes, 14)
  local boost = get_output(self.genes, 15)
  local bulk_up = get_output(self.genes, 16)
  local create_anutrient = get_output(self.genes, 17)
  local create_bnutrient = get_output(self.genes, 18)
  local photosynth = get_output(self.genes, 19)
  local brake = get_output(self.genes, 20)
  local want_to_rep = get_output(self.genes, 21)
  if self.bnutrient < 0 then
    self.boost = 0
  else
    self.bnutrient = self.bnutrient - (boost * 0.3)
  end
  local invers_dis = 1.0 - self.trace.Fraction
  self:SetColor(Color(r * 255, g * 255, b * 255, 255))
  local a_change = (PI / 6) * (use - angle_1) * (1 - self:ScaleNormalized())
  do
    local _with_0 = self:GetPhysicsObject()
    _with_0:AddAngleVelocity(Vector(0, a_change, 0))
  end
  local s = ((speed + boost) * 55) * (1 + self:ScaleNormalized())
  self:MoveByAngle(s)
  self.energy = self.energy - ((speed + boost) * 0.001 * pow(self:ScaleNormalized(), 2))
  if (bulk_up > 0.5 and self.anutrient > 0) then
    self.health = self.health + self.anutrient
    self.anutrient = 0
  end
  if (push > 0.5 and self.anutrient > 0) then
    if (self.trace.hit_entity) then
      do
        local _with_0 = self.trace.Entity:GetPhysicsObject()
        print("Feshtung")
        _with_0:ApplyForceCenter(self:GetDir() * _with_0:GetMass() * invers_dis * 150 * self:ScaleNormalized() * (1 - pull))
        self.anutrient = self.anutrient - (0.025 * abs(push - pull))
      end
    end
  end
  if (gather_nutrient > 0.5) then
    if self.nutrient_delay < CurTime() and self.trace.hit_entity and not self.trace.is_learner then
      local oi = invers_dis * self:ScaleNormalized()
      local _exp_0 = self.trace.MatType
      if 68 == _exp_0 then
        self.water = self.water + get_gnutrient_from(self.trace.Entity, oi * 3)
        self.anutrient = self.anutrient + get_gnutrient_from(self.trace.Entity, oi * 1)
        self.nutrient_delay = CurTime()
      else
        self.gnutrient = self.gnutrient + (2 * get_gnutrient_from(self.trace.Entity, oi * 15 * (1 + (self.anutrient * 0.10))))
        self.nutrient_delay = CurTime()
      end
    end
  end
  if (give_nutrient > 0.5 and self.gnutrient > 0) then
    if self.trace.is_learner then
      local e = self.gnutrient * 0.05
      local we = self.water * 0.05
      self.trace.Entity.gnutrient = self.trace.Entity.gnutrient + e
      self.trace.Entity.water = self.trace.Entity.water + we
      self.gnutrient = self.gnutrient - e
      self.water = self.water - we
    end
  end
  if (take_nutrient > 0.5) then
    if self.trace.is_learner then
      do
        local _with_0 = self.trace.Entity
        local e = self:ScaleNormalized() * invers_dis
        _with_0.health = _with_0.health - (e * 3)
        self.energy = self.energy - (e * 0.01)
        if _with_0.health <= 0 then
          _with_0.health = _with_0.health - 10
          print("SLOMP")
          self:EmitSound("ambient/levels/canals/drip" .. tostring(rand(1, 4)) .. ".wav", 50)
          self.energy = self.energy + (_with_0.energy * 0.3)
          self.gnutrient = self.gnutrient + (_with_0.gnutrient * 0.3)
          self.anutrient = self.anutrient + (_with_0.anutrient * 0.3)
          self.bnutrient = self.bnutrient + (_with_0.bnutrient * 0.3)
          self.water = self.water + (_with_0.water * 0.3)
          _with_0.energy = _with_0.energy - (_with_0.energy * 0.35)
          _with_0.gnutrient = _with_0.gnutrient - (_with_0.gnutrient * 0.35)
          _with_0.anutrient = _with_0.anutrient - (_with_0.anutrient * 0.35)
          _with_0.bnutrient = _with_0.bnutrient - (_with_0.bnutrient * 0.35)
          _with_0.water = _with_0.water - (_with_0.water * 0.35)
        end
      end
    end
  end
  if (generate_energy > 0.5) then
    if (photosynth > 0.5 and self.water > 0 and self.gnutrient > 0) then
      local wloss = self.water * 0.1
      local gloss = self.gnutrient * 0.1
      local e = max(0, 100 * wloss * gloss * (abs((sin(CurTime() / 25)))) * (1 + (self:GetColor().g / 255)) * self:ScaleNormalized())
      self.water = self.water - wloss
      self.energy = self.energy + e
      self.gnutrient = self.gnutrient - gloss
      if e > 1 then
        print("photosynth: " .. tostring(e) .. ", " .. tostring((abs((sin(CurTime() / 25))))) .. ", " .. tostring(self.water) .. ", " .. tostring(self.gnutrient))
      end
    else
      local e = (self.gnutrient * generate_energy * 0.1)
      self.energy = self.energy + (e * 1.2)
      self.gnutrient = max(self.gnutrient - e, 0)
    end
  end
  if self.energy > (self:ScaleNormalized() * 10) * 2 and self.repcounter < CurTime() and want_to_rep > 0.5 then
    print((self:ScaleNormalized() * 10), "riu")
    local child = self:CreateChild()
    child:EnableConstraints(true)
    child.energy = (self:ScaleNormalized() * 10)
    self.energy = self.energy - ((self:ScaleNormalized() * 10) * 1.2)
    self.repcounter = CurTime() + (self:ScaleNormalized() * 5)
  end
  if (self.gnutrient >= 5) then
    local e = abs(-(cos((PI * self.time_alive) / 50)) * create_anutrient * 0.001)
    self.anutrient = self.anutrient + e
    self.gnutrient = self.gnutrient - e
  end
  if (self.gnutrient >= 5) then
    local e = create_bnutrient * self.gnutrient * 0.001
    self.bnutrient = self.bnutrient + e
    self.gnutrient = self.gnutrient - e
  end
  self.gnutrient = max(0, self.gnutrient)
  self.anutrient = max(0, self.anutrient)
  self.bnutrient = max(0, self.bnutrient)
  self.water = max(0, self.water)
end
ENT.GetDir = function(self, offset)
  if offset == nil then
    offset = 0
  end
  local a = self:GetForward()
  a:Rotate(Angle(0, offset * 30, 0))
  return a
end
ENT.Trace = function(self)
  self.trace = util.TraceLine({
    start = self:GetPos(),
    endpos = self:GetPos() + self:GetDir() * 200 * self:ScaleNormalized(),
    filter = function(ent)
      return ent ~= self
    end
  })
  debugoverlay.Line(self:GetPos(), self:GetPos() + self:GetDir() * 200 * self:ScaleNormalized(), 0.1, Color(self.trace.Fraction * 255, self.trace.Fraction * 255, self.trace.Fraction * 255))
  self.trace.is_learner = false
  self.trace.hit_entity = false
  if IsValid(self.trace.Entity) then
    self.trace.is_learner = self.trace.Entity:GetClass() == "learner"
    self.trace.hit_entity = true
  end
end
ENT.SecondaryTrace = function(self, i, ang_off)
  self.sectraces[i] = util.TraceLine({
    start = self:GetPos(),
    endpos = self:GetPos() + self:GetDir(ang_off) * 200 * self:ScaleNormalized(),
    filter = function(ent)
      return ent ~= self
    end
  })
  return debugoverlay.Line(self:GetPos(), self:GetPos() + self:GetDir(ang_off) * 200 * self.scale / 2, 0.1, Color(self.sectraces[i].Fraction * 255, self.sectraces[i].Fraction * 255, self.sectraces[i].Fraction * 255))
end
ENT.CreateChild = function(self)
  local new_child = ents.Create("learner")
  do
    local _with_0 = new_child
    new_child:Initialize()
    new_child.genes = nil
    new_child.gsystem = nil
    new_child:SetPos(self:GetPos() + self:GetDir() * -15)
    new_child.genes = table.Copy(self.genes)
    new_child.gsystem = table.Copy(self.gsystem)
    new_child:SetAngles(new_child:GetPhysicsObject():RotateAroundAxis((Vector(0, 1, 0)), (rand() * 360)))
    mutate_genes(new_child.genes)
    new_child.parent = self
    ResetWeights(new_child.genes)
    new_child.genes.generation = self.genes.generation + 1
    print("MR: " .. tostring(new_child.genes.mr) .. ", Gen: " .. tostring(new_child.genes.generation))
    new_child:Spawn()
    return new_child
  end
end
ENT.MoveByAngle = function(self, amount)
  do
    local _with_0 = self:GetPhysicsObject()
    _with_0:ApplyForceCenter(_with_0:GetMass() * self:GetDir() * amount)
    return _with_0
  end
end
ENT.Think = function(self)
  if self.energy <= 0 or self.health <= -100 then
    self:Remove()
    return 
  end
  if self.genes == nil then
    self.genes = CreateGenes(250)
  end
  if self.scale == nil then
    self.scale = max(0.3, self.genes.normal_values.scale * S_MUL)
    self:Scale()
    self.health = pow(self:ScaleNormalized(), 5) * 200
    if self.parent and false then
      self:EnableConstraints(true)
      constraint.Rope(self.parent, self, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 5, 0, 0, 2, "", false, Color(0, 0, 0))
    end
  end
  self.energy = self.energy - pow(self:ScaleNormalized() * 0.001, 2 - (clamp01(self.water / 10)))
  self:Trace()
  self:SecondaryTrace(1, -0.70)
  self:SecondaryTrace(2, -0.30)
  self:SecondaryTrace(3, 0.30)
  self:SecondaryTrace(4, 0.70)
  reset_neurons(self.genes)
  self:AddInputs()
  update_all_weights(self.genes)
  for i = 1, 3 do
    run_all_neurons(self.genes)
  end
  self:ActOutputs()
  self.time_alive = self.time_alive + 1
  self.previous_pos = self:GetPos()
  self:NextThink(CurTime() + 0.10)
  return true
end
ENT.TakePhysicsDamage = function(self) end
