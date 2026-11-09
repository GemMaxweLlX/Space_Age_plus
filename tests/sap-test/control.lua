-- Автотесты Space Age+. Запускаются через tools/run-tests.sh (headless Factorio, режим benchmark).
-- Каждая проверка пишет в лог "SAP-TEST PASS <имя>" или "SAP-TEST FAIL <имя>: <подробности>".

local results = {}

local function check(name, ok, details)
  if ok then
    log("SAP-TEST PASS " .. name)
  else
    log("SAP-TEST FAIL " .. name .. ": " .. tostring(details))
  end
  results[#results + 1] = ok
end

local function techtree_on()
  return settings.startup["sap-techtree-enabled"].value
end

local steps = {}

-- Тик 10: проверки прототипов и начального состояния ------------------------------
steps[10] = function()
  local force = game.forces.player
  for _, name in pairs({ "sap-oxygen-generator", "sap-oxygen-distributor", "sap-atmospheric-collector",
                         "sap-telescope", "sap-storm-stabilizer", "sap-decipherer", "sap-logic-lab",
                         "sap-data-wreck", "sap-fallen-debris" }) do
    check("entity " .. name, prototypes.entity[name] ~= nil)
  end
  check("planet echaris", game.planets["echaris"] ~= nil)
  check("mk1 hidden at start", not force.technologies["sap-satellite-mk1"].enabled)
  check("echaris discovery hidden", not force.technologies["sap-planet-discovery-echaris"].enabled
    and not force.technologies["sap-planet-discovery-echaris"].visible_when_disabled)

  if techtree_on() then
    check("techtree: logistics-2 hidden", not force.technologies["logistics-2"].enabled)
    check("techtree: military hidden", not force.technologies["military"].enabled)
    check("techtree: automation visible", force.technologies["automation"].enabled)
    check("techtree: decipherer visible", force.technologies["sap-decipherer"].enabled)
    local wrecks = game.surfaces.nauvis.count_entities_filtered({ name = "sap-starting-wreck" })
    check("techtree: starting wreck placed", wrecks == 1, wrecks)
  end
  if settings.startup["sap-exploration-vanilla-planets"].value then
    check("exploration: vulcanus discovery hidden", not force.technologies["planet-discovery-vulcanus"].enabled)
  end
end

-- Тик 20: телескоп ----------------------------------------------------------------
steps[20] = function()
  local force = game.forces.player
  local surface = game.surfaces.nauvis
  local pos = surface.find_non_colliding_position("sap-telescope", { 40, 40 }, 50, 1)
  surface.create_entity({ name = "sap-telescope", position = pos, force = force, raise_built = true })
  check("telescope unlocks mk1", force.technologies["sap-satellite-mk1"].enabled)
end

-- Тик 30: Echaris — поверхность, буря, стабилизатор, дроны -----------------------
steps[30] = function()
  local surface = game.planets["echaris"].create_surface()
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  check("echaris: map generated", surface.is_chunk_generated({ 2, 2 }))
  local effect = surface.global_effect
  check("storm: global effect set", effect ~= nil and effect.speed ~= nil and effect.speed < 0, serpent.line(effect))
  local origin = surface.find_non_colliding_position("sap-storm-stabilizer", { 0, 0 }, 64, 1)
  storage.stab_origin = origin
  local stab = surface.create_entity({ name = "sap-storm-stabilizer", position = origin, force = "player",
                                       raise_built = true })
  local inv = stab and stab.get_module_inventory()
  check("storm: stabilizer gets module", inv ~= nil and not inv.is_empty(),
        inv and serpent.line(inv.get_contents()))
  storage.robot_far = surface.create_entity({ name = "construction-robot", position = { 200, 200 }, force = "player" })
  storage.robot_near = surface.create_entity({ name = "construction-robot", position = { origin.x + 2, origin.y + 2 }, force = "player" })
end

-- Тик 30: мусор — платформа и выброс --------------------------------------------
steps[31] = function()
  local force = game.forces.player
  force.unlock_space_location("nauvis")
  local platform = force.create_space_platform({ name = "sap-test", planet = "nauvis",
                                                 starter_pack = "space-platform-starter-pack" })
  storage.platform = platform
  check("debris: platform created", platform ~= nil)
  if platform then platform.apply_starter_pack() end
end

steps[40] = function()
  local platform = storage.platform
  if not (platform and platform.valid and platform.hub) then
    check("debris: platform hub", false, "no hub")
    return
  end
  local hub = platform.hub.position
  for i = 1, 40 do
    platform.eject_item({ name = "iron-plate" }, { hub.x + 3, hub.y + i % 5 }, { 0.1, 0 })
  end
  check("debris: items ejected", #platform.ejected_items > 0, #platform.ejected_items)
end

-- Тики 50+: ракеты со спутниками -----------------------------------------------
-- 10 спутников 1 поколения (столько нужно без хардкора), затем спутник 2 поколения.
steps[50] = function()
  local surface = game.surfaces.nauvis
  local pos = surface.find_non_colliding_position("rocket-silo", { -80, -80 }, 100, 1)
  local silo = surface.create_entity({ name = "rocket-silo", position = pos, force = "player" })
  surface.create_entity({ name = "electric-energy-interface", position = { pos.x + 7, pos.y }, force = "player" })
  surface.create_entity({ name = "substation", position = { pos.x + 5, pos.y + 3 }, force = "player" })
  storage.silo = silo
  storage.launched = 0
  check("silo built", silo ~= nil)
end

local MK1_LAUNCHES = 10

local function try_launch()
  local silo = storage.silo
  if not (silo and silo.valid) or storage.launched > MK1_LAUNCHES then return end
  if silo.rocket_silo_status ~= defines.rocket_silo_status.rocket_ready then
    silo.rocket_parts = silo.prototype.rocket_parts_required
    return
  end
  local item = storage.launched < MK1_LAUNCHES and "sap-satellite-mk1" or "sap-satellite-mk2"
  silo.get_inventory(defines.inventory.rocket_silo_rocket).insert({ name = item, count = 1 })
  if silo.launch_rocket({ type = defines.cargo_destination.orbit }) then
    storage.launched = storage.launched + 1
    log("SAP-TEST INFO launched " .. item .. " #" .. storage.launched)
    if storage.launched == MK1_LAUNCHES then storage.mk1_done_tick = game.tick end
  end
end

local function discovery_states()
  local force = game.forces.player
  local found, scouted = 0, 0
  local names = { "sap-planet-discovery-echaris" }
  if settings.startup["sap-exploration-vanilla-planets"].value then
    for _, p in pairs({ "vulcanus", "fulgora", "gleba", "aquilo" }) do names[#names + 1] = "planet-discovery-" .. p end
  end
  for _, name in pairs(names) do
    local t = force.technologies[name]
    if t.visible_when_disabled or t.enabled then found = found + 1 end
    if t.enabled then scouted = scouted + 1 end
  end
  return found, scouted
end

-- Тик 60: кислород и дешифратор (без игрока — только то, на что опирается логика) -----
steps[60] = function()
  local surface = game.surfaces.nauvis
  local character = surface.create_entity({ name = "character", position = { 20, -20 }, force = "player" })
  local armor_inv = character.get_inventory(defines.inventory.character_armor)
  armor_inv.insert({ name = "modular-armor", count = 1 })
  local grid = armor_inv[1].grid
  check("oxygen: modular armor has grid", grid ~= nil)
  if grid then
    local placed = grid.put({ name = "sap-oxygen-tank-equipment" })
    check("oxygen: tank fits in grid", placed ~= nil)
    check("oxygen: grid counts tank", grid.count("sap-oxygen-tank-equipment") == 1,
          grid.count("sap-oxygen-tank-equipment"))
  end
  check("oxygen: mod-data planets", prototypes.mod_data["sap-oxygen-planets"].data["echaris"] ~= nil)

  local pos = surface.find_non_colliding_position("sap-decipherer", { 30, -30 }, 30, 1)
  local decipherer = surface.create_entity({ name = "sap-decipherer", position = pos, force = "player" })
  local inv = decipherer.get_inventory(defines.inventory.chest)
  inv.insert({ name = "sap-data-card-logistics", count = 1, quality = "rare" })
  inv.insert({ name = "automation-science-pack", count = 10 })
  inv.insert({ name = "logistic-science-pack", count = 10 })
  local quality
  for _, stack in pairs(inv.get_contents()) do
    if stack.name == "sap-data-card-logistics" then quality = stack.quality end
  end
  check("decipherer: card keeps quality", quality == "rare" or (type(quality) == "table" and quality.name == "rare"),
        serpent.line(quality))
end

-- Тик 70: обломки с картами данных ---------------------------------------------
steps[70] = function()
  local wrecks = 0
  for _, name in pairs({ "nauvis", "echaris" }) do
    wrecks = wrecks + game.surfaces[name].count_entities_filtered({ name = "sap-data-wreck" })
  end
  check("techtree: data wrecks generated", not techtree_on() or wrecks > 0, wrecks)
end

-- Конец ---------------------------------------------------------------------------
-- Мусор проверяем раньше: куски медленно пролетают мимо и улетают с карты.
steps[2900] = function()
  local platform = storage.platform
  if platform and platform.valid then
    local chunks = platform.find_asteroid_chunks_filtered({ name = "sap-debris-metal" })
    check("debris: chunks came back", #chunks > 0, #chunks)
  end
end

steps[29000] = function()
  local force = game.forces.player
  local robot_far, robot_near = storage.robot_far, storage.robot_near
  check("storm: far robot damaged", not (robot_far and robot_far.valid)
        or robot_far.health < robot_far.max_health, robot_far and robot_far.valid and robot_far.health)
  -- Молнии бури (как на Фульгоре) могут попасть и в робота у стабилизатора — это не урон бури.
  check("storm: near robot not drained", robot_near == nil or not robot_near.valid
        or robot_near.energy > 0, robot_near and robot_near.valid and robot_near.energy)
  if robot_near and robot_near.valid then log("SAP-TEST INFO near robot health " .. robot_near.health .. "/" .. robot_near.max_health) end
  check("storm: near robot alive or hit by lightning only", robot_near and robot_near.valid,
        "robot near stabilizer destroyed")


  check("satellites: all launched", storage.launched == MK1_LAUNCHES + 1, storage.launched)
  check("satellites: mk2 tech enabled after 10", force.technologies["sap-satellite-mk2"].enabled)
  local found, scouted = discovery_states()
  check("satellites: mk1 found something", found >= 1, found)
  check("satellites: mk2 scouted one", scouted == 1, scouted)

  local launches = 0
  for _, r in pairs(results) do if not r then launches = launches + 1 end end
  log("SAP-TEST DONE failures=" .. launches)
end

script.on_event(defines.events.on_tick, function(event)
  if event.tick > 50 and event.tick % 30 == 0 then
    local ok, err = pcall(try_launch)
    if not ok then check("launch", false, err) end
  end
  local step = steps[event.tick]
  if step then
    local ok, err = pcall(step)
    if not ok then check("step " .. event.tick, false, err) end
  end
end)

script.on_event(defines.events.on_rocket_launch_ordered, function(event)
  log("SAP-TEST INFO rocket launch ordered, pod=" .. tostring(event.rocket.attached_cargo_pod ~= nil))
end)
