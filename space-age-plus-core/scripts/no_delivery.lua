-- Хардкор «Без доставки с платформы» (docs: Глобальные механики → Хардкор; Echaris, Nivar).
-- Грузовая капсула, которая улетает с платформы на планету с включённой настройкой,
-- разворачивается обратно в хаб своей платформы. Капсулы с игроком не трогаем.

local no_delivery = {}

local function rules()
  local proto = prototypes.mod_data["sap-no-delivery-planets"]
  return proto and proto.data or {}
end

local function forbidden(surface_name, force)
  local rule = rules()[surface_name]
  if not rule then return false end
  if storage.no_delivery_override and storage.no_delivery_override[surface_name] then return true end
  if rule.unless_tech then
    local tech = force.technologies[rule.unless_tech]
    if tech and tech.researched then return false end
  end
  if rule.setting then
    return settings.startup[rule.setting] and settings.startup[rule.setting].value == true
  end
  return true
end

local function target_surface(destination)
  if not destination then return nil end
  if destination.surface then return destination.surface end
  if destination.station and destination.station.valid then return destination.station.surface end
  return nil
end

--- Проверяет капсулу; возвращает true, если она развёрнута.
function no_delivery.check_pod(pod, player_index)
  if not (pod and pod.valid) or player_index then return false end
  local origin = pod.cargo_pod_origin
  if not (origin and origin.valid and origin.surface.platform) then return false end
  local target = target_surface(pod.cargo_pod_destination)
  if not (target and forbidden(target.name, origin.force)) then return false end
  pod.cargo_pod_destination = { type = defines.cargo_destination.station, station = origin }
  local rule = rules()[target.name]
  if rule.unless_tech then
    origin.force.print({ "sap-no-delivery.needs-tech", { "space-location-name." .. target.name },
                         { "technology-name." .. rule.unless_tech } })
  else
    origin.force.print({ "sap-no-delivery.returned", { "space-location-name." .. target.name } })
  end
  return true
end

function no_delivery.on_cargo_pod_finished_ascending(event)
  no_delivery.check_pod(event.cargo_pod, event.player_index)
end

--- Для тестов: включить запрет для поверхности без изменения настроек.
function no_delivery.set_override(surface_name, value)
  storage.no_delivery_override = storage.no_delivery_override or {}
  storage.no_delivery_override[surface_name] = value
end

return no_delivery
