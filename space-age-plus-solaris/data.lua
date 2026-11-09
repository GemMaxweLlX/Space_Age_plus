-- space-age-plus-solaris: прототипы (Solaris — планета у Солнца).
-- Модуль пока заготовка. Здесь будут: planet, space-connection, autoplace ресурсов,
-- существа и гнёзда, постройки и технологии планеты.

-- Регистрация планеты в системе кислорода ядра (space-age-plus-core).
-- "generator" — как планета решает проблему воздуха (см. docs: Кислород → По планетам).
local sap = require("__space-age-plus-core__.prototypes.api")
sap.register_oxygen_planet("solaris", { solution = "generator" })
