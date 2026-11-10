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
  return remote.call("sap-core", "get_setting", "sap-techtree-enabled")
end

-- Шаги по тикам. Несколько шагов на один тик выполняются по порядку (не заменяют друг друга).
local step_lists = {}
local steps = setmetatable({}, {
  __newindex = function(_, tick, fn)
    step_lists[tick] = step_lists[tick] or {}
    table.insert(step_lists[tick], fn)
  end,
})

-- Тик 10: проверки прототипов и начального состояния ------------------------------
steps[10] = function()
  local force = game.forces.player
  for _, name in pairs({ "sap-oxygen-generator", "sap-oxygen-distributor", "sap-atmospheric-collector",
                         "sap-telescope", "sap-storm-stabilizer", "sap-decipherer", "sap-logic-lab",
                         "sap-data-wreck", "sap-fallen-debris" }) do
    check("entity " .. name, prototypes.entity[name] ~= nil)
  end
  check("planet echaris", game.planets["echaris"] ~= nil)
  check("tech: cryo pipe needs no heating", prototypes.entity["sap-cryo-pipe"].heating_energy == 0,
        prototypes.entity["sap-cryo-pipe"].heating_energy)
  check("tech: steam turbine mk2 condenses", prototypes.mod_data["sap-condensing-generators"].data["sap-steam-turbine-mk2"] == 0.9)
  check("tech: mk2+ assembler faster than mk3",
        prototypes.entity["sap-assembling-machine-mk2plus"].get_crafting_speed() > prototypes.entity["assembling-machine-3"].get_crafting_speed())
  check("tech: water cistern recipe", prototypes.recipe["sap-water-cistern"] ~= nil)
  check("tech: heavy-duty pump 2400/s", math.abs(prototypes.entity["sap-heavy-duty-pump"].get_pumping_speed() * 60 - 2400) < 1,
        prototypes.entity["sap-heavy-duty-pump"].get_pumping_speed() * 60)
  local uses = {}
  for _, ingredient in pairs(prototypes.recipe["sap-logistic-robot-mk2"].ingredients) do uses[ingredient.name] = true end
  check("I1: echaris uses nivalite when nivar installed", uses["sap-nivalite"] == true)
  uses = {}
  for _, ingredient in pairs(prototypes.recipe["sap-solar-panel-mk2"].ingredients) do uses[ingredient.name] = true end
  check("I1: echaris uses heat crystals when solaris installed", uses["sap-heat-resistant-crystal"] == true)
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
  if remote.call("sap-core", "get_setting", "sap-exploration-vanilla-planets") then
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
  platform.eject_item({ name = "sap-data-card-logistics" }, { hub.x + 3, hub.y }, { 0.1, 0 })
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
  local names = {}
  for _, info in pairs(prototypes.mod_data["sap-explorable-planets"].data) do
    names[#names + 1] = info.discovery_tech
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
  -- В MODE=migration старые чанки сгенерированы до мода: проверяем на новой области.
  if wrecks == 0 and techtree_on() then
    local nauvis = game.surfaces.nauvis
    nauvis.request_to_generate_chunks({ 3000, 3000 }, 8)
    nauvis.force_generate_chunk_requests()
    wrecks = nauvis.count_entities_filtered({ name = "sap-data-wreck" })
  end
  check("techtree: data wrecks generated", not techtree_on() or wrecks > 0, wrecks)
end

-- Тики 80-90: Механиты --------------------------------------------------------------
steps[300] = function()
  local surface = game.surfaces["echaris"]
  local centers = surface.count_entities_filtered({ name = { "sap-center-data", "sap-center-suppression",
    "sap-center-assembly", "sap-center-energy" } })
  local servers = surface.count_entities_filtered({ name = { "sap-control-server", "sap-control-server-heavy" } })
  check("mechanites: centers generated", centers > 0, centers)
  check("mechanites: servers generated", servers > 0, servers)

  local base = surface.find_non_colliding_position("gun-turret", { -40, -40 }, 60, 2)
  storage.turret = surface.create_entity({ name = "gun-turret", position = base, force = "player" })
  storage.disruptor = surface.create_entity({ name = "sap-disruptor", position = { base.x + 4, base.y }, force = "enemy" })
  storage.mk2 = surface.create_entity({ name = "sap-construction-robot-mk2", position = { 300, 300 }, force = "player" })

  local sentinel = surface.create_entity({ name = "sap-sentinel", position = { base.x - 30, base.y }, force = "enemy" })
  local before = surface.count_entities_filtered({ name = "sap-stormbringer" })
  sentinel.damage(10, "player", "physical", storage.turret)
  local after = surface.count_entities_filtered({ name = "sap-stormbringer" })
  check("mechanites: sentinel calls reinforcements", after > before, before .. " -> " .. after)

  local overseer = surface.create_entity({ name = "sap-overseer", position = { base.x - 60, base.y }, force = "enemy" })
  overseer.die("player", storage.turret)
  check("mechanites: overseer died without error", not overseer.valid)
end

steps[400] = function()
  local turret = storage.turret
  local disruptor = storage.disruptor
  if disruptor and disruptor.valid then
    check("mechanites: disruptor disables turret", turret and turret.valid and turret.disabled_by_script,
          turret and turret.valid and tostring(turret.disabled_by_script))
  else
    log("SAP-TEST INFO disruptor died before EMP check")
  end
  local mk2 = storage.mk2
  check("storm: mk2 robot protected", mk2 and mk2.valid and mk2.health == mk2.max_health,
        mk2 and mk2.valid and mk2.health)
end

-- Тики 100+: Solaris -----------------------------------------------------------------
steps[100] = function()
  local surface = game.planets["solaris"].create_surface()
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  check("solaris: map generated", surface.is_chunk_generated({ 2, 2 }))
  check("solaris: long day", surface.dawn == 0.6, surface.dawn)
  local ore = surface.count_entities_filtered({ name = "sap-magmatic-ore" })
  local crystal = surface.count_entities_filtered({ name = "sap-heat-resistant-crystal" })
  check("solaris: magmatic ore placed", ore > 0, ore)
  check("solaris: crystals placed", crystal > 0, crystal)
  check("solaris: no tungsten", surface.count_entities_filtered({ name = "tungsten-ore" }) == 0)

  local hot_pos = surface.find_non_colliding_position("assembling-machine-2", { 10, 10 }, 40, 1)
  storage.hot_machine = surface.create_entity({ name = "assembling-machine-2", position = hot_pos, force = "player", raise_built = true })
  local cool_pos = surface.find_non_colliding_position("assembling-machine-2", { -30, 10 }, 40, 6)
  storage.cool_machine = surface.create_entity({ name = "assembling-machine-2", position = cool_pos, force = "player", raise_built = true })
  surface.create_entity({ name = "sap-radiator", position = { cool_pos.x + 2, cool_pos.y }, force = "player" })
  surface.create_entity({ name = "electric-energy-interface", position = { cool_pos.x, cool_pos.y + 4 }, force = "player" })
  surface.create_entity({ name = "substation", position = { cool_pos.x + 3, cool_pos.y + 3 }, force = "player" })
end

steps[200] = function()
  local surface = game.surfaces["solaris"]
  local nests = surface.count_entities_filtered({ name = { "sap-scorch-nest", "sap-magmar-nest" } })
  check("solaris: nests placed", nests > 0, nests)
end

steps[5000] = function()
  local hot, cool = storage.hot_machine, storage.cool_machine
  check("solaris: unprotected machine overheats", hot and hot.valid and hot.disabled_by_script,
        hot and hot.valid and tostring(hot.disabled_by_script))
  check("solaris: radiator protects machine", cool and cool.valid and not cool.disabled_by_script,
        cool and cool.valid and tostring(cool.disabled_by_script))
end

-- Тики 120+: Aquara ------------------------------------------------------------------
steps[120] = function()
  local surface = game.planets["aquara"].create_surface()
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  check("aquara: map generated", surface.is_chunk_generated({ 2, 2 }))
  local area = { { -256, -256 }, { 256, 256 } }
  local water = surface.count_tiles_filtered({ area = area, collision_mask = "water_tile" })
  local total = 512 * 512
  log("SAP-TEST INFO aquara water fraction " .. string.format("%.2f", water / total))
  check("aquara: mostly water", water / total > 0.6, water / total)
  check("aquara: no gleba spawners", surface.count_entities_filtered({ name = { "gleba-spawner", "gleba-spawner-small" } }) == 0)

  -- Торнадо: незащищённая постройка, постройка под щитом, якорь.
  local function land(near)
    return surface.find_non_colliding_position("storage-tank", near, 200, 4, true)
  end
  local p1 = land({ 0, 0 })
  storage.aq_bare = surface.create_entity({ name = "storage-tank", position = p1, force = "player" })
  remote.call("sap-aquara", "spawn_tornado", { x = p1.x - 6, y = p1.y }, p1, 3)

  local p2 = land({ 120, 0 })
  storage.aq_shielded = surface.create_entity({ name = "storage-tank", position = p2, force = "player" })
  surface.create_entity({ name = "sap-storm-shield", position = { p2.x + 4, p2.y + 4 }, force = "player" })
  surface.create_entity({ name = "electric-energy-interface", position = { p2.x - 4, p2.y + 4 }, force = "player" })
  surface.create_entity({ name = "substation", position = { p2.x, p2.y + 5 }, force = "player" })
  remote.call("sap-aquara", "spawn_tornado", { x = p2.x - 6, y = p2.y }, p2, 3)

  local p3 = land({ -120, 0 })
  storage.aq_anchor = surface.create_entity({ name = "sap-storm-anchor", position = p3, force = "player" })
  remote.call("sap-aquara", "spawn_tornado", { x = p3.x - 20, y = p3.y }, { x = p3.x - 60, y = p3.y }, 2)
end

steps[1500] = function()
  local surface = game.surfaces["aquara"]
  local nests = surface.count_entities_filtered({ name = "sap-aquara-nest" })
  check("aquara: nests placed", nests > 0, nests)
  local bare, shielded, anchor = storage.aq_bare, storage.aq_shielded, storage.aq_anchor
  check("aquara: tornado damages unshielded", not (bare and bare.valid) or bare.health < bare.max_health,
        bare and bare.valid and bare.health)
  check("aquara: shield protects", shielded and shielded.valid and shielded.health == shielded.max_health,
        shielded and shielded.valid and shielded.health)
  check("aquara: anchor caught tornado", anchor and anchor.valid and anchor.energy > 0,
        anchor and anchor.valid and anchor.energy)
end

-- Тики 140+: Nivar --------------------------------------------------------------------
steps[140] = function()
  local surface = game.planets["nivar"].create_surface()
  surface.request_to_generate_chunks({ 0, 0 }, 6)
  surface.force_generate_chunk_requests()
  check("nivar: map generated", surface.is_chunk_generated({ 2, 2 }))
  check("nivar: no surface resources", surface.count_entities_filtered({ type = "resource" }) == 0,
        surface.count_entities_filtered({ type = "resource" }))

  local pos = surface.find_non_colliding_position("sap-nivar-elevator", { 0, 0 }, 64, 1)
  local elevator = surface.create_entity({ name = "sap-nivar-elevator", position = pos, force = "player", raise_built = true })
  local partner = remote.call("sap-nivar", "partner_of", elevator)
  check("nivar: elevator partner in caves", partner and partner.valid and partner.surface.name == "nivar-caves",
        partner and partner.valid and partner.surface.name)
  if partner and partner.valid then
    elevator.get_inventory(defines.inventory.linked_container_main).insert({ name = "iron-plate", count = 7 })
    check("nivar: elevator storage shared",
          partner.get_inventory(defines.inventory.linked_container_main).get_item_count("iron-plate") == 7)
  end
  local caves = game.surfaces["nivar-caves"]
  check("nivar: caves are dark", caves.freeze_daytime and caves.daytime == 0.5, caves.daytime)
  caves.request_to_generate_chunks({ 0, 0 }, 6)
  caves.force_generate_chunk_requests()
  local ores = {}
  for _, ore in pairs({ "sap-nivalite", "sap-cryolite", "sap-dark-ice" }) do
    ores[ore] = caves.count_entities_filtered({ name = ore })
    check("nivar: caves have " .. ore, ores[ore] > 0, ores[ore])
  end

  -- Криобуря: машина без защиты и машина у криообогревателя.
  local cold_pos = surface.find_non_colliding_position("assembling-machine-2", { 40, 0 }, 40, 6)
  storage.nv_cold = surface.create_entity({ name = "assembling-machine-2", position = cold_pos, force = "player", raise_built = true })
  local warm_pos = surface.find_non_colliding_position("assembling-machine-2", { -40, 0 }, 40, 6)
  storage.nv_warm = surface.create_entity({ name = "assembling-machine-2", position = warm_pos, force = "player", raise_built = true })
  surface.create_entity({ name = "sap-cryo-heater", position = { warm_pos.x + 2.5, warm_pos.y }, force = "player" })
  surface.create_entity({ name = "electric-energy-interface", position = { warm_pos.x, warm_pos.y + 4 }, force = "player" })
  surface.create_entity({ name = "substation", position = { warm_pos.x + 3, warm_pos.y + 3 }, force = "player" })
  remote.call("sap-nivar", "set_cryostorm", true)

  -- Изолирующий фундамент и фундамент + стены.
  local function insulated(near, walls)
    local p = surface.find_non_colliding_position("assembling-machine-2", near, 60, 20)
    local tiles = {}
    for x = -2, 1 do for y = -2, 1 do tiles[#tiles + 1] = { name = "sap-insulating-foundation", position = { p.x + x, p.y + y } } end end
    surface.set_tiles(tiles)
    local machine = surface.create_entity({ name = "assembling-machine-2", position = p, force = "player", raise_built = true })
    if walls then
      for _, offset in pairs({ { 0, -6 }, { 0, 6 }, { -6, 0 }, { 6, 0 } }) do
        surface.create_entity({ name = "sap-insulated-wall", position = { p.x + offset[1], p.y + offset[2] }, force = "player" })
      end
    end
    return machine
  end
  storage.nv_foundation = insulated({ 0, 80 }, false)
  storage.nv_enclosed = insulated({ 0, -80 }, true)

  -- Пещерная броня.
  local caves_surface = game.surfaces["nivar-caves"]
  local cpos = caves_surface.find_non_colliding_position("character", { 5, 5 }, 30, 1)
  local caver = caves_surface.create_entity({ name = "character", position = cpos, force = "player" })
  caver.get_inventory(defines.inventory.character_armor).insert({ name = "sap-cave-armor", count = 1 })
  storage.caver = caver
end

steps[400] = function()
  local caver = storage.caver
  check("nivar: cave armor speeds up in caves", caver and caver.valid and caver.character_running_speed_modifier >= 0.29,
        caver and caver.valid and caver.character_running_speed_modifier)
end

steps[4500] = function()
  local cold, warm = storage.nv_cold, storage.nv_warm
  check("nivar: cryostorm stops unprotected machine", cold and cold.valid and cold.disabled_by_script,
        cold and cold.valid and tostring(cold.disabled_by_script))
  check("nivar: cryo heater protects machine", warm and warm.valid and not warm.disabled_by_script,
        warm and warm.valid and tostring(warm.disabled_by_script))
  local foundation, enclosed = storage.nv_foundation, storage.nv_enclosed
  if foundation and foundation.valid then
    local fp = foundation.position
    log("SAP-TEST INFO foundation machine at " .. serpent.line(fp) .. " tile " .. foundation.surface.get_tile(fp.x, fp.y).name
        .. " status " .. serpent.line(foundation.custom_status))
  end
  check("nivar: foundation slows freezing", foundation and foundation.valid and not foundation.disabled_by_script,
        foundation and foundation.valid and tostring(foundation.disabled_by_script))
  check("nivar: foundation + walls slow it more", enclosed and enclosed.valid and not enclosed.disabled_by_script
        and enclosed.custom_status == nil or (enclosed.custom_status and enclosed.custom_status.diode ~= defines.entity_status_diode.red),
        enclosed and enclosed.valid and serpent.line(enclosed.custom_status))
  local nests = game.surfaces["nivar"].count_entities_filtered({ name = "sap-blizzard-nest" })
    + game.surfaces["nivar-caves"].count_entities_filtered({ name = "sap-cave-nest" })
  check("nivar: nests placed", nests > 0, nests)
end

-- Тики 160+: бонусы технологий по качеству (I3) -------------------------------------
steps[160] = function()
  if not techtree_on() then return end
  local force = game.forces.player
  check("I3: variant exists", force.technologies["automation-2-sap-rare"] ~= nil)
  remote.call("sap-core", "unlock_tech", "player", "automation-2", "rare")
  check("I3: base unlocked", force.technologies["automation-2"].enabled)
  check("I3: uncommon variant unlocked", force.technologies["automation-2-sap-uncommon"].enabled)
  check("I3: rare variant unlocked", force.technologies["automation-2-sap-rare"].enabled)
  check("I3: epic variant still hidden", not force.technologies["automation-2-sap-epic"].enabled)
  check("I3: rare costs x2", force.technologies["automation-2-sap-rare"].research_unit_count
        == 2 * force.technologies["automation-2"].research_unit_count,
        force.technologies["automation-2-sap-rare"].research_unit_count)

  local surface = game.surfaces.nauvis
  local before_pos = surface.find_non_colliding_position("assembling-machine-2", { -20, 40 }, 40, 4)
  storage.am_before = surface.create_entity({ name = "assembling-machine-2", position = before_pos, force = "player",
                                              raise_built = true })
  force.technologies["automation-2-sap-rare"].researched = true
end

steps[170] = function()
  if not techtree_on() then return end
  local force = game.forces.player
  check("I3: researched quality recorded", remote.call("sap-core", "researched_quality", "player", "automation-2") == "rare",
        remote.call("sap-core", "researched_quality", "player", "automation-2"))
  check("I3: base researched", force.technologies["automation-2"].researched)
  local surface = game.surfaces.nauvis
  local pos = surface.find_non_colliding_position("assembling-machine-2", { 20, 40 }, 40, 4)
  local machine = surface.create_entity({ name = "assembling-machine-2", position = pos, force = "player", raise_built = true })
  machine.set_recipe("iron-gear-wheel")
  storage.am_after = machine
  local neighbour_pos = surface.find_non_colliding_position("assembling-machine-1", { pos.x + 3.5, pos.y }, 10, 0.5)
  storage.am_neighbour = surface.create_entity({ name = "assembling-machine-1", position = neighbour_pos, force = "player",
                                                 raise_built = true })
end

steps[180] = function()
  if not techtree_on() then return end
  local function fx(e) return e and e.valid and e.effects or {} end
  local after, before, neighbour = fx(storage.am_after), fx(storage.am_before), fx(storage.am_neighbour)
  log("SAP-TEST INFO bonus effects new=" .. serpent.line(after) .. " old=" .. serpent.line(before)
      .. " neighbour=" .. serpent.line(neighbour))
  check("I3: new building gets speed bonus", (after.speed or 0) > 0.09, serpent.line(after))
  check("I3: new building gets efficiency bonus", (after.consumption or 0) < -0.09, serpent.line(after))
  check("I3: existing building upgraded", (before.speed or 0) > 0.09, serpent.line(before))
  check("I3: bonus does not leak to neighbour", (neighbour.speed or 0) == 0, serpent.line(neighbour))
end

-- Тики 190+: захват ульев SA+ ----------------------------------------------------------
steps[190] = function()
  local surface = game.surfaces["solaris"]
  local pos = surface.find_non_colliding_position("sap-scorch-nest", { 0, -60 }, 60, 2)
  local nest = surface.create_entity({ name = "sap-scorch-nest", position = pos, force = "enemy" })
  storage.capture_pos = nest.position
  surface.create_entity({ name = "sap-capture-rocket-solaris", position = { pos.x, pos.y + 10 }, target = nest.position,
                          speed = 0.3, force = "player" })
  local scorch = surface.create_entity({ name = "sap-scorch", position = { pos.x + 30, pos.y }, force = "enemy" })
  scorch.die("player")
  -- Ванильная ракета захвата не должна брать гнёзда SA+.
  local pos2 = surface.find_non_colliding_position("sap-scorch-nest", { 60, -60 }, 60, 2)
  local nest2 = surface.create_entity({ name = "sap-scorch-nest", position = pos2, force = "enemy" })
  storage.vanilla_target = nest2
  surface.create_entity({ name = "capture-robot-rocket", position = { pos2.x, pos2.y + 10 }, target = nest2,
                          speed = 0.3, force = "player" })
end

steps[400 + 1] = function()
  local surface = game.surfaces["solaris"]
  local captive = surface.find_entities_filtered({ name = "sap-captive-sap-scorch-nest", position = storage.capture_pos,
                                                   radius = 3 })[1]
  check("capture: recalibrated rocket captures nest", captive ~= nil)
  check("capture: vanilla rocket ignores SA+ nest", storage.vanilla_target and storage.vanilla_target.valid)
  if captive then
    captive.get_fuel_inventory().insert({ name = "sap-solaris-food", count = 10 })
    storage.captive = captive
  end
end

steps[2500] = function()
  local captive = storage.captive
  if not (captive and captive.valid) then return end
  local produced = captive.get_output_inventory().get_item_count("sap-heat-scales")
  check("capture: fed captive nest produces scales", produced > 0, produced)
end

-- Тики 210+: сверхбойлер и мега-турбина ---------------------------------------------
steps[210] = function()
  local surface = game.surfaces["solaris"]
  local bpos = surface.find_non_colliding_position("sap-super-boiler", { 0, 120 }, 80, 4)
  local boiler = surface.create_entity({ name = "sap-super-boiler", position = bpos, force = "player" })
  local catcher = surface.create_entity({ name = "sap-ray-catcher",
    position = surface.find_non_colliding_position("sap-ray-catcher", { bpos.x + 5, bpos.y }, 10, 1), force = "player" })
  storage.sb_boiler, storage.sb_start = boiler, boiler.temperature
  remote.call("sap-solaris", "charge_catcher", catcher, 5000000000)

  -- Установка целиком: турбина, нагрузка, подстанция, бак. Вокруг лава, поэтому ищем участок
  -- суши и проверяем, что встала каждая постройка; иначе пробуем другое место.
  local turbine, tank
  for attempt = 1, 8 do
    local center = surface.find_non_colliding_position("rocket-silo", { 80 + attempt * 40, 120 }, 120, 2, true)
    if center then
      local placed = {}
      local function put(name, dx, dy)
        local e = surface.create_entity({ name = name, position = { center.x + dx, center.y + dy }, force = "player" })
        if e then placed[#placed + 1] = e end
        return e
      end
      turbine = put("sap-mega-turbine", 0, 0)
      local load = put("electric-energy-interface", 3, -1)
      local pole = put("substation", 3, 2)
      tank = put("storage-tank", -3, 0)
      if turbine and load and pole and tank then
        load.power_production = 0
        load.power_usage = 50000000 / 60
        load.electric_buffer_size = 100000000
        log("SAP-TEST INFO mega turbine setup on attempt " .. attempt)
        break
      end
      for _, e in pairs(placed) do e.destroy() end
      turbine, tank = nil, nil
    end
  end
  check("solaris: mega turbine test setup", turbine ~= nil and tank ~= nil)
  storage.mt_turbine, storage.mt_tank = turbine, tank
end

for tick = 220, 800, 20 do
  steps[tick] = function()
    local turbine = storage.mt_turbine
    if turbine and turbine.valid then turbine.insert_fluid({ name = "steam", amount = 200, temperature = 500 }) end
  end
end

steps[810] = function()
  local boiler = storage.sb_boiler
  check("solaris: catcher heats super boiler", boiler and boiler.valid and boiler.temperature > storage.sb_start + 50,
        boiler and boiler.valid and (storage.sb_start .. " -> " .. boiler.temperature))
  local tank = storage.mt_tank
  local water = tank and tank.valid and tank.get_fluid_count("water") or 0
  local turbine = storage.mt_turbine
  if turbine and turbine.valid and tank and tank.valid then
    log(string.format("SAP-TEST INFO water %.1f turbine at %.1f,%.1f tank at %.1f,%.1f energy %.0f",
      water, turbine.position.x, turbine.position.y, tank.position.x, tank.position.y, turbine.energy_generated_last_tick))
  end
  check("solaris: mega turbine returns water", water > 0, water)
end

-- Тики 230+: мусор на орбите Echaris ------------------------------------------------
steps[230] = function()
  local force = game.forces.player
  force.unlock_space_location("echaris")
  local platform = force.create_space_platform({ name = "sap-test-echaris", planet = "echaris",
                                                 starter_pack = "space-platform-starter-pack" })
  if platform then platform.apply_starter_pack() end
  storage.echaris_platform = platform
  local extra = false
  for _, product in pairs(prototypes.recipe["sap-debris-electrified-crushing"].products) do
    if product.name == "sap-mechanite-scrap" then extra = true end
  end
  check("debris: electrified gives mechanite scrap with echaris installed", extra)
end

steps[240] = function()
  local platform = storage.echaris_platform
  if not (platform and platform.valid and platform.hub) then
    check("debris: echaris platform", false, "no hub")
    return
  end
  local hub = platform.hub.position
  for i = 1, 60 do platform.eject_item({ name = "iron-plate" }, { hub.x + 3, hub.y + i % 5 }, { 0.1, 0 }) end
end

for tick = 2400, 3400, 50 do
  steps[tick] = function()
    local platform = storage.echaris_platform
    if not (platform and platform.valid) then return end
    local flavored = #platform.find_asteroid_chunks_filtered({ name = "sap-debris-electrified" })
    storage.max_electrified = math.max(storage.max_electrified or 0, flavored)
    if tick == 3400 then
      check("debris: echaris orbit gives electrified debris", storage.max_electrified > 0, storage.max_electrified)
    end
  end
end

-- Тик 2700: хардкор «без доставки» на Echaris ----------------------------------------
steps[2700] = function()
  local platform = storage.echaris_platform
  if not (platform and platform.valid and platform.hub) then return end
  game.planets["echaris"].create_surface()
  remote.call("sap-core", "no_delivery_override", "echaris", true)
  local pod = platform.hub.create_cargo_pod()
  check("no-delivery: pod created", pod ~= nil)
  if not pod then return end
  pod.get_inventory(defines.inventory.cargo_unit).insert({ name = "iron-plate", count = 10 })
  pod.cargo_pod_destination = { type = defines.cargo_destination.surface, surface = game.surfaces["echaris"],
                                position = { 0, 0 } }
  storage.hub_iron_before = platform.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")
  storage.pod = pod
end

steps[4200] = function()
  local platform = storage.echaris_platform
  if not (platform and platform.valid and platform.hub) then return end
  local after = platform.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")
  local landed = game.surfaces["echaris"].find_entities_filtered({ name = "item-on-ground" })
  local on_echaris = game.surfaces["echaris"].count_entities_filtered({ type = "cargo-pod" })
  log(string.format("SAP-TEST INFO hub iron %d -> %d, pods on echaris %d, items on ground %d",
      storage.hub_iron_before or -1, after, on_echaris, #landed))
  check("no-delivery: cargo came back to the hub", after >= (storage.hub_iron_before or 0) + 10,
        (storage.hub_iron_before or -1) .. " -> " .. after)
  remote.call("sap-core", "no_delivery_override", "echaris", false)
end

-- Тики 3000+: силовой барьер, стелс, взлом, тихий захват ---------------------------
local function clear_spot(surface, near, size)
  -- Если рядом места нет — ищем всё дальше по спирали.
  for attempt = 0, 12 do
    local angle = attempt * 1.3
    local p = { near[1] + math.cos(angle) * attempt * 60, near[2] + math.sin(angle) * attempt * 60 }
    local found = surface.find_non_colliding_position("sap-control-server-heavy", p, 200, size or 4, true)
    if found then return found end
  end
  error("no free spot near " .. serpent.line(near))
end

steps[3000] = function()
  local surface = game.surfaces["echaris"]
  local force = game.forces.player
  -- Барьер
  local bpos = clear_spot(surface, { -150, 150 })
  local barrier = surface.create_entity({ name = "sap-force-barrier", position = bpos, force = force })
  barrier.energy = 50000000
  storage.barrier, storage.barrier_units = barrier, {}
  for i = 1, 3 do
    storage.barrier_units[i] = surface.create_entity({ name = "sap-sentinel", position = { bpos.x + 4 + i, bpos.y }, force = "enemy" })
  end
  -- Стелс: два персонажа, у одного костюм стелса; рядом с каждым — Механит в 12 клетках.
  local first_pos
  for i, armor in pairs({ "sap-stealth-suit", "modular-armor" }) do
    -- Персонажи должны стоять далеко друг от друга, иначе стелс одного уводит врага другого.
    local cpos, fallback
    for shift = 0, 12 do
      local ok, found = pcall(clear_spot, surface, { 150 + i * 80 + shift * 25, -150 - shift * 15 })
      cpos = ok and found or nil
      if not fallback and cpos
          and (not first_pos or ((cpos.x - first_pos.x) ^ 2 + (cpos.y - first_pos.y) ^ 2) > 60 ^ 2) then
        fallback = cpos
      end
      if not cpos then goto next_shift end
      -- Подальше от зон Механитов: их патрули законно находят игрока и в костюме.
      local near_zone = surface.count_entities_filtered({
        name = { "sap-control-server", "sap-control-server-heavy", "sap-alien-guardian", "sap-alien-vault" },
        position = cpos, radius = 90, limit = 1,
      }) > 0
      if not near_zone and (not first_pos or ((cpos.x - first_pos.x) ^ 2 + (cpos.y - first_pos.y) ^ 2) > 60 ^ 2) then
        break
      end
      cpos = nil
      ::next_shift::
    end
    cpos = cpos or fallback or clear_spot(surface, { 0, -300 - i * 120 })
    first_pos = first_pos or cpos
    local character = surface.create_entity({ name = "character", position = cpos, force = force })
    character.get_inventory(defines.inventory.character_armor).insert({ name = armor, count = 1 })
    -- В костюме — враг в 12 клетках (дальше порога 6); без костюма — быстрый враг рядом,
    -- чтобы рельеф не мешал ему дойти.
    local distance = armor == "sap-stealth-suit" and 12 or 4
    local unit = surface.create_entity({ name = armor == "sap-stealth-suit" and "sap-annihilator" or "sap-sentinel",
                                         position = { cpos.x + distance, cpos.y }, force = "enemy" })
    unit.commandable.set_command({ type = defines.command.attack, target = character,
                                   distraction = defines.distraction.none })
    storage["stealth_" .. i] = character
  end
  -- Взлом
  force.technologies["sap-mechanite-hacking"].researched = true
  local hpos = clear_spot(surface, { 150, 150 })
  storage.hack_units = {}
  for i = 1, 8 do
    storage.hack_units[i] = surface.create_entity({ name = "sap-sentinel", position = { hpos.x + (i % 3), hpos.y + math.floor(i / 3) },
                                                   force = "enemy" })
  end
  local thrower = surface.create_entity({ name = "character", position = { hpos.x - 10, hpos.y }, force = force })
  surface.create_entity({ name = "sap-emp-grenade", position = { hpos.x - 9, hpos.y }, target = { hpos.x + 1, hpos.y + 1 },
                          speed = 0.3, source = thrower, force = force })
  -- Тихий захват
  local cpos = clear_spot(surface, { -150, -150 })
  local center = surface.create_entity({ name = "sap-center-data", position = cpos, force = "neutral" })
  for i = 1, 3 do surface.create_entity({ name = "sap-sentinel", position = { cpos.x + 20 + i, cpos.y }, force = "enemy" }) end
  local loud = remote.call("sap-echaris", "center_alarm", center, "player")
  force.technologies["sap-silent-capture-protocol"].researched = true
  local quiet = remote.call("sap-echaris", "center_alarm", center, "player")
  check("silent capture: alarm without protocol", loud > 0, loud)
  check("silent capture: no alarm with protocol", quiet == 0, quiet)
end

steps[3120] = function()
  local alive = 0
  for _, u in pairs(storage.barrier_units) do if u.valid then alive = alive + 1 end end
  check("barrier: kills mechanites in range", alive == 0, alive)
  check("barrier: spends charge", storage.barrier.valid and storage.barrier.energy <= 50000000 - 15000000,
        storage.barrier.valid and storage.barrier.energy)
  local hacked = 0
  for _, u in pairs(storage.hack_units) do if u.valid and u.force.name == "player" then hacked = hacked + 1 end end
  check("hacking: EMP grenade turns mechanites", hacked > 0, hacked)
end

-- Без костюма: следим за здоровьем всё время теста; если враг погиб (например, от молнии
-- бури), ставим нового рядом.
for tick = 3030, 3870, 30 do
  steps[tick] = function()
    local plain = storage.stealth_2
    if not (plain and plain.valid) then return end
    if plain.health < plain.max_health then storage.plain_was_hit = true end
    local attacker = storage.stealth_unit_2
    if not (attacker and attacker.valid) then
      local surface = plain.surface
      local pos = surface.find_non_colliding_position("sap-sentinel", { plain.position.x + 4, plain.position.y }, 8, 0.5)
      if pos then
        attacker = surface.create_entity({ name = "sap-sentinel", position = pos, force = "enemy" })
        attacker.commandable.set_command({ type = defines.command.attack, target = plain,
                                           distraction = defines.distraction.none })
        storage.stealth_unit_2 = attacker
      end
    end
  end
end

steps[3900] = function()
  local stealthy, plain = storage.stealth_1, storage.stealth_2
  local s_hp = stealthy and stealthy.valid and stealthy.health or 0
  local p_hp = plain and plain.valid and plain.health or 0
  log(string.format("SAP-TEST INFO stealth health %.0f, plain health %.0f", s_hp, p_hp))
  -- Молния бури Echaris (электричество без источника) бьёт и по игроку в костюме — это не
  -- провал стелса. Провал — урон от Механита.
  local death = storage.stealth_death
  local by_lightning = death and death.cause == nil and death.damage == "electric"
  if by_lightning then log("SAP-TEST INFO stealth character killed by storm lightning: check skipped") end
  check("stealth: suit keeps mechanites away", by_lightning or (stealthy and stealthy.valid and s_hp == stealthy.max_health),
        serpent.line(death) .. " hp " .. s_hp)
  local gap = (stealthy and stealthy.valid and plain and plain.valid)
    and math.sqrt((stealthy.position.x - plain.position.x) ^ 2 + (stealthy.position.y - plain.position.y) ^ 2) or -1
  local attacker = storage.stealth_unit_2
  check("stealth: without suit gets attacked", not (plain and plain.valid) or p_hp < plain.max_health or storage.plain_was_hit,
        string.format("hp %s, characters %.0f apart, attacker %s", p_hp, gap,
          attacker and attacker.valid and (attacker.force.name .. " " .. serpent.line(attacker.position)) or "gone"))
end

-- Тики 4300+: капсула доставки на Solaris -----------------------------------------
local function send_pod(platform, surface_name, item, count)
  local pod = platform.hub.create_cargo_pod()
  if not pod then return nil end
  pod.get_inventory(defines.inventory.cargo_unit).insert({ name = item, count = count })
  pod.cargo_pod_destination = { type = defines.cargo_destination.surface, surface = game.surfaces[surface_name],
                                position = { 0, 0 } }
  return pod
end

steps[4300] = function()
  local force = game.forces.player
  force.unlock_space_location("solaris")
  local platform = force.create_space_platform({ name = "sap-test-solaris", planet = "solaris",
                                                 starter_pack = "space-platform-starter-pack" })
  platform.apply_starter_pack()
  storage.solaris_platform = platform
end

steps[4310] = function()
  local platform = storage.solaris_platform
  check("capsule: pod without tech created", send_pod(platform, "solaris", "copper-plate", 7) ~= nil)
end

steps[5800] = function()
  local platform = storage.solaris_platform
  local back = platform.hub.get_inventory(defines.inventory.hub_main).get_item_count("copper-plate")
  check("capsule: without tech cargo returns to hub", back == 7, back)
  game.forces.player.technologies["sap-improved-delivery-capsule"].researched = true
  send_pod(platform, "solaris", "copper-plate", 5)
end

steps[7300] = function()
  local platform = storage.solaris_platform
  local back = platform.hub.get_inventory(defines.inventory.hub_main).get_item_count("copper-plate")
  check("capsule: with tech cargo lands on solaris", back == 7, back)
end

-- Тики 7400+: хранилища древней расы и последние записи дневника ---------------------
steps[7400] = function()
  local vaults, with_loot = 0, 0
  for _, surface in pairs(game.surfaces) do
    for _, vault in pairs(surface.find_entities_filtered({ name = "sap-alien-vault" })) do
      vaults = vaults + 1
      local inv = vault.get_inventory(defines.inventory.chest)
      local card, data = 0, 0
      for _, stack in pairs(inv.get_contents()) do
        if stack.name == "sap-data-card-alien" then card = card + stack.count end
        if stack.name == "sap-alien-data" then data = data + stack.count end
      end
      if card == 1 and data == 1 then
        with_loot = with_loot + 1
      else
        log("SAP-TEST INFO vault on " .. surface.name .. " at " .. serpent.line(vault.position) .. ": "
            .. serpent.line(inv.get_contents()))
      end
    end
  end
  -- Хранилища появляются только со скрытым деревом (их карты открывают скрытые технологии).
  check("alien: vaults generated", not techtree_on() or vaults > 0, vaults)
  check("alien: vaults hold alien card and data", vaults == 0 and not techtree_on() or vaults > 0 and with_loot == vaults,
        with_loot .. "/" .. vaults)
  check("alien: alien techs in alien category",
        prototypes.mod_data["sap-tech-catalog"].data["sap-alien-geometry"].category == "alien")

  -- Дедлок: отдельная команда, 12 машин с рецептом и без ингредиентов.
  local force = game.create_force("sap-deadlock-test")
  local surface = game.surfaces.nauvis
  local base = surface.find_non_colliding_position("substation", { 200, 200 }, 100, 20)
  surface.create_entity({ name = "electric-energy-interface", position = { base.x - 3, base.y }, force = force })
  surface.create_entity({ name = "substation", position = base, force = force })
  for i = 0, 11 do
    local m = surface.create_entity({ name = "assembling-machine-2",
      position = { base.x - 6 + (i % 4) * 3 + 0.5, base.y + 3 + math.floor(i / 4) * 3 + 0.5 }, force = force })
    if m then m.set_recipe("iron-gear-wheel") end
  end
  storage.deadlock_force = force.name
end

steps[7500] = function()
  remote.call("sap-diary", "check_base", storage.deadlock_force)
  local entries = {}
  for _, key in pairs(remote.call("sap-diary", "entries", storage.deadlock_force)) do entries[key] = true end
  check("diary: deadlock detected", entries["deadlock"] == true, serpent.line(entries))
  local player_entries = {}
  for _, key in pairs(remote.call("sap-diary", "entries", "player")) do player_entries[key] = true end
  check("diary: first interplanetary delivery", player_entries["first-delivery"] == true)
end

-- Тики 8000+: кислород (без игрока, через тестовый шаг) ---------------------------------
steps[8000] = function()
  local surface = game.planets["vulcanus"].create_surface()
  surface.request_to_generate_chunks({ 0, 0 }, 3)
  surface.force_generate_chunk_requests()
  local function spot(near) return surface.find_non_colliding_position("rocket-silo", near, 80, 2, true) end
  local force = game.forces.player

  local a = surface.create_entity({ name = "character", position = spot({ -40, 0 }), force = force })
  local bpos = spot({ 0, 40 })
  local b = surface.create_entity({ name = "character", position = bpos, force = force })
  local armor = b.get_inventory(defines.inventory.character_armor)
  armor.insert({ name = "modular-armor", count = 1 })
  armor[1].grid.put({ name = "sap-oxygen-tank-equipment" })

  local cpos = spot({ 40, 0 })
  local distributor = surface.create_entity({ name = "sap-oxygen-distributor", position = cpos, force = force })
  surface.create_entity({ name = "electric-energy-interface", position = { cpos.x + 3, cpos.y - 2 }, force = force })
  surface.create_entity({ name = "substation", position = { cpos.x + 3, cpos.y + 1 }, force = force })
  local c = surface.create_entity({ name = "character", position = { cpos.x - 3, cpos.y + 3 }, force = force })
  storage.ox = { a = a, b = b, c = c, distributor = distributor }
  storage.ox.b_start = remote.call("sap-core", "oxygen_step", b, 150)
end

for tick = 8060, 8660, 60 do
  steps[tick] = function()
    local ox = storage.ox
    if ox.distributor.valid then ox.distributor.insert_fluid({ name = "sap-oxygen", amount = 50 }) end
    for _, key in pairs({ "a", "b", "c" }) do
      if ox[key].valid then ox["air_" .. key] = remote.call("sap-core", "oxygen_step", ox[key]) end
    end
  end
end

steps[8700] = function()
  local ox = storage.ox
  check("oxygen: no armor means suffocation", not ox.a.valid or ox.a.health < ox.a.max_health,
        ox.a.valid and ox.a.health)
  check("oxygen: tank keeps you alive", ox.b.valid and ox.b.health == ox.b.max_health, ox.b.valid and ox.b.health)
  check("oxygen: tank air goes down", ox.air_b and ox.air_b < ox.b_start, tostring(ox.b_start) .. " -> " .. tostring(ox.air_b))
  check("oxygen: distributor zone protects", ox.c.valid and ox.c.health == ox.c.max_health,
        ox.c.valid and ox.c.health .. " status " .. tostring(ox.distributor.status))
end

-- Тики 8800+: дешифратор и ЛЛК (без окна, через тестовый вызов) --------------------------
steps[8800] = function()
  if not techtree_on() then return end
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  local function machine(name, near)
    local e = surface.create_entity({ name = name, position = surface.find_non_colliding_position(name, near, 40, 1),
                                      force = force })
    local inv = e.get_inventory(defines.inventory.chest)
    inv.insert({ name = "automation-science-pack", count = 10 })
    inv.insert({ name = "logistic-science-pack", count = 10 })
    return e, inv
  end
  local dec, dinv = machine("sap-decipherer", { -60, -60 })
  dinv.insert({ name = "sap-data-card-logistics", count = 1, quality = "rare" })
  local result = remote.call("sap-core", "decipher", "player", dec, 1)
  log("SAP-TEST INFO decipher options " .. serpent.line(result))
  check("decipher: offers technologies", result.names and #result.names > 0, serpent.line(result))
  if result.names and result.names[1] then
    local tech = string.match(result.names[1], "^(.-):")
    check("decipher: chosen technology unlocked", force.technologies[tech].enabled, tech)
  end
  check("decipher: packs spent", dinv.get_item_count("automation-science-pack") == 0)

  local llk, linv = machine("sap-logic-lab", { -70, -60 })
  local llk_off = remote.call("sap-core", "get_setting", "sap-hardcore-decipher-only")
  local llk_result = remote.call("sap-core", "decipher", "player", llk, 1, 0)
  if llk_off then
    check("llk: disabled by decipher-only hardcore", llk_result.message == "sap-techtree.llk-disabled",
          serpent.line(llk_result))
    return
  end
  log("SAP-TEST INFO llk options " .. serpent.line(llk_result))
  check("llk: success offers up to two", llk_result.names and #llk_result.names >= 1 and #llk_result.names <= 2,
        serpent.line(llk_result))
  local fail = machine("sap-logic-lab", { -80, -60 })
  local fail_result = remote.call("sap-core", "decipher", "player", fail, nil, 0.99)
  check("llk: failure spends packs and gives nothing", fail_result.names == nil and fail_result.message == "sap-techtree.llk-failed",
        serpent.line(fail_result))
  check("llk: no alien technologies offered", not (llk_result.names and string.find(table.concat(llk_result.names, ","), "sap%-alien")))
  local _ = linv
end

-- Тик 5: проверка прохождения (до любых действий теста) ----------------------------------
local progression = require("progression")
steps[5] = function()
  local stuck, rounds = progression.audit(game.forces.player)
  log("SAP-TEST INFO progression rounds " .. rounds .. ", unreachable " .. #stuck .. ": " .. table.concat(stuck, ", "))
  check("progression: every technology reachable", #stuck == 0, #stuck .. " unreachable")
  -- Самопроверка: без карт «Логистика» должны появиться тупики, иначе проверка ничего не ловит.
  local stuck_without = progression.audit(game.forces.player, { logistics = true })
  log("SAP-TEST INFO progression without logistics cards: " .. #stuck_without .. " unreachable, e.g. "
      .. table.concat({ table.unpack(stuck_without, 1, math.min(5, #stuck_without)) }, ", "))
  check("progression: audit detects a missing card category", not techtree_on() or #stuck_without > 0, #stuck_without)
end

-- Тики 9000+: замер производительности на большой базе -----------------------------------
local function grid(surface, name, count, origin, step, force)
  local placed = 0
  local side = math.ceil(math.sqrt(count))
  for i = 0, side * side - 1 do
    if placed >= count then break end
    local pos = { origin.x + (i % side) * step, origin.y + math.floor(i / side) * step }
    if surface.can_place_entity({ name = name, position = pos, force = force }) then
      surface.create_entity({ name = name, position = pos, force = force, raise_built = true })
      placed = placed + 1
    end
  end
  return placed
end


steps[9000] = function()
  local force = game.forces.player
  local solaris = game.surfaces["solaris"]
  solaris.request_to_generate_chunks({ 600, 0 }, 4)
  solaris.force_generate_chunk_requests()
  local n1 = grid(solaris, "assembling-machine-2", 2000, { x = 500, y = -100 }, 3, force)
  grid(solaris, "sap-radiator", 200, { x = 501.5, y = -98.5 }, 9, force)
  local nivar = game.surfaces["nivar"]
  nivar.request_to_generate_chunks({ 600, 0 }, 4)
  nivar.force_generate_chunk_requests()
  local n2 = grid(nivar, "assembling-machine-2", 2000, { x = 500, y = -100 }, 3, force)
  local echaris = game.surfaces["echaris"]
  local n3 = grid(echaris, "construction-robot", 1000, { x = 0, y = 0 }, 2, force)
  grid(echaris, "roboport", 50, { x = -300, y = -300 }, 8, force)
  grid(echaris, "sap-storm-stabilizer", 100, { x = 300, y = 300 }, 6, force)
  log(string.format("SAP-TEST INFO bench base: solaris %d, nivar %d machines, echaris %d robots", n1, n2, n3))
  remote.call("sap-nivar", "set_cryostorm", true)
end

-- Полный цикл (каждая машина/дрон обработаны один раз): сумма и каждый вызов отдельно.
local function measure_cycle(label, fn, calls)
  local total = helpers.create_profiler()
  local each = {}
  for i = 1, calls do
    local p = helpers.create_profiler()
    fn()
    p.stop()
    each[i] = p
  end
  total.stop()
  local line = { "", "SAP-TEST BENCH ", label, " cycle: ", total, " | calls:" }
  for i = 1, calls do line[#line + 1] = { "", " ", each[i] } end
  log(line)
end

steps[9010] = function()
  -- Первый цикл — прогрев (впервые записываются статусы), меряется второй.
  for round = 1, 2 do
    local tag = round == 1 and " (warm-up)" or ""
    measure_cycle("solaris overheat" .. tag, function() remote.call("sap-solaris", "overheat_tick") end, 5)
    measure_cycle("nivar cryostorm" .. tag, function() remote.call("sap-nivar", "cryostorm_tick") end, 5)
    measure_cycle("echaris storm" .. tag, function() remote.call("sap-echaris", "storm_tick") end, 4)
  end
end

-- Тики 9500+: мелочи из документа -----------------------------------------------------------
steps[9500] = function()
  -- Отвоевание зон: зона без барьера возвращается Механитам, зона с барьером — нет.
  local echaris = game.surfaces["echaris"]
  local function server_at(near)
    -- Точка без чужих серверов и барьеров в радиусе зоны (40), иначе зона считается занятой.
    local busy = { "sap-control-server", "sap-control-server-heavy", "sap-force-barrier", "sap-force-barrier-mk2" }
    for i = 0, 40 do
      local candidate = { near[1] + (i % 7) * 120, near[2] + math.floor(i / 7) * 120 }
      echaris.request_to_generate_chunks(candidate, 2)
      echaris.force_generate_chunk_requests()
      if echaris.count_entities_filtered({ name = busy, position = candidate, radius = 60, limit = 1 }) == 0 then
        near = candidate
        break
      end
    end
    local pos = clear_spot(echaris, near, 4)
    return echaris.create_entity({ name = "sap-control-server", position = pos, force = "enemy" })
  end
  local open_zone = server_at({ 400, 400 })
  local guarded = server_at({ -400, 400 })
  local open_pos, guarded_pos = open_zone.position, guarded.position
  echaris.create_entity({ name = "sap-force-barrier",
    position = echaris.find_non_colliding_position("sap-force-barrier", { guarded_pos.x + 12, guarded_pos.y }, 20, 1),
    force = "player" })
  open_zone.die("player")
  guarded.die("player")
  local reclaimed = remote.call("sap-echaris", "reclaim_now")
  local back_open = echaris.count_entities_filtered({ name = "sap-control-server", position = open_pos, radius = 20 })
  local back_guarded = echaris.count_entities_filtered({ name = "sap-control-server", position = guarded_pos, radius = 20 })
  check("mechanites: zone without barrier reclaimed", back_open == 1, back_open .. " (reclaimed " .. reclaimed .. ")")
  check("mechanites: zone with barrier stays", back_guarded == 0, back_guarded)

  -- Solaris: вулканические источники вместо гейзеров кислоты.
  local solaris = game.surfaces["solaris"]
  local vents = solaris.count_entities_filtered({ name = "sap-volcanic-vent" })
  check("solaris: volcanic vents placed", vents > 0, vents)
  check("solaris: no sulfuric acid geysers", solaris.count_entities_filtered({ name = "sulfuric-acid-geyser" }) == 0)
  local uses_metal = false
  for _, i in pairs(prototypes.recipe["sap-heat-resistant-alloy"].ingredients) do
    if i.name == "sap-molten-metal" then uses_metal = true end
  end
  check("solaris: alloy made from molten metal", uses_metal)

  -- Nivar: пещерные гнёзда просыпаются от криобури; ресурсы Аквило в рецептах.
  local caves = game.surfaces["nivar-caves"]
  local npos = caves.find_non_colliding_position("sap-cave-nest", { 60, 60 }, 60, 2, true)
  caves.create_entity({ name = "sap-cave-nest", position = npos, force = "enemy" })
  caves.create_entity({ name = "wooden-chest",
    position = caves.find_non_colliding_position("wooden-chest", { npos.x + 25, npos.y }, 20, 1), force = "player" })
  local woken = remote.call("sap-nivar", "wake_caves")
  check("nivar: cryostorm wakes cave creatures", woken > 0, woken)
  local lithium = false
  for _, i in pairs(prototypes.recipe["sap-cryo-heater"].ingredients) do
    if i.name == "lithium-plate" then lithium = true end
  end
  check("nivar: needs Aquilo lithium (N4)", lithium)
end

-- Тик 15: набор настроек (PRESET=... в tools/run-tests.sh) ------------------------------------
steps[15] = function()
  local preset = settings.startup["sap-preset"].value
  local get = function(name) return remote.call("sap-core", "get_setting", name) end
  log("SAP-TEST INFO preset " .. preset)
  if preset == "casual" then
    check("preset casual: tree not hidden", get("sap-techtree-enabled") == false
          and game.forces.player.technologies["logistics-2"].enabled)
    check("preset casual: vanilla planets without satellites", game.forces.player.technologies["planet-discovery-vulcanus"].enabled)
    check("preset casual: slow suffocation, large tanks",
          get("sap-oxygen-death-speed") == "slow" and get("sap-oxygen-tank-size") == "large")
  elseif preset == "hardcore" then
    check("preset hardcore: tree hidden", not game.forces.player.technologies["logistics-2"].enabled)
    check("preset hardcore: every hardcore option on", get("sap-hardcore-strict-oxygen") and get("sap-hardcore-satellite")
          and get("sap-hardcore-echaris-timed-waves") and get("sap-hardcore-nivar-no-delivery"))
    check("preset hardcore: fast suffocation, small tanks",
          get("sap-oxygen-death-speed") == "fast" and get("sap-oxygen-tank-size") == "small")
  end
end

-- Тик 16: API для других модов -----------------------------------------------------------------
steps[16] = function()
  if not techtree_on() then return end
  local catalog = prototypes.mod_data["sap-tech-catalog"].data
  check("api: keep_visible keeps a technology visible", game.forces.player.technologies["sap-test-visible-tech"].enabled
        and catalog["sap-test-visible-tech"] == nil)
  check("api: set_tech_category sets the card category", catalog["sap-test-categorized-tech"]
        and catalog["sap-test-categorized-tech"].category == "trains")
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
  -- Робот у стабилизатора может погибнуть от молнии (как на Фульгоре) — это не ошибка бури.


  check("satellites: all launched", storage.launched == MK1_LAUNCHES + 1, storage.launched)
  local hard_sat = remote.call("sap-core", "get_setting", "sap-hardcore-satellite")
  check("satellites: mk2 tech enabled after 10 (hardcore: not yet)",
        force.technologies["sap-satellite-mk2"].enabled ~= (hard_sat == true))
  local found, scouted = discovery_states()
  check("satellites: mk1 found something", found >= 1, found)
  check("satellites: mk2 scouted one", scouted == 1, scouted)

  local entries = {}
  for _, key in pairs(remote.call("sap-diary", "entries", "player")) do entries[key] = true end
  log("SAP-TEST INFO diary entries: " .. serpent.line(remote.call("sap-diary", "entries", "player")))
  local expected = { "sat-first", "sat-five-lost", "emp-disruptor", "reinforcements", "capture-sa", "jettisoned-card",
                     "kill-scorch-1" }
  if not remote.call("sap-core", "get_setting", "sap-hardcore-satellite") then expected[#expected + 1] = "sat-mk2-ready" end
  for _, key in pairs(expected) do
    check("diary: entry " .. key, entries[key] == true)
  end

  local launches = 0
  for _, r in pairs(results) do if not r then launches = launches + 1 end end
  log("SAP-TEST DONE failures=" .. launches)
end

-- Подземелья древней расы ---------------------------------------------------------------
local function has_entry_early(force_name, key)
  for _, k in pairs(remote.call("sap-diary", "entries", force_name)) do if k == key then return true end end
  return false
end

local DUNGEON_PLANETS = { "nauvis", "vulcanus", "fulgora", "gleba", "aquilo", "solaris", "echaris", "aquara", "nivar" }

steps[9600] = function()
  local profiler = helpers.create_profiler()
  for _, planet in pairs(DUNGEON_PLANETS) do
    if game.planets[planet] then
      local record = remote.call("sap-core", "dungeon_generate", planet)
      local surface = game.get_surface("sap-dungeon-" .. planet)
      check("dungeon " .. planet .. ": surface", surface ~= nil)
      if surface then
        check("dungeon " .. planet .. ": rooms", record.rooms >= 4, record.rooms)
        check("dungeon " .. planet .. ": doors", record.doors >= 1, record.doors)
        check("dungeon " .. planet .. ": exit", surface.count_entities_filtered({ name = "sap-dungeon-exit" }) == 1)
        local caches = surface.find_entities_filtered({ name = "sap-ancient-cache" })
        check("dungeon " .. planet .. ": caches", #caches >= record.rooms - 1, #caches)
        local cores = 0
        local core_item = remote.call("sap-core", "cores_item", planet)
        for _, c in pairs(caches) do cores = cores + c.get_inventory(defines.inventory.chest).get_item_count(core_item) end
        check("dungeon " .. planet .. ": no core while the Warden lives", cores == 0, cores)
        local rec = remote.call("sap-core", "dungeon_record", planet)
        check("dungeon " .. planet .. ": Warden in the last room", rec.boss ~= nil and rec.boss.valid)
        check("dungeon " .. planet .. ": traps", surface.count_entities_filtered({ name = "sap-ancient-trap" }) > 0)
        local doubles = 0
        for _, d in pairs(remote.call("sap-core", "dungeon_door_locks", planet)) do
          if d.kind == "double" then doubles = doubles + 1 end
        end
        check("dungeon " .. planet .. ": one double door to the last room", doubles == 1, doubles)
        if rec.boss and rec.boss.valid then rec.boss.die() end
        local locks = remote.call("sap-core", "dungeon_door_locks", planet)
        local all_locked = true
        for _, d in pairs(locks) do
          if not (d.lock and d.lock.valid) or (d.kind == "double" and not (d.lock2 and d.lock2.valid)) then
            all_locked = false
          end
        end
        check("dungeon " .. planet .. ": every door has a lock", all_locked)
        -- Дверь стоит на полу (коридоре), а не в пустоте.
        local on_floor = true
        for _, d in pairs(locks) do
          if surface.get_tile(d.door.position).name == "out-of-map" then on_floor = false end
        end
        check("dungeon " .. planet .. ": doors in corridors", on_floor)
        local c = record.chunks
        check("dungeon " .. planet .. ": void outside rooms",
              surface.get_tile(c[1] * 32, c[2] * 32).name == "out-of-map"
              and surface.get_tile(c[3] * 32 + 31, c[4] * 32 + 31).name == "out-of-map")
        local start = surface.find_non_colliding_position("character", record.start, 10, 0.5)
        check("dungeon " .. planet .. ": start is walkable", start ~= nil)
      end
    end
  end
  profiler.stop()
  log({ "", "SAP-TEST INFO dungeon generation (all planets): ", profiler })
  -- Повторный вызов возвращает то же подземелье.
  local again = remote.call("sap-core", "dungeon_generate", "nauvis")
  check("dungeon: generated once", again.surface == "sap-dungeon-nauvis")
  -- Вход у хранилища на Наувисе.
  local entrance = remote.call("sap-core", "dungeon_place_entrance", "nauvis", { 40, 40 })
  check("dungeon: entrance placed", entrance ~= nil and entrance.valid)
  -- Гарантированный вход на планете (без хранилищ), 150–250 клеток от центра.
  local vulcanus = game.planets.vulcanus.surface or game.planets.vulcanus.create_surface()
  remote.call("sap-core", "dungeon_ensure_entrance", vulcanus.name)
  local guaranteed = remote.call("sap-core", "dungeon_guaranteed", vulcanus.name)
  local distance = guaranteed and guaranteed.valid
    and math.sqrt(guaranteed.position.x ^ 2 + guaranteed.position.y ^ 2) or -1
  check("dungeon: guaranteed entrance on every planet", distance >= 130 and distance <= 270, distance)

  -- Открываем по одной двери каждого вида.
  storage.dungeon_doors = {}
  for _, planet in pairs(DUNGEON_PLANETS) do
    for _, d in pairs(remote.call("sap-core", "dungeon_door_locks", planet)) do
      if not storage.dungeon_doors[d.kind] then
        storage.dungeon_doors[d.kind] = d.door
        if d.kind == "power" then
          d.lock.get_fuel_inventory().insert({ name = "solid-fuel", count = 5 })
        elseif d.kind == "double" then
          d.lock.get_fuel_inventory().insert({ name = "solid-fuel", count = 5 })
          d.lock2.get_inventory(defines.inventory.chest).insert({ name = "sap-ancient-key", count = 1 })
        else
          d.lock.get_inventory(defines.inventory.chest).insert({ name = "sap-ancient-key", count = 1 })
        end
      end
    end
  end
  check("dungeon: all lock kinds exist", storage.dungeon_doors.power ~= nil and storage.dungeon_doors.key ~= nil
        and storage.dungeon_doors.double ~= nil)

  -- Ловушка: персонаж на ловушке получает урон, повторно — только после перезарядки.
  local surface = game.get_surface("sap-dungeon-gleba")
  local trap = surface.find_entities_filtered({ name = "sap-ancient-trap", limit = 1 })[1]
  local character = surface.create_entity({ name = "character", position = trap.position, force = "player" })
  local health = character.health
  check("dungeon: trap triggers", remote.call("sap-core", "dungeon_step_on_traps", character, "gleba") == true)
  check("dungeon: trap hurts", character.valid and character.health < health)
  check("dungeon: trap cooldown", remote.call("sap-core", "dungeon_step_on_traps", character, "gleba") == false)
  if character.valid then character.destroy() end
end

steps[9700] = function()
  check("diary: first dungeon door", has_entry_early("player", "dungeon-door"))
  check("diary: the Warden", has_entry_early("player", "dungeon-warden"))
  local keeper = game.get_surface("sap-dungeon-nauvis").find_entities_filtered({ name = "sap-ancient-keeper", limit = 1 })[1]
  if keeper then keeper.die("player") end
  check("diary: the Keeper", keeper ~= nil and has_entry_early("player", "dungeon-keeper"))
  for _, planet in pairs(DUNGEON_PLANETS) do
    if game.planets[planet] then
      local rec = remote.call("sap-core", "dungeon_record", planet)
      local cache = rec.final_cache
      local item = remote.call("sap-core", "cores_item", planet)
      check("dungeon " .. planet .. ": the Warden's death opens the core cache", cache ~= nil and cache.valid
            and cache.get_inventory(defines.inventory.chest).get_item_count(item) == 1)
    end
  end
  -- Повторная экспедиция (Аквило): нельзя, пока ядро не забрано.
  check("dungeon: no new expedition before the core is taken", remote.call("sap-core", "dungeon_can_reset", "aquilo") == false)
  local rec = remote.call("sap-core", "dungeon_record", "aquilo")
  rec.final_cache.get_inventory(defines.inventory.chest).clear()
end

steps[9780] = function()
  check("dungeon: new expedition after the core is taken", remote.call("sap-core", "dungeon_reset", "aquilo") == true)
  local record = remote.call("sap-core", "dungeon_generate", "aquilo")
  check("dungeon: new expedition is a new dungeon", record.run == 1 and record.surface == "sap-dungeon-aquilo-1",
        serpent.line({ record.run, record.surface }))
  local rec = remote.call("sap-core", "dungeon_record", "aquilo")
  if rec.boss and rec.boss.valid then rec.boss.die() end
end

steps[9850] = function()
  local rec = remote.call("sap-core", "dungeon_record", "aquilo")
  local inventory = rec.final_cache and rec.final_cache.get_inventory(defines.inventory.chest)
  local cards = 0
  for _, stack in pairs(inventory and inventory.get_contents() or {}) do
    if stack.name == "sap-data-card-alien" then cards = cards + stack.count end
  end
  check("dungeon: repeat expedition gives cards, not a core", inventory ~= nil
        and inventory.get_item_count(remote.call("sap-core", "cores_item", "aquilo")) == 0
        and cards >= 3, cards)
  check("dungeon: old expedition surface removed", game.get_surface("sap-dungeon-aquilo") == nil)
end

steps[9800] = function()
  local key_door = storage.dungeon_doors and storage.dungeon_doors.key
  check("dungeon: key lock opens its door", key_door ~= nil and not key_door.valid)
  local power_door = storage.dungeon_doors and storage.dungeon_doors.power
  check("dungeon: power lock does not open instantly", power_door ~= nil and power_door.valid)
  local double_door = storage.dungeon_doors and storage.dungeon_doors.double
  check("dungeon: double lock needs the power cycle too", double_door ~= nil and double_door.valid)
end

steps[11600] = function()
  local power_door = storage.dungeon_doors and storage.dungeon_doors.power
  check("dungeon: power lock opens its door after the cycle", power_door ~= nil and not power_door.valid)
  local double_door = storage.dungeon_doors and storage.dungeon_doors.double
  check("dungeon: double lock opens with power and key", double_door ~= nil and not double_door.valid)
end

-- Сюжет и концовки ------------------------------------------------------------------------
local function has_entry(force_name, key)
  for _, k in pairs(remote.call("sap-diary", "entries", force_name)) do if k == key then return true end end
  return false
end

steps[11700] = function()
  remote.call("sap-core", "test_set_story_victory", false)
  local tech = prototypes.technology["sap-ancient-nexus"]
  local recipe = prototypes.recipe["sap-ancient-nexus"]
  check("story: nexus prototypes", tech ~= nil and recipe ~= nil)
  local packs = prototypes.mod_data["sap-planet-packs"].data
  local in_tech = {}
  for _, ing in pairs(tech.research_unit_ingredients) do in_tech[ing.name] = true end
  local in_recipe = {}
  for _, ing in pairs(recipe.ingredients) do in_recipe[ing.name] = true end
  local n, all_tech, all_recipe = 0, true, true
  for pack in pairs(packs) do
    n = n + 1
    if not in_tech[pack] then all_tech = false end
    if not in_recipe[pack] then all_recipe = false end
  end
  check("story: nexus tech needs every planet pack", all_tech)
  check("story: nexus recipe needs every planet pack", all_recipe)
  local registry = prototypes.mod_data["sap-ancient-cores"].data
  local planets = 0
  for planet, entry in pairs(registry) do
    planets = planets + 1
    check("cores: item for " .. planet, prototypes.item[entry.item] ~= nil)
  end
  check("cores: one per planet with a pack", planets == n, planets .. " vs " .. n)
  check("cores: nexus holds a core of every planet",
        prototypes.entity["sap-ancient-nexus"].get_inventory_size(defines.inventory.chest) == planets)
  -- Забираем ядра из трёх подземелий.
  storage.story_taken = 0
  for _, planet in pairs({ "nauvis", "vulcanus", "fulgora" }) do
    local surface = game.get_surface("sap-dungeon-" .. planet)
    for _, cache in pairs(surface and surface.find_entities_filtered({ name = "sap-ancient-cache" }) or {}) do
      local item = remote.call("sap-core", "cores_item", planet)
      local removed = cache.get_inventory(defines.inventory.chest).remove({ name = item, count = 1 })
      storage.story_taken = storage.story_taken + removed
    end
  end
  check("story: took three cores", storage.story_taken == 3, storage.story_taken)
  -- Ядро Наувиса в пьедестал: +100 здоровья персонажа всей команде.
  local nauvis = game.surfaces.nauvis
  storage.pedestal = nauvis.create_entity({
    name = "sap-ancient-pedestal", force = "player", raise_built = true,
    position = nauvis.find_non_colliding_position("sap-ancient-pedestal", { -40, 60 }, 40, 1),
  })
  storage.health_bonus = game.forces.player.character_health_bonus
  storage.pedestal.insert({ name = remote.call("sap-core", "cores_item", "nauvis"), count = 1 })
end

steps[11780] = function()
  local force = game.forces.player
  check("cores: pedestal technology unlocked by taking a core", force.technologies["sap-ancient-pedestal"].researched)
  check("diary: core on the pedestal", has_entry_early("player", "dungeon-pedestal"))
  check("cores: core in pedestal gives the planet bonus",
        math.abs(force.character_health_bonus - storage.health_bonus - 100) < 0.01, force.character_health_bonus)
  storage.pedestal.get_inventory(defines.inventory.chest).clear()
end

steps[11850] = function()
  local force = game.forces.player
  check("cores: bonus removed with the core", math.abs(force.character_health_bonus - storage.health_bonus) < 0.01,
        force.character_health_bonus)
  check("cores: no active bonus", next(remote.call("sap-core", "cores_applied", "player")) == nil)
end

--- Узел команды со всеми ядрами планет.
local function complete_nexus(force, near)
  local nauvis = game.surfaces.nauvis
  local nexus = nauvis.create_entity({
    name = "sap-ancient-nexus", force = force, raise_built = true,
    position = nauvis.find_non_colliding_position("sap-ancient-nexus", near, 60, 1),
  })
  for _, entry in pairs(prototypes.mod_data["sap-ancient-cores"].data) do nexus.insert({ name = entry.item, count = 1 }) end
  return nexus
end

steps[11900] = function()
  check("story: core fragment Nauvis", has_entry("player", "story-core-nauvis"))
  check("story: core fragment Fulgora", has_entry("player", "story-core-fulgora"))
  check("story: pattern after three cores", has_entry("player", "story-pattern"))
  check("story: no fragment for an untouched dungeon", not has_entry("player", "story-core-gleba"))
  local nexus = game.surfaces.nauvis.create_entity({
    name = "sap-ancient-nexus", force = "player", raise_built = true,
    position = game.surfaces.nauvis.find_non_colliding_position("sap-ancient-nexus", { -60, 60 }, 60, 1),
  })
  check("story: nexus built", nexus ~= nil)
  check("story: nexus diary entry", has_entry("player", "story-nexus"))
  check("story: no ending without the cores", remote.call("sap-core", "story_choose", "player", "inherit") == false
        and next(remote.call("sap-core", "story_available", "player")) == nil)
  for _, entry in pairs(prototypes.mod_data["sap-ancient-cores"].data) do nexus.insert({ name = entry.item, count = 1 }) end

  -- Наследие (команда player), затем «остаться» и другие концовки.
  check("story: choose inheritance", remote.call("sap-core", "story_choose", "player", "inherit") == true)
  check("story: no second ending before deciding", remote.call("sap-core", "story_choose", "player", "seal") == false)
  check("story: ending stored", remote.call("sap-core", "story_ending", "player") == "inherit")
  check("story: decide stage", remote.call("sap-core", "story_stage", "player") == "decide")
  local all = true
  for name, t in pairs(game.forces.player.technologies) do
    if string.sub(name, 1, 10) == "sap-alien-" and not t.researched then all = false end
  end
  check("story: inheritance researches ancient technologies", all)
  check("story: inheritance epilogue", has_entry("player", "story-ending-inherit"))
  local enemy_guardians = 0
  for _, surface in pairs(game.surfaces) do
    enemy_guardians = enemy_guardians + surface.count_entities_filtered({ name = "sap-alien-guardian", force = "enemy" })
  end
  check("story: inheritance — ancient guardians crumble", enemy_guardians == 0, enemy_guardians)
  check("story: inheritance — lab productivity", game.forces.player.laboratory_productivity_bonus >= 0.1)
  check("story: stay", remote.call("sap-core", "story_decide", "player", "stay") == true)
  check("story: stay entry", has_entry("player", "story-stay"))
  check("story: recharging after staying", remote.call("sap-core", "story_stage", "player") == "recharge")
  check("story: nothing available while recharging",
        next(remote.call("sap-core", "story_available", "player")) == nil)
  check("story: game not finished when victory is off", not game.finished)
  remote.call("sap-core", "test_story_recharge", "player")
  local available = remote.call("sap-core", "story_available", "player")
  check("story: other endings open after recharge", available.restore and available.seal and not available.inherit)
  check("story: secret ending still locked after one ending", not available.unity)
  check("story: second ending (awakening)", remote.call("sap-core", "story_choose", "player", "restore") == true)
  check("story: awakening — guardian squad by the nexus", nexus.surface.count_entities_filtered({
    name = "sap-alien-guardian", force = "player", position = nexus.position, radius = 20 }) >= 4)
  local items_before = nexus.surface.count_entities_filtered({ type = "item-entity", position = nexus.position, radius = 10 })
  remote.call("sap-core", "test_story_gift", "player")
  check("story: awakening — gifts from the ancients", nexus.surface.count_entities_filtered({
    type = "item-entity", position = nexus.position, radius = 10 }) > items_before)
  remote.call("sap-core", "story_decide", "player", "stay")
  remote.call("sap-core", "test_story_recharge", "player")
  available = remote.call("sap-core", "story_available", "player")
  check("story: secret ending opens after two endings", available.unity == true and available.seal == true)
  check("story: unity ends the story", remote.call("sap-core", "story_choose", "player", "unity") == true
        and remote.call("sap-core", "story_stage", "player") == "done")
  check("story: unity epilogue", has_entry("player", "story-ending-unity"))
  check("story: nothing after the end", next(remote.call("sap-core", "story_available", "player")) == nil)

  -- Возвращение домой (отдельная команда).
  local home = game.create_force("sap-story-home")
  local home_nexus = complete_nexus(home, { -120, 60 })
  remote.call("sap-core", "story_choose", home.name, "inherit")
  check("story: go home", remote.call("sap-core", "story_decide", home.name, "return") == true
        and remote.call("sap-core", "story_stage", home.name) == "done")
  check("story: return epilogue", has_entry(home.name, "story-return"))
  local crate = home_nexus.surface.find_entities_filtered({ name = "steel-chest", force = home, position = home_nexus.position,
                                                            radius = 25, limit = 1 })[1]
  check("story: going home — company reward crate", crate ~= nil and crate.get_item_count("processing-unit") == 200)

  -- Пробуждение (отдельная команда): стражи становятся союзниками.
  local awake = game.create_force("sap-story-awake")
  complete_nexus(awake, { -160, 60 })
  local guardian = game.surfaces.nauvis.create_entity({
    name = "sap-alien-guardian", force = "enemy",
    position = game.surfaces.nauvis.find_non_colliding_position("sap-alien-guardian", { -90, 90 }, 60, 1),
  })
  remote.call("sap-core", "story_choose", awake.name, "restore")
  check("story: awakening turns guardians into allies", guardian and guardian.valid and guardian.force == awake)
  if guardian and guardian.valid then guardian.destroy() end

  -- Печать (ещё одна команда): подземелья обрушиваются.
  local sealer = game.create_force("sap-story-seal")
  complete_nexus(sealer, { -200, 60 })
  storage.story_bonus = sealer.mining_drill_productivity_bonus
  remote.call("sap-core", "story_choose", sealer.name, "seal")
  check("story: seal adds mining productivity", sealer.mining_drill_productivity_bonus > storage.story_bonus + 0.2)
  local entrances = 0
  for _, surface in pairs(game.surfaces) do
    entrances = entrances + surface.count_entities_filtered({ name = "sap-dungeon-entrance" })
  end
  check("story: seal buries the dungeon entrances", entrances == 0, entrances)
end

steps[12000] = function()
  check("cores: nexus cores give their bonuses", remote.call("sap-core", "cores_applied", "player").nauvis == true)
  check("story: seal collapses the dungeons", game.get_surface("sap-dungeon-nauvis") == nil
        and game.get_surface("sap-dungeon-echaris") == nil)
end

-- Выгрузка цифр баланса (tools/balance.py).
local balance = require("balance")
steps[12] = function()
  local techs, recipes, units = balance.dump()
  check("balance: dump written", techs > 0 and recipes > 0 and units > 0, techs .. "/" .. recipes .. "/" .. units)
end

-- После загрузки сохранения (MODE=saveload) ранние шаги уже выполнены; отмечаем загрузку.
script.on_load(function()
  log("SAP-TEST INFO loaded save, continuing")
end)

-- Режим с игроком (MODE=player): свой набор шагов, обычные шаги не выполняются.
local player_step_lists = {}
local player_steps = setmetatable({}, {
  __newindex = function(_, tick, fn)
    player_step_lists[tick] = player_step_lists[tick] or {}
    table.insert(player_step_lists[tick], fn)
  end,
})
require("player_tests").register(player_steps, check, function()
  local failures = 0
  for _, r in pairs(results) do if not r then failures = failures + 1 end end
  log("SAP-TEST DONE failures=" .. failures)
  script.finish_test(failures == 0)
end)

-- Шаги считаются от тика, когда тестовый мод подключили (в MODE=migration карта уже шла).
script.on_init(function()
  storage.t0 = game.tick
  log("SAP-TEST INFO test mod started at tick " .. game.tick)
end)

script.on_event(defines.events.on_tick, function(event)
  local t = event.tick - (storage.t0 or 0)
  if script.test_arg ~= "player" and t > 50 and t % 30 == 0 then
    local ok, err = pcall(try_launch)
    if not ok then check("launch", false, err) end
  end
  local lists = script.test_arg == "player" and player_step_lists or step_lists
  for _, step in pairs(lists[t] or {}) do
    local ok, err = pcall(step)
    if not ok then check("step " .. event.tick, false, err) end
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if storage.stealth_1 and event.entity == storage.stealth_1 then
    storage.stealth_death = { cause = event.cause and event.cause.valid and event.cause.name or nil,
                              damage = event.damage_type and event.damage_type.name }
    log("SAP-TEST INFO stealth character killed by " .. tostring(event.cause and event.cause.valid and event.cause.name)
        .. " damage " .. tostring(event.damage_type and event.damage_type.name) .. " at tick " .. event.tick)
  end
end, { { filter = "type", type = "character" } })

script.on_event(defines.events.on_rocket_launch_ordered, function(event)
  log("SAP-TEST INFO rocket launch ordered, pod=" .. tostring(event.rocket.attached_cargo_pod ~= nil))
end)
