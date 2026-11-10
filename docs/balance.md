# Баланс Space Age+

Все цифры в одном месте. Файл собирается автоматически (`tools/balance.py`) из прототипов игры
и констант в скриптах — правьте исходники, затем пересоберите. Версии технологий по качеству
(`-sap-uncommon` … `-sap-legendary`) стоят дороже обычной и в таблицу не включены.

## Технологии

| Технология | Стоимость | Время | Колбы | Требования |
|---|---|---|---|---|
| Ускоренная переработка (`sap-accelerated-processing`) | 700 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |
| Аккумулятор Mk2 (`sap-accumulator-mk2`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | electric-energy-accumulators, sap-planet-discovery-echaris |
| Инопланетный протокол консервации (`sap-alien-conservation`) | 1500 | 60 | red, green, blue, space | space-science-pack |
| Дрейфовые двигатели (`sap-alien-drift-engines`) | 2000 | 60 | red, green, blue, space | space-science-pack |
| Инопланетная геометрия недр (`sap-alien-geometry`) | 1500 | 60 | red, green, blue, space | space-science-pack |
| Хват древних (`sap-alien-grip`) | 2500 | 60 | red, green, blue, space | space-science-pack |
| Инопланетная несущая решётка (`sap-alien-lattice`) | 2000 | 60 | red, green, blue, space | space-science-pack |
| Резонанс знаний (`sap-alien-resonance`) | 3000 | 60 | red, green, blue, space | space-science-pack |
| Поле стазиса (`sap-alien-stasis-field`) | 2000 | 60 | red, green, blue, space | space-science-pack |
| Древний узел (`sap-ancient-nexus`) | 1000 | 60 | red, green, blue, space, pioneer, tectonic, ionic, symbiotic, cryostasis, thermal, cybernetic, hydro, deep | sap-alien-resonance, sap-cryostasis-science-pack, sap-cybernetic-science-pack, sap-deep-science-pack, sap-hydro-science-pack, sap-ionic-science-pack, sap-pioneer-science-pack, sap-symbiotic-science-pack, sap-tectonic-science-pack, sap-thermal-science-pack, space-science-pack |
| Древний пьедестал (`sap-ancient-pedestal`) | триггер: scripted |  |  |  |
| Архивный дешифратор (`sap-archive-decipherer`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris |
| Сборочный автомат Mk2+ (`sap-assembling-machine-mk2plus`) | 1200 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | automation-3, sap-planet-discovery-echaris |
| Биолюминесцентные водоросли (`sap-bioluminescent-algae`) | 800 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-sea-salt-preservation |
| `sap-capture-recalibration-aquara` | 500 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | captivity, sap-hydro-science-pack, sap-planet-discovery-aquara, sap-symbiotic-science-pack |
| `sap-capture-recalibration-nivar` | 500 | 60 | red, green, blue, space, agricultural, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | captivity, sap-cryostasis-science-pack, sap-deep-science-pack, sap-ionic-science-pack, sap-planet-discovery-nivar, sap-symbiotic-science-pack, sap-tectonic-science-pack |
| `sap-capture-recalibration-nivar-caves` | 500 | 60 | red, green, blue, space, agricultural, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | captivity, sap-planet-discovery-nivar |
| `sap-capture-recalibration-solaris` | 500 | 60 | red, green, blue, space, metallurgic, agricultural, tectonic, symbiotic, thermal | captivity, sap-planet-discovery-solaris, sap-symbiotic-science-pack, sap-tectonic-science-pack, sap-thermal-science-pack |
| Панцирная броня Aquara (`sap-carapace-armor`) | 600 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |
| Пещерная броня (`sap-cave-armor`) | 600 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Пещерный конвейер (`sap-cave-belt`) | 500 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Центрифуга Mk2 (`sap-centrifuge-mk2`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris, uranium-processing |
| Цистерна (`sap-cistern`) | 150 | 30 | red, green | fluid-handling |
| Зонтик защиты (`sap-coronal-umbrella`) | 600 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | lightning-collector, sap-ionic-science-pack, sap-planet-discovery-solaris |
| Зонтик Mk2 (`sap-coronal-umbrella-mk2`) | 800 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-coronal-umbrella, sap-planet-discovery-solaris |
| Криоброня (`sap-cryo-armor`) | 800 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | power-armor, sap-planet-discovery-nivar |
| Криозащитный купол (`sap-cryo-dome`) | 1000 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Криообогреватель Mk2 (`sap-cryo-heater-mk2`) | 700 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Криопроводящая труба (`sap-cryo-pipe`) | 400 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Криостазисная колба (`sap-cryostasis-science-pack`) | триггер: craft-item |  |  | cryogenic-science-pack |
| Кибернетическая колба (`sap-cybernetic-science-pack`) | триггер: craft-item |  |  | sap-planet-discovery-echaris |
| Переработка космического мусора (`sap-debris-recycling`) | 200 | 30 | red, green, blue, pioneer | sap-pioneer-science-pack, space-platform |
| Дешифратор (`sap-decipherer`) | 30 | 10 | red | automation-science-pack |
| Глубинный бур (`sap-deep-drill`) | 800 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-cryostasis-science-pack, sap-deep-science-pack, sap-ionic-science-pack, sap-planet-discovery-nivar, sap-symbiotic-science-pack, sap-tectonic-science-pack |
| Глубинный бур Mk2 (`sap-deep-drill-mk2`) | 1000 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-deep-drill, sap-planet-discovery-nivar |
| Глубинная колба (`sap-deep-science-pack`) | триггер: craft-item |  |  | sap-planet-discovery-nivar |
| Разрядник Echaris (`sap-echaris-discharger`) | 1200 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris, tesla-weapons |
| Экзоскелет Echaris (`sap-echaris-exoskeleton`) | 1500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | power-armor-mk2, sap-planet-discovery-echaris |
| Дроны Mk2 (`sap-echaris-robots-mk2`) | 1500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | construction-robotics, sap-cybernetic-science-pack, sap-ionic-science-pack, sap-planet-discovery-echaris |
| Электропечь Mk2 (`sap-electric-furnace-mk2`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | advanced-material-processing-2, sap-planet-discovery-echaris |
| Электромагнитная турель (`sap-em-turret`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | laser-turret, sap-planet-discovery-echaris |
| Зенитная ЭМИ-пушка (`sap-emp-flak-cannon`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | rocket-turret, sap-planet-discovery-echaris, sap-symbiotic-science-pack |
| ЭМИ-граната (`sap-emp-grenade`) | 500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | military-2, sap-planet-discovery-echaris |
| Огнеупорная стена (`sap-fireproof-wall`) | 500 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris, sap-thermite-mk2 |
| Силовой барьер (`sap-force-barrier`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, cybernetic | sap-cybernetic-science-pack, sap-ionic-science-pack, sap-planet-discovery-echaris |
| Силовой барьер Mk2 (`sap-force-barrier-mk2`) | 1500 | 60 | red, green, blue, space, electromagnetic, ionic, cybernetic | sap-force-barrier |
| Термотрубка Mk2 (`sap-heat-pipe-mk2`) | 700 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | nuclear-power, sap-planet-discovery-solaris |
| Жаропрочная броня (`sap-heat-resistant-armor`) | 500 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris |
| Жаропрочный конвейер (`sap-heat-resistant-belt`) | 800 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris, turbo-transport-belt |
| Система жидкостей высокого класса (`sap-high-grade-fluids`) | 800 | 60 | red, green, blue, space, metallurgic, tectonic, thermal | metallurgic-science-pack, sap-planet-discovery-solaris, sap-tectonic-science-pack, sap-thermal-science-pack |
| Гидробиологическая колба (`sap-hydro-science-pack`) | триггер: craft-item |  |  | sap-planet-discovery-aquara |
| Улучшенная капсула доставки (`sap-improved-delivery-capsule`) | 500 | 60 | red, green, blue, space, metallurgic, tectonic, thermal | sap-planet-discovery-solaris, sap-tectonic-science-pack, sap-thermal-science-pack |
| Термоизоляционная стена (`sap-insulated-wall`) | 500 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Изолирующий фундамент (`sap-insulating-foundation`) | 500 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Ионная колба (`sap-ionic-science-pack`) | триггер: craft-item |  |  | electromagnetic-science-pack |
| Логистический маяк Mk2 (`sap-logistic-beacon-mk2`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris, sap-roboport-mk2 |
| Взлом Механитов (`sap-mechanite-hacking`) | 1500 | 60 | red, green, blue, space, electromagnetic, ionic, cybernetic | sap-emp-grenade |
| Модульный реактор (`sap-modular-reactor`) | 1500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | nuclear-power, sap-planet-discovery-echaris |
| Нивалитовый провод (`sap-nivalite-wire`) | 600 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis, deep | sap-planet-discovery-nivar |
| Системы жизнеобеспечения (`sap-oxygen-systems`) | 300 | 30 | red, green, blue, pioneer | sap-pioneer-science-pack, space-platform |
| Колба первопроходца (`sap-pioneer-science-pack`) | триггер: craft-item |  |  | advanced-circuit |
| Открытие Aquara (`sap-planet-discovery-aquara`) | 1000 | 60 | red, green, blue, space, agricultural, symbiotic | agricultural-science-pack, sap-oxygen-systems, sap-symbiotic-science-pack |
| Открытие Echaris (`sap-planet-discovery-echaris`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic | electromagnetic-science-pack, sap-ionic-science-pack, sap-oxygen-systems |
| Открытие Nivar (`sap-planet-discovery-nivar`) | 1500 | 60 | red, green, blue, space, cryogenic, tectonic, ionic, symbiotic, cryostasis | cryogenic-science-pack, sap-cryostasis-science-pack, sap-ionic-science-pack, sap-oxygen-systems, sap-symbiotic-science-pack, sap-tectonic-science-pack |
| Открытие Solaris (`sap-planet-discovery-solaris`) | 1000 | 60 | red, green, blue, space, metallurgic, tectonic | metallurgic-science-pack, sap-oxygen-systems, sap-tectonic-science-pack |
| Плазменный карабин (`sap-plasma-carbine`) | 600 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | military-3, sap-planet-discovery-echaris |
| Башня-ретранслятор энергии (`sap-power-relay-tower`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | electric-energy-distribution-2, sap-planet-discovery-echaris |
| Радар Mk2 (`sap-radar-mk2`) | 500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | radar, sap-planet-discovery-echaris |
| Радиатор Mk2 (`sap-radiator-mk2`) | 600 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris |
| Захватчик луча (`sap-ray-catcher`) | 1000 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-coronal-umbrella |
| Роботодок Mk2 (`sap-roboport-mk2`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-echaris-robots-mk2, sap-planet-discovery-echaris |
| Спутник 1 поколения (`sap-satellite-mk1`) | 500 | 30 | red, green, blue, purple, yellow, pioneer | rocket-silo, sap-pioneer-science-pack, sap-telescope |
| Спутник 2 поколения (`sap-satellite-mk2`) | 1000 | 30 | red, green, blue, purple, yellow, space, pioneer | sap-pioneer-science-pack, sap-satellite-mk1 |
| Консервация морской солью (`sap-sea-salt-preservation`) | 500 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-hydro-science-pack, sap-planet-discovery-aquara, sap-symbiotic-science-pack |
| Протокол тихого захвата (`sap-silent-capture-protocol`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, cybernetic | sap-stealth-suit |
| Солнечная панель Mk2 (`sap-solar-panel-mk2`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris, solar-energy |
| Костюм стелса (`sap-stealth-suit`) | 800 | 60 | red, green, blue, space, electromagnetic, ionic, cybernetic | sap-planet-discovery-echaris |
| Паровая турбина Mk2 (`sap-steam-turbine-mk2`) | 600 | 60 | red, green, blue, purple, pioneer | low-density-structure, nuclear-power, sap-pioneer-science-pack |
| Хранилище жидкости Mk2 (`sap-storage-tank-mk2`) | 500 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | fluid-handling, sap-planet-discovery-echaris |
| Штормовой якорь (`sap-storm-anchor`) | 1000 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | electric-energy-accumulators, sap-storm-shield |
| Штормовой якорь Mk2 (`sap-storm-anchor-mk2`) | 1000 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara, sap-storm-anchor |
| Штормовой прогнозатор (`sap-storm-forecaster`) | 400 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-storm-shield |
| Штормовой щит (`sap-storm-shield`) | 600 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |
| Сверхбойлер (`sap-super-boiler`) | 1200 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | nuclear-power, sap-ionic-science-pack, sap-ray-catcher, sap-tectonic-science-pack, sap-thermal-science-pack |
| Сверхбойлер Mk2 (`sap-super-boiler-mk2`) | 2000 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-super-boiler |
| Турель-подавитель (`sap-suppressor-turret`) | 1000 | 60 | red, green, blue, space, electromagnetic, ionic, symbiotic, cybernetic | sap-planet-discovery-echaris, tesla-weapons |
| Симбиотическая колба (`sap-symbiotic-science-pack`) | триггер: craft-item |  |  | agricultural-science-pack |
| Тектоническая колба (`sap-tectonic-science-pack`) | триггер: craft-item |  |  | metallurgic-science-pack |
| Телескоп (`sap-telescope`) | 100 | 15 | red, green | logistic-science-pack |
| `sap-test-categorized-tech` | 10 | 5 | red, green | logistic-science-pack |
| `sap-test-visible-tech` | 10 | 5 | red, green | logistic-science-pack |
| Термическая колба (`sap-thermal-science-pack`) | триггер: craft-item |  |  | sap-planet-discovery-solaris |
| Термит (`sap-thermite`) | 500 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris, sap-tectonic-science-pack, sap-thermal-science-pack |
| Термит Mk2 (`sap-thermite-mk2`) | 600 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-thermite |
| Термоэлектрический генератор (`sap-thermoelectric-generator`) | 700 | 60 | red, green, blue, space, metallurgic, tectonic, ionic, thermal | sap-planet-discovery-solaris, solar-energy |
| Подводный бур (`sap-underwater-drill`) | 700 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |
| Переработка ядовитых желёз (`sap-venom-processing`) | 500 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |
| Водная башня Mk2 (`sap-water-tower-mk2`) | 700 | 60 | red, green, blue, space, agricultural, symbiotic, hydro | sap-planet-discovery-aquara |

## Рецепты

| Рецепт | Время, с | Ингредиенты | Результат | Условия |
|---|---|---|---|---|
| Аккумулятор Mk2 (`sap-accumulator-mk2`) | 10 | 5 sap-mechanite-scrap, 2 supercapacitor, 2 accumulator | 1 sap-accumulator-mk2 |  |
| Концентратор воздуха (`sap-air-concentrator`) | 2 | 1 steel-plate, 1 lithium-plate | 1 sap-air-concentrator |  |
| Воздушный фильтр (`sap-air-filter`) | 2 | 1 iron-plate, 1 carbon | 1 sap-air-filter |  |
| Питательные вещества из водорослей (`sap-algae-nutrients`) | 2 | 2 sap-green-algae | 4 nutrients |  |
| Древний узел (`sap-ancient-nexus`) | 60 | 50 processing-unit, 10 sap-pioneer-science-pack, 10 sap-tectonic-science-pack, 10 sap-ionic-science-pack, 10 sap-symbiotic-science-pack, 10 sap-cryostasis-science-pack, 10 sap-thermal-science-pack, 10 sap-cybernetic-science-pack, 10 sap-hydro-science-pack, 10 sap-deep-science-pack, 100 refined-concrete | 1 sap-ancient-nexus |  |
| Древний пьедестал (`sap-ancient-pedestal`) | 10 | 20 steel-plate, 10 advanced-circuit | 1 sap-ancient-pedestal |  |
| `sap-aquara-food` | 4 | 1 bioflux, 2 sap-green-algae, 1 sap-sea-salt | 2 sap-aquara-food |  |
| Сборочный автомат Mk2+ (`sap-assembling-machine-mk2plus`) | 10 | 2 sap-mechanite-core, 5 superconductor, 1 assembling-machine-3 | 1 sap-assembling-machine-mk2plus |  |
| Атмосферный коллектор (`sap-atmospheric-collector`) | 5 | 10 steel-plate, 10 electronic-circuit, 10 pipe | 1 sap-atmospheric-collector |  |
| Биокамера Mk2 (`sap-biochamber-mk2`) | 10 | 5 sap-venom-gland, 1 biochamber | 1 sap-biochamber-mk2 |  |
| Биофильтр (`sap-biofilter`) | 2 | 1 plastic-bar, 2 yumako-mash | 1 sap-biofilter |  |
| Биолюминесцентные водоросли (`sap-bioluminescent-algae`) | 12 | 1 bioflux, 200 water | 2 sap-bioluminescent-algae | pressure 1800-1800 |
| Биофлюс из биолюминесцентных водорослей (`sap-bioluminescent-bioflux`) | 6 | 3 sap-bioluminescent-algae | 1 bioflux |  |
| `sap-capture-rocket-aquara` | 10 | 5 sap-sea-salt, 1 capture-robot-rocket | 1 sap-capture-rocket-aquara |  |
| `sap-capture-rocket-nivar` | 10 | 4 sap-cryolite, 1 capture-robot-rocket | 1 sap-capture-rocket-nivar |  |
| `sap-capture-rocket-nivar-caves` | 10 | 4 sap-dark-ice, 1 capture-robot-rocket | 1 sap-capture-rocket-nivar-caves |  |
| `sap-capture-rocket-solaris` | 10 | 2 sap-heat-resistant-alloy, 1 capture-robot-rocket | 1 sap-capture-rocket-solaris |  |
| Панцирная броня Aquara (`sap-carapace-armor`) | 10 | 30 sap-carapace, 1 modular-armor | 1 sap-carapace-armor |  |
| Пещерная броня (`sap-cave-armor`) | 10 | 5 sap-cryo-gland, 10 sap-ice-spike, 1 heavy-armor | 1 sap-cave-armor |  |
| Пещерный конвейер (`sap-cave-belt`) | 1 | 1 sap-cryolite, 1 express-transport-belt | 1 sap-cave-belt |  |
| Центрифуга Mk2 (`sap-centrifuge-mk2`) | 10 | 5 sap-nivalite, 2 sap-mechanite-core, 1 centrifuge | 1 sap-centrifuge-mk2 |  |
| Цистерна (`sap-cistern`) | 4 | 5 steel-plate | 1 sap-cistern |  |
| Строительный дрон Mk2 (`sap-construction-robot-mk2`) | 10 | 2 sap-nivalite, 1 sap-mechanite-core, 1 construction-robot | 1 sap-construction-robot-mk2 |  |
| Зонтик защиты (`sap-coronal-umbrella`) | 10 | 10 sap-heat-resistant-alloy, 2 lightning-rod | 1 sap-coronal-umbrella |  |
| Зонтик Mk2 (`sap-coronal-umbrella-mk2`) | 10 | 10 sap-heat-resistant-alloy, 2 sap-coronal-umbrella | 1 sap-coronal-umbrella-mk2 |  |
| `sap-crude-oil-cistern` | 1 | 1 sap-cistern, 500 crude-oil | 1 sap-crude-oil-cistern |  |
| Криоброня (`sap-cryo-armor`) | 10 | 30 sap-cryo-carapace, 20 sap-nivalite-wire, 1 power-armor | 1 sap-cryo-armor |  |
| Криоконцентратор (`sap-cryo-concentrator`) | 2 | 1 sap-cryolite, 1 steel-plate, 1 lithium-plate | 1 sap-cryo-concentrator |  |
| Криозащитный купол (`sap-cryo-dome`) | 10 | 20 sap-dark-ice, 10 processing-unit, 10 lithium-plate, 4 sap-cryo-heater | 1 sap-cryo-dome |  |
| Криообогреватель (`sap-cryo-heater`) | 5 | 5 sap-cryolite, 2 lithium-plate, 4 heat-pipe | 1 sap-cryo-heater |  |
| Криообогреватель Mk2 (`sap-cryo-heater-mk2`) | 10 | 10 sap-nivalite-wire, 2 sap-cryo-heater | 1 sap-cryo-heater-mk2 |  |
| Криолампа (`sap-cryo-lamp`) | 2 | 2 sap-cryolite, 1 small-lamp | 1 sap-cryo-lamp |  |
| Криопроводящая труба (`sap-cryo-pipe`) | 1 | 1 sap-cryolite, 1 pipe | 1 sap-cryo-pipe |  |
| Криопроводящая подземная труба (`sap-cryo-pipe-to-ground`) | 2 | 4 sap-cryolite, 2 pipe-to-ground | 2 sap-cryo-pipe-to-ground |  |
| Криостазисная колба (`sap-cryostasis-science-pack`) | 10 | 2 ice, 1 lithium-plate, 20 ammoniacal-solution | 2 sap-cryostasis-science-pack | pressure 300-300 |
| Кибернетическая колба (`sap-cybernetic-science-pack`) | 10 | 3 sap-mechanite-scrap, 1 sap-mechanite-core, 1 supercapacitor | 2 sap-cybernetic-science-pack | pressure 600-600 |
| Дробление: Мусор с биоплёнкой (`sap-debris-biofilm-crushing`) | 2 | 1 sap-debris-biofilm | 3 spoilage, 2 nutrients, 1 sap-green-algae |  |
| Дробление: Наэлектризованный мусор (`sap-debris-electrified-crushing`) | 2 | 1 sap-debris-electrified | 6 copper-cable, 1 supercapacitor, 1 sap-mechanite-scrap |  |
| Дробление электронного мусора (`sap-debris-electronic-crushing`) | 2 | 1 sap-debris-electronic | 4 copper-cable, 1 electronic-circuit, 1 advanced-circuit, 1 processing-unit |  |
| Дробление: Замёрзший мусор (`sap-debris-frozen-crushing`) | 2 | 1 sap-debris-frozen | 4 ice, 1 iron-plate, 1 sap-cryolite |  |
| Дробление: Раскалённый мусор (`sap-debris-heated-crushing`) | 2 | 1 sap-debris-heated | 3 iron-plate, 1 tungsten-plate, 1 sap-heat-resistant-crystal |  |
| Дробление металлического мусора (`sap-debris-metal-crushing`) | 2 | 1 sap-debris-metal | 3 iron-plate, 2 copper-plate, 1 steel-plate |  |
| Дробление ракетных обломков (`sap-debris-rocket-crushing`) | 2 | 1 sap-debris-rocket | 3 steel-plate, 1 low-density-structure, 2 plastic-bar, 1 rocket-fuel |  |
| Дешифратор (`sap-decipherer`) | 5 | 10 iron-gear-wheel, 20 copper-cable, 20 electronic-circuit | 1 sap-decipherer |  |
| Глубинные водоросли (`sap-deep-algae`) | 10 | 1 sap-sea-salt, 300 water | 3 sap-deep-algae | pressure 1800-1800 |
| Газ из глубинных водорослей (`sap-deep-algae-gas`) | 4 | 4 sap-deep-algae | 60 petroleum-gas |  |
| Глубинный бур (`sap-deep-drill`) | 20 | 10 processing-unit, 10 lithium-plate, 4 electric-mining-drill | 1 sap-deep-drill |  |
| Глубинный бур Mk2 (`sap-deep-drill-mk2`) | 10 | 1 sap-guardian-core, 20 sap-nivalite-wire, 1 sap-deep-drill | 1 sap-deep-drill-mk2 |  |
| Глубинное бурение: криолит (`sap-deep-drilling-cryolite`) | 4 |  | 2 sap-cryolite | pressure 250-250 |
| Глубинное бурение: тёмный лёд (`sap-deep-drilling-dark-ice`) | 3 |  | 2 sap-dark-ice | pressure 250-250 |
| Глубинное бурение: нивалит (`sap-deep-drilling-nivalite`) | 4 |  | 1 sap-nivalite | pressure 250-250 |
| Глубинная колба (`sap-deep-science-pack`) | 10 | 1 sap-cryolite, 2 sap-dark-ice, 2 sap-nivalite | 2 sap-deep-science-pack | pressure 250-250 |
| Осушитель (`sap-dehumidifier`) | 2 | 1 carbon-fiber, 2 sap-sea-salt | 1 sap-dehumidifier |  |
| Разрядник Echaris (`sap-echaris-discharger`) | 10 | 3 sap-mechanite-core, 1 tesla-turret | 1 sap-echaris-discharger |  |
| Экзоскелет Echaris (`sap-echaris-exoskeleton`) | 10 | 20 sap-nivalite, 10 sap-mechanite-core, 1 power-armor-mk2 | 1 sap-echaris-exoskeleton |  |
| Электропечь Mk2 (`sap-electric-furnace-mk2`) | 10 | 5 sap-mechanite-scrap, 2 supercapacitor, 1 electric-furnace | 1 sap-electric-furnace-mk2 |  |
| Электромагнитная турель (`sap-em-turret`) | 10 | 2 sap-mechanite-core, 5 superconductor, 1 laser-turret | 1 sap-em-turret |  |
| ЭМИ-фильтр (`sap-emp-filter`) | 2 | 4 copper-cable, 1 supercapacitor | 1 sap-emp-filter |  |
| Зенитная ЭМИ-пушка (`sap-emp-flak-cannon`) | 10 | 2 sap-mechanite-core, 5 supercapacitor, 1 rocket-turret | 1 sap-emp-flak-cannon |  |
| ЭМИ-граната (`sap-emp-grenade`) | 10 | 2 sap-mechanite-scrap, 1 supercapacitor, 1 grenade | 2 sap-emp-grenade |  |
| `sap-empty-crude-oil-cistern` | 1 | 1 sap-crude-oil-cistern | 1 sap-cistern, 500 crude-oil |  |
| `sap-empty-fluoroketone-cold-cistern` | 1 | 1 sap-fluoroketone-cold-cistern | 1 sap-cistern, 500 fluoroketone-cold |  |
| `sap-empty-fluoroketone-hot-cistern` | 1 | 1 sap-fluoroketone-hot-cistern | 1 sap-cistern, 500 fluoroketone-hot |  |
| `sap-empty-heavy-oil-cistern` | 1 | 1 sap-heavy-oil-cistern | 1 sap-cistern, 500 heavy-oil |  |
| `sap-empty-light-oil-cistern` | 1 | 1 sap-light-oil-cistern | 1 sap-cistern, 500 light-oil |  |
| `sap-empty-lubricant-cistern` | 1 | 1 sap-lubricant-cistern | 1 sap-cistern, 500 lubricant |  |
| `sap-empty-petroleum-gas-cistern` | 1 | 1 sap-petroleum-gas-cistern | 1 sap-cistern, 500 petroleum-gas |  |
| `sap-empty-sap-molten-metal-cistern` | 1 | 1 sap-sap-molten-metal-cistern | 1 sap-cistern, 500 sap-molten-metal |  |
| `sap-empty-sap-oxygen-cistern` | 1 | 1 sap-sap-oxygen-cistern | 1 sap-cistern, 500 sap-oxygen |  |
| `sap-empty-sap-volcanic-gas-cistern` | 1 | 1 sap-sap-volcanic-gas-cistern | 1 sap-cistern, 500 sap-volcanic-gas |  |
| `sap-empty-sulfuric-acid-cistern` | 1 | 1 sap-sulfuric-acid-cistern | 1 sap-cistern, 500 sulfuric-acid |  |
| `sap-empty-water-cistern` | 1 | 1 sap-water-cistern | 1 sap-cistern, 500 water |  |
| Огнеупорная стена (`sap-fireproof-wall`) | 1 | 1 sap-thermite-mk2, 1 stone-wall | 1 sap-fireproof-wall |  |
| `sap-fluoroketone-cold-cistern` | 1 | 1 sap-cistern, 500 fluoroketone-cold | 1 sap-fluoroketone-cold-cistern |  |
| `sap-fluoroketone-hot-cistern` | 1 | 1 sap-cistern, 500 fluoroketone-hot | 1 sap-fluoroketone-hot-cistern |  |
| Силовой барьер (`sap-force-barrier`) | 10 | 5 sap-mechanite-core, 10 supercapacitor, 2 accumulator | 1 sap-force-barrier |  |
| Силовой барьер Mk2 (`sap-force-barrier-mk2`) | 10 | 10 sap-nivalite, 10 sap-mechanite-core, 1 sap-force-barrier | 1 sap-force-barrier-mk2 |  |
| Зелёные водоросли (`sap-green-algae`) | 8 | 200 water | 4 sap-green-algae | pressure 1800-1800 |
| Термотрубка Mk2 (`sap-heat-pipe-mk2`) | 10 | 2 sap-heat-resistant-alloy, 1 heat-pipe | 1 sap-heat-pipe-mk2 |  |
| Жаропрочный сплав (`sap-heat-resistant-alloy`) | 8 | 2 sap-heat-resistant-crystal, 40 sap-molten-metal | 2 sap-heat-resistant-alloy |  |
| Жаропрочная броня (`sap-heat-resistant-armor`) | 10 | 20 sap-heat-scales, 10 sap-heat-resistant-alloy, 1 heavy-armor | 1 sap-heat-resistant-armor |  |
| Жаропрочный конвейер (`sap-heat-resistant-belt`) | 1 | 1 sap-heat-resistant-alloy, 1 turbo-transport-belt | 1 sap-heat-resistant-belt |  |
| Сверхпрочный насос (`sap-heavy-duty-pump`) | 10 | 5 electric-engine-unit, 10 tungsten-plate, 2 offshore-pump | 1 sap-heavy-duty-pump |  |
| `sap-heavy-oil-cistern` | 1 | 1 sap-cistern, 500 heavy-oil | 1 sap-heavy-oil-cistern |  |
| Труба сверхвысоких температур (`sap-high-temperature-pipe`) | 1 | 1 tungsten-plate, 1 pipe | 1 sap-high-temperature-pipe |  |
| Подземная труба сверхвысоких температур (`sap-high-temperature-pipe-to-ground`) | 2 | 4 tungsten-plate, 2 pipe-to-ground | 2 sap-high-temperature-pipe-to-ground |  |
| Гидробиологическая колба (`sap-hydro-science-pack`) | 10 | 1 bioflux, 3 sap-green-algae, 1 sap-sea-salt | 2 sap-hydro-science-pack | pressure 1800-1800 |
| Термоизоляционная стена (`sap-insulated-wall`) | 1 | 2 sap-dark-ice, 1 stone-wall | 1 sap-insulated-wall |  |
| Изолирующий фундамент (`sap-insulating-foundation`) | 2 | 2 sap-cryolite, 10 refined-concrete | 10 sap-insulating-foundation |  |
| Ионная колба (`sap-ionic-science-pack`) | 10 | 1 battery, 1 holmium-plate, 1 superconductor | 2 sap-ionic-science-pack | pressure 800-800 |
| `sap-light-oil-cistern` | 1 | 1 sap-cistern, 500 light-oil | 1 sap-light-oil-cistern |  |
| Логический лабораторный комплекс (ЛЛК) (`sap-logic-lab`) | 5 | 10 iron-gear-wheel, 10 copper-cable, 10 electronic-circuit | 1 sap-logic-lab |  |
| Логистический маяк Mk2 (`sap-logistic-beacon-mk2`) | 10 | 3 sap-mechanite-core, 10 processing-unit, 1 roboport | 1 sap-logistic-beacon-mk2 |  |
| Логистический дрон Mk2 (`sap-logistic-robot-mk2`) | 10 | 2 sap-nivalite, 1 sap-mechanite-core, 1 logistic-robot | 1 sap-logistic-robot-mk2 |  |
| `sap-lubricant-cistern` | 1 | 1 sap-cistern, 500 lubricant | 1 sap-lubricant-cistern |  |
| Плавка магматической руды (`sap-magmatic-ore-melting`) | 16 | 20 sap-magmatic-ore, 200 lava | 300 molten-iron, 150 molten-copper |  |
| Мега-турбина (`sap-mega-turbine`) | 15 | 20 tungsten-plate, 30 sap-heat-resistant-alloy, 3 steam-turbine | 1 sap-mega-turbine |  |
| Модульный реактор (`sap-modular-reactor`) | 10 | 20 sap-nivalite, 100 steel-plate, 10 sap-mechanite-core, 20 processing-unit | 1 sap-modular-reactor |  |
| Расплавленный металл (`sap-molten-metal`) | 8 | 10 sap-magmatic-ore, 50 sap-volcanic-gas | 200 sap-molten-metal |  |
| `sap-molten-metal-barrel` | 0.2 | 1 barrel, 50 sap-molten-metal | 1 sap-molten-metal-barrel |  |
| Нивалитовый провод (`sap-nivalite-wire`) | 1 | 1 sap-nivalite, 2 copper-cable | 2 sap-nivalite-wire |  |
| `sap-nivar-caves-food` | 4 | 1 sap-cryolite, 2 sap-dark-ice, 1 bioflux | 2 sap-nivar-caves-food |  |
| Лифт между слоями (`sap-nivar-elevator`) | 20 | 50 steel-plate, 20 electric-engine-unit, 20 lithium-plate | 1 sap-nivar-elevator |  |
| `sap-nivar-food` | 4 | 2 iron-ore, 1 sap-cryolite, 1 bioflux | 2 sap-nivar-food |  |
| `sap-oxygen-barrel` | 0.2 | 1 barrel, 50 sap-oxygen | 1 sap-oxygen-barrel |  |
| Сбор воздуха (Aquara) (`sap-oxygen-collection-aquara`) | 5 | 1 sap-dehumidifier | 200 sap-oxygen | pressure 1800-1800 |
| Сбор воздуха (Аквило) (`sap-oxygen-collection-aquilo`) | 5 | 1 sap-air-concentrator | 200 sap-oxygen | pressure 300-300 |
| Сбор воздуха (Echaris) (`sap-oxygen-collection-echaris`) | 5 | 1 sap-emp-filter | 200 sap-oxygen | pressure 600-600 |
| Сбор воздуха (Фульгора) (`sap-oxygen-collection-fulgora`) | 5 | 1 sap-air-filter | 200 sap-oxygen | pressure 800-800 |
| Сбор воздуха (Глеба) (`sap-oxygen-collection-gleba`) | 5 | 1 sap-biofilter | 200 sap-oxygen | pressure 2000-2000 |
| Сбор воздуха (Nivar) (`sap-oxygen-collection-nivar`) | 5 | 1 sap-cryo-concentrator | 200 sap-oxygen | pressure 250-250 |
| Распределитель кислорода (`sap-oxygen-distributor`) | 5 | 5 steel-plate, 5 electronic-circuit, 5 pipe | 1 sap-oxygen-distributor |  |
| Кислород из воды (`sap-oxygen-electrolysis`) | 2 | 100 water | 50 sap-oxygen |  |
| Кислород из кальцита (`sap-oxygen-from-calcite`) | 2 | 1 calcite | 50 sap-oxygen |  |
| Генератор кислорода (`sap-oxygen-generator`) | 5 | 10 steel-plate, 5 advanced-circuit, 10 pipe | 1 sap-oxygen-generator |  |
| Кислородный баллон (`sap-oxygen-tank-equipment`) | 5 | 10 steel-plate, 2 advanced-circuit, 5 pipe | 1 sap-oxygen-tank-equipment |  |
| `sap-petroleum-gas-cistern` | 1 | 1 sap-cistern, 500 petroleum-gas | 1 sap-petroleum-gas-cistern |  |
| Колба первопроходца (`sap-pioneer-science-pack`) | 10 | 1 raw-fish, 2 steel-plate, 2 advanced-circuit | 2 sap-pioneer-science-pack | pressure 1000-1000 |
| Плазменный карабин (`sap-plasma-carbine`) | 10 | 1 sap-mechanite-core, 5 supercapacitor, 1 submachine-gun | 1 sap-plasma-carbine |  |
| Башня-ретранслятор энергии (`sap-power-relay-tower`) | 10 | 4 sap-nivalite, 5 sap-mechanite-scrap, 2 big-electric-pole | 1 sap-power-relay-tower |  |
| Помпа Mk2 (`sap-pump-mk2`) | 10 | 2 electric-engine-unit, 5 tungsten-plate, 1 pump | 1 sap-pump-mk2 |  |
| Нефтекачалка Mk2 (`sap-pumpjack-mk2`) | 10 | 5 electric-engine-unit, 10 tungsten-carbide, 1 pumpjack | 1 sap-pumpjack-mk2 |  |
| Радар Mk2 (`sap-radar-mk2`) | 10 | 1 sap-mechanite-core, 1 radar | 1 sap-radar-mk2 |  |
| Радиатор охлаждения (`sap-radiator`) | 4 | 2 sap-heat-resistant-alloy, 2 heat-pipe | 1 sap-radiator |  |
| Радиатор Mk2 (`sap-radiator-mk2`) | 10 | 4 sap-heat-resistant-crystal, 2 sap-radiator | 1 sap-radiator-mk2 |  |
| Захватчик луча (`sap-ray-catcher`) | 10 | 10 sap-heat-resistant-crystal, 20 sap-heat-resistant-alloy, 1 lightning-collector | 1 sap-ray-catcher |  |
| Роботодок Mk2 (`sap-roboport-mk2`) | 10 | 5 sap-nivalite, 2 sap-mechanite-core, 1 roboport | 1 sap-roboport-mk2 |  |
| Солёные водоросли (`sap-salted-algae`) | 2 | 4 sap-green-algae, 1 sap-sea-salt | 4 sap-salted-algae |  |
| Питательные вещества из солёных водорослей (`sap-salted-algae-nutrients`) | 2 | 2 sap-salted-algae | 3 nutrients |  |
| `sap-sap-molten-metal-cistern` | 1 | 1 sap-cistern, 500 sap-molten-metal | 1 sap-sap-molten-metal-cistern |  |
| `sap-sap-oxygen-cistern` | 1 | 1 sap-cistern, 500 sap-oxygen | 1 sap-sap-oxygen-cistern |  |
| `sap-sap-volcanic-gas-cistern` | 1 | 1 sap-cistern, 500 sap-volcanic-gas | 1 sap-sap-volcanic-gas-cistern |  |
| Спутник 1 поколения (`sap-satellite-mk1`) | 10 | 10 processing-unit, 20 low-density-structure, 10 solar-panel, 2 radar | 1 sap-satellite-mk1 |  |
| Спутник 2 поколения (`sap-satellite-mk2`) | 30 | 50 processing-unit, 50 low-density-structure, 30 solar-panel, 20 accumulator, 5 radar | 1 sap-satellite-mk2 |  |
| Морская соль (`sap-sea-salt`) | 4 | 500 water | 2 sap-sea-salt | pressure 1800-1800 |
| Солнечная панель Mk2 (`sap-solar-panel-mk2`) | 10 | 5 sap-mechanite-scrap, 2 sap-heat-resistant-crystal, 1 solar-panel | 1 sap-solar-panel-mk2 |  |
| `sap-solaris-food` | 4 | 2 sap-magmatic-ore, 1 sap-thermite, 1 bioflux | 2 sap-solaris-food |  |
| Костюм стелса (`sap-stealth-suit`) | 10 | 5 sap-mechanite-core, 10 supercapacitor, 1 modular-armor | 1 sap-stealth-suit |  |
| Паровая турбина Mk2 (`sap-steam-turbine-mk2`) | 10 | 5 processing-unit, 5 low-density-structure, 1 steam-turbine | 1 sap-steam-turbine-mk2 |  |
| Хранилище жидкости Mk2 (`sap-storage-tank-mk2`) | 10 | 5 sap-mechanite-scrap, 1 storage-tank | 1 sap-storage-tank-mk2 |  |
| Штормовой якорь (`sap-storm-anchor`) | 10 | 10 electric-engine-unit, 10 carbon-fiber, 5 accumulator | 1 sap-storm-anchor |  |
| Штормовой якорь Mk2 (`sap-storm-anchor-mk2`) | 10 | 1 sap-abyss-core, 2 sap-storm-anchor | 1 sap-storm-anchor-mk2 |  |
| Штормовой щит (`sap-storm-shield`) | 10 | 20 steel-plate, 10 processing-unit, 20 carbon-fiber | 1 sap-storm-shield |  |
| Стабилизатор бури (`sap-storm-stabilizer`) | 10 | 10 steel-plate, 5 processing-unit, 5 superconductor, 5 supercapacitor | 1 sap-storm-stabilizer |  |
| `sap-sulfuric-acid-cistern` | 1 | 1 sap-cistern, 500 sulfuric-acid | 1 sap-sulfuric-acid-cistern |  |
| Сверхбойлер (`sap-super-boiler`) | 10 | 20 sap-heat-resistant-alloy, 2 heat-exchanger | 1 sap-super-boiler |  |
| Сверхбойлер Mk2 (`sap-super-boiler-mk2`) | 15 | 1 sap-molten-core, 20 tungsten-carbide, 1 sap-super-boiler | 1 sap-super-boiler-mk2 |  |
| Турель-подавитель (`sap-suppressor-turret`) | 10 | 10 sap-mechanite-scrap, 10 supercapacitor, 1 tesla-turret | 1 sap-suppressor-turret |  |
| Симбиотическая колба (`sap-symbiotic-science-pack`) | 10 | 1 bioflux, 2 jelly, 1 pentapod-egg | 2 sap-symbiotic-science-pack | pressure 2000-2000 |
| Тектоническая колба (`sap-tectonic-science-pack`) | 10 | 2 calcite, 2 tungsten-carbide, 100 lava | 2 sap-tectonic-science-pack | pressure 4000-4000 |
| Телескоп (`sap-telescope`) | 10 | 20 steel-plate, 10 iron-gear-wheel, 20 electronic-circuit | 1 sap-telescope |  |
| Термическая колба (`sap-thermal-science-pack`) | 10 | 2 sap-heat-resistant-alloy, 1 sap-thermite, 50 sap-molten-metal | 2 sap-thermal-science-pack | pressure 50-50 |
| Термит (`sap-thermite`) | 4 | 2 iron-plate, 1 sap-heat-resistant-crystal, 30 sap-volcanic-gas | 2 sap-thermite |  |
| Термит Mk2 (`sap-thermite-mk2`) | 6 | 1 sap-lava-clot, 2 sap-thermite, 20 sulfuric-acid | 2 sap-thermite-mk2 |  |
| Термоэлектрический генератор (`sap-thermoelectric-generator`) | 10 | 10 copper-cable, 5 sap-heat-resistant-crystal, 1 solar-panel | 1 sap-thermoelectric-generator |  |
| Подводный бур (`sap-underwater-drill`) | 10 | 10 carbon-fiber, 10 pipe, 2 electric-mining-drill | 1 sap-underwater-drill |  |
| Глубоководная руда (`sap-underwater-ore`) | 6 | 100 water | 3 iron-ore, 2 copper-ore, 1 stone | pressure 1800-1800 |
| Кислота из ядовитых желёз (`sap-venom-acid`) | 3 | 2 sap-venom-gland, 50 water | 60 sulfuric-acid |  |
| Ядовитая капсула из желёз (`sap-venom-poison-capsule`) | 8 | 2 steel-plate, 3 sap-venom-gland | 1 poison-capsule |  |
| `sap-volcanic-gas-barrel` | 0.2 | 1 barrel, 50 sap-volcanic-gas | 1 sap-volcanic-gas-barrel |  |
| Разделение вулканического газа (`sap-volcanic-gas-separation`) | 2 | 50 sap-volcanic-gas, 20 water | 1 sulfur, 40 sulfuric-acid |  |
| `sap-water-cistern` | 1 | 1 sap-cistern, 500 water | 1 sap-water-cistern |  |
| Водная башня (`sap-water-tower`) | 10 | 10 steel-plate, 5 bioflux, 10 carbon-fiber, 10 pipe | 1 sap-water-tower |  |
| Водная башня Mk2 (`sap-water-tower-mk2`) | 10 | 5 sap-carapace, 10 carbon-fiber, 1 sap-water-tower | 1 sap-water-tower-mk2 |  |

## Существа

| Существо | Здоровье | Скорость | Дальность | Перезарядка, тиков | Урон за удар |
|---|---|---|---|---|---|
| Хранитель (`sap-ancient-keeper`) | 2500 | 0.23 | 1.5 | 35 | 30 |
| Смотритель (`sap-ancient-warden`) | 15000 | 0.3 | 1.5 | 50 | 90 |
| Annihilator (`sap-annihilator`) | 1500 | 0.138 | 1.5 | 35 | 30 |
| Вьюга (`sap-blizzard`) | 300 | 0.24 | 1 | 35 | 15 |
| Бездонный (`sap-bottomless`) | 6000 | 0.15 | 16 | 100 | 0 |
| Disruptor (`sap-disruptor`) | 220 | 0.165 | 14 | 100 | 0 |
| Иней (`sap-frost`) | 80 | 0.2 | 0.5 | 35 | 7 |
| Ледяной страж (`sap-ice-guardian`) | 5000 | 0.3 | 1.5 | 50 | 90 |
| Магмар (`sap-magmar`) | 160 | 0.165 | 14 | 100 | 0 |
| Молтен (`sap-molten`) | 4000 | 0.3 | 1.5 | 50 | 90 |
| Overseer (`sap-overseer`) | 800 | 0.15 | 15 | 100 | 0 |
| Скорч (`sap-scorch`) | 60 | 0.26 | 0.5 | 35 | 7 |
| Sentinel-09 (`sap-sentinel`) | 180 | 0.24 | 1 | 35 | 15 |
| Сталагмит (`sap-stalagmite`) | 250 | 0.165 | 14 | 100 | 0 |
| Stormbringer (`sap-stormbringer`) | 90 | 0.28 | 0.5 | 35 | 7 |

## Гнёзда и турели

| Объект | Тип | Здоровье |
|---|---|---|
| Древний страж (`sap-alien-guardian`) | turret | 1000 |
| Гнездо пентаподов (`sap-aquara-nest`) | unit-spawner | 600 |
| Гнездо Вьюги (`sap-blizzard-nest`) | unit-spawner | 600 |
| Пещерное гнездо (`sap-cave-nest`) | unit-spawner | 600 |
| Сервер контроля (`sap-control-server`) | unit-spawner | 600 |
| Тяжёлый сервер контроля (`sap-control-server-heavy`) | unit-spawner | 1500 |
| Гнездо Магмаров (`sap-magmar-nest`) | unit-spawner | 500 |
| Гнездо Скорчей (`sap-scorch-nest`) | unit-spawner | 400 |

## Постройки

| Постройка | Тип | Здоровье | Потребление, кВт | Скорость |
|---|---|---|---|---|
| Бездна (`sap-abyss`) | spider-unit | 5000 |  |  |
| Аккумулятор Mk2 (`sap-accumulator-mk2`) | accumulator | 150 | 900 |  |
| Хранилище древней расы (`sap-alien-vault`) | container | 600 |  |  |
| Древний тайник (`sap-ancient-cache`) | container | 350 |  |  |
| Древняя дверь (`sap-ancient-door`) | simple-entity-with-owner | 50 |  |  |
| Ключевой замок (`sap-ancient-key-lock`) | container | 350 |  |  |
| Древний узел (`sap-ancient-nexus`) | container | 600 |  |  |
| Древний пьедестал (`sap-ancient-pedestal`) | container | 350 |  |  |
| Энергетический замок (`sap-ancient-power-lock`) | assembling-machine | 300 | 1000 | 1 |
| Древняя ловушка (`sap-ancient-trap`) | simple-entity-with-owner | 100 |  |  |
| Сборочный автомат Mk2+ (`sap-assembling-machine-mk2plus`) | assembling-machine | 400 | 375 | 2.5 |
| Атмосферный коллектор (`sap-atmospheric-collector`) | assembling-machine | 300 | 210 | 1 |
| Биокамера Mk2 (`sap-biochamber-mk2`) | assembling-machine | 300 | 500 | 3 |
| `sap-captive-sap-aquara-nest` | assembling-machine | 350 | 100 | 1 |
| `sap-captive-sap-blizzard-nest` | assembling-machine | 350 | 100 | 1 |
| `sap-captive-sap-cave-nest` | assembling-machine | 350 | 100 | 1 |
| `sap-captive-sap-magmar-nest` | assembling-machine | 350 | 100 | 1 |
| `sap-captive-sap-scorch-nest` | assembling-machine | 350 | 100 | 1 |
| Пещерный конвейер (`sap-cave-belt`) | transport-belt | 170 |  |  |
| Центр механической сборки (`sap-center-assembly`) | container | 150 |  |  |
| Центр данных (`sap-center-data`) | container | 150 |  |  |
| Энергетический комплекс (`sap-center-energy`) | container | 150 |  |  |
| Центр подавления сигналов (`sap-center-suppression`) | container | 150 |  |  |
| Центрифуга Mk2 (`sap-centrifuge-mk2`) | assembling-machine | 350 | 350 | 2 |
| Строительный дрон Mk2 (`sap-construction-robot-mk2`) | construction-robot | 200 | 30 |  |
| Зонтик защиты (`sap-coronal-umbrella`) | lightning-attractor | 100 |  |  |
| Зонтик Mk2 (`sap-coronal-umbrella-mk2`) | lightning-attractor | 100 |  |  |
| Криозащитный купол (`sap-cryo-dome`) | radar | 250 | 2000 |  |
| Криообогреватель (`sap-cryo-heater`) | lamp | 100 | 100 |  |
| Криообогреватель Mk2 (`sap-cryo-heater-mk2`) | lamp | 100 | 70 |  |
| Криолампа (`sap-cryo-lamp`) | lamp | 100 | 5 |  |
| Криопроводящая труба (`sap-cryo-pipe`) | pipe | 100 |  |  |
| Криопроводящая подземная труба (`sap-cryo-pipe-to-ground`) | pipe-to-ground | 150 |  |  |
| Обломок корабля (`sap-data-wreck`) | container | 100 |  |  |
| Дешифратор (`sap-decipherer`) | container | 350 |  |  |
| Глубинный бур (`sap-deep-drill`) | assembling-machine | 350 | 500 | 0.75 |
| Глубинный бур Mk2 (`sap-deep-drill-mk2`) | assembling-machine | 350 | 500 | 1.5 |
| Вход в подземелье древних (`sap-dungeon-entrance`) | container | 100 |  |  |
| Выход на поверхность (`sap-dungeon-exit`) | container | 350 |  |  |
| Разрядник Echaris (`sap-echaris-discharger`) | electric-turret | 2000 | 6000 |  |
| Электропечь Mk2 (`sap-electric-furnace-mk2`) | furnace | 350 | 126 | 3 |
| Электромагнитная турель (`sap-em-turret`) | electric-turret | 1000 | 1200 |  |
| Зенитная ЭМИ-пушка (`sap-emp-flak-cannon`) | ammo-turret | 1500 |  |  |
| Упавший обломок (`sap-fallen-debris`) | simple-entity-with-owner | 50 |  |  |
| Огнеупорная стена (`sap-fireproof-wall`) | wall | 1050 |  |  |
| Силовой барьер (`sap-force-barrier`) | accumulator | 150 | 2000 |  |
| Силовой барьер Mk2 (`sap-force-barrier-mk2`) | accumulator | 150 | 5000 |  |
| Термотрубка Mk2 (`sap-heat-pipe-mk2`) | heat-pipe | 200 |  |  |
| Жаропрочный конвейер (`sap-heat-resistant-belt`) | transport-belt | 340 |  |  |
| Сверхпрочный насос (`sap-heavy-duty-pump`) | offshore-pump | 150 | 60 |  |
| Труба сверхвысоких температур (`sap-high-temperature-pipe`) | pipe | 100 |  |  |
| Подземная труба сверхвысоких температур (`sap-high-temperature-pipe-to-ground`) | pipe-to-ground | 150 |  |  |
| Термоизоляционная стена (`sap-insulated-wall`) | wall | 700 |  |  |
| Логический лабораторный комплекс (ЛЛК) (`sap-logic-lab`) | container | 350 |  |  |
| Логистический маяк Mk2 (`sap-logistic-beacon-mk2`) | roboport | 500 | 2050 |  |
| Логистический дрон Mk2 (`sap-logistic-robot-mk2`) | logistic-robot | 200 | 27 |  |
| Мега-турбина (`sap-mega-turbine`) | generator | 300 |  |  |
| Модульный реактор (`sap-modular-reactor`) | burner-generator | 400 | 30000 |  |
| Лифт между слоями (`sap-nivar-elevator`) | linked-container | 100 |  |  |
| Распределитель кислорода (`sap-oxygen-distributor`) | assembling-machine | 300 | 210 | 1 |
| Генератор кислорода (`sap-oxygen-generator`) | assembling-machine | 300 | 210 | 1 |
| Башня-ретранслятор энергии (`sap-power-relay-tower`) | electric-pole | 150 |  |  |
| Помпа Mk2 (`sap-pump-mk2`) | pump | 180 | 29 |  |
| Нефтекачалка Mk2 (`sap-pumpjack-mk2`) | mining-drill | 200 | 70 |  |
| Радар Mk2 (`sap-radar-mk2`) | radar | 250 | 300 |  |
| Радиатор охлаждения (`sap-radiator`) | lamp | 100 | 50 |  |
| Радиатор Mk2 (`sap-radiator-mk2`) | lamp | 100 | 120 |  |
| Захватчик луча (`sap-ray-catcher`) | lightning-attractor | 200 |  |  |
| Рябь (`sap-ripple`) | spider-unit | 120 |  |  |
| Роботодок Mk2 (`sap-roboport-mk2`) | roboport | 500 | 8050 |  |
| Солнечная панель Mk2 (`sap-solar-panel-mk2`) | solar-panel | 200 |  |  |
| Обломок корабля (`sap-starting-wreck`) | container | 150 |  |  |
| Паровая турбина Mk2 (`sap-steam-turbine-mk2`) | generator | 300 |  |  |
| Хранилище жидкости Mk2 (`sap-storage-tank-mk2`) | storage-tank | 500 |  |  |
| Штормовой якорь (`sap-storm-anchor`) | accumulator | 150 |  |  |
| Штормовой якорь Mk2 (`sap-storm-anchor-mk2`) | accumulator | 150 |  |  |
| Штормовой щит (`sap-storm-shield`) | radar | 250 | 1000 |  |
| Стабилизатор бури (`sap-storm-stabilizer`) | beacon | 200 | 800 |  |
| Сверхбойлер (`sap-super-boiler`) | boiler | 200 | 30000 |  |
| Сверхбойлер Mk2 (`sap-super-boiler-mk2`) | boiler | 200 | 60000 |  |
| Турель-подавитель (`sap-suppressor-turret`) | electric-turret | 2000 | 6000 |  |
| Прибой (`sap-surf`) | spider-unit | 400 |  |  |
| `sap-tech-bonus-beacon` | beacon | 200 | 0 |  |
| Телескоп (`sap-telescope`) | radar | 250 | 300 |  |
| Термоэлектрический генератор (`sap-thermoelectric-generator`) | solar-panel | 200 |  |  |
| Подводный бур (`sap-underwater-drill`) | assembling-machine | 350 | 150 | 0.75 |
| Водная башня (`sap-water-tower`) | assembling-machine | 350 | 150 | 0.75 |
| Водная башня Mk2 (`sap-water-tower-mk2`) | assembling-machine | 350 | 150 | 1.5 |

## Настройки

| Настройка | Тип | По умолчанию | Диапазон / варианты |
|---|---|---|---|
| Стражи в подземельях (`sap-dungeon-guardians`) | runtime-global | normal | few, normal, many |
| Размер подземелий (`sap-dungeon-size`) | runtime-global | normal | small, normal, large |
| Подземелья древней расы (`sap-dungeons-enabled`) | startup | True |  |
| Исследование: ванильные планеты тоже через спутники (`sap-exploration-vanilla-planets`) | startup | True |  |
| Хардкор: агрессивные мобы на Aquara (`sap-hardcore-aquara-aggressive`) | startup | False |  |
| Хардкор: постоянная буря на Aquara (`sap-hardcore-aquara-permanent-storm`) | startup | False |  |
| Хардкор: только дешифратор (`sap-hardcore-decipher-only`) | startup | False |  |
| Хардкор: без доставки с платформы на Echaris (`sap-hardcore-echaris-no-delivery`) | startup | False |  |
| Хардкор: без нейтральной зоны посадки (`sap-hardcore-echaris-no-neutral-zone`) | startup | False |  |
| Хардкор: волны Механитов по таймеру (`sap-hardcore-echaris-timed-waves`) | startup | False |  |
| Хардкор: без доставки с платформы на Nivar (`sap-hardcore-nivar-no-delivery`) | startup | False |  |
| Хардкор: спутник 1 поколения (`sap-hardcore-satellite`) | startup | False |  |
| Хардкор: агрессивные мобы на Solaris (`sap-hardcore-solaris-aggressive`) | startup | False |  |
| Хардкор: строгий кислород (`sap-hardcore-strict-oxygen`) | runtime-global | False |  |
| Технологии: шанс ЛЛК, % (`sap-llk-chance`) | runtime-global | 15 | 10 … 20 |
| Кислород: скорость смерти без воздуха (`sap-oxygen-death-speed`) | runtime-global | medium | slow, medium, fast |
| Кислород: радиус пузыря распределителя (`sap-oxygen-distributor-radius`) | startup | 16 | 8 … 64 |
| Кислород: включить систему (`sap-oxygen-enabled`) | runtime-global | True |  |
| Кислород: объём баллона (`sap-oxygen-tank-size`) | runtime-global | medium | small, medium, large |
| Набор настроек Space Age+ (`sap-preset`) | startup | standard | custom, casual, standard, hardcore |
| Solaris: лучей коронарной массы (макс.) (`sap-solaris-coronal-rays`) | startup | 3 | 1 … 5 |
| Перезарядка Древнего узла, мин (`sap-story-recharge-minutes`) | runtime-global | 30 | 0 … 240 |
| Экран победы после концовки (`sap-story-victory`) | runtime-global | True |  |
| Технологии: скрытое дерево (`sap-techtree-enabled`) | startup | True |  |

## Константы в скриптах

Значения в начале `scripts/*.lua` каждого модуля (тики: 60 = 1 секунда).


### aquara

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| creatures.lua | `NEST_CHANCE` | 0.1 |  |
| creatures.lua | `ABYSS_CHANCE` | 0.02 |  |
| creatures.lua | `SAFE_RADIUS` | 120 |  |
| creatures.lua | `ABYSS_DISTANCE` | 350 |  |
| creatures.lua | `ATTACK_GROUP` | 5 |  |
| storm.lua | `FORECAST_TICKS` | 3600 |  |
| storm.lua | `SHIELD_RADIUS` | 20 |  |
| storm.lua | `ANCHOR_PULL_RADIUS` | 48 |  |
| storm.lua | `SPAWN_EVERY` | 10 | проверок (секунд) |
| storm.lua | `SPAWN_DISTANCE` | 60 |  |
| storm.lua | `STEP` | 2 |  |
| storm.lua | `LIFETIME` | 120 | проверок |
| storm.lua | `DAMAGE_RADIUS` | 4 |  |
| storm.lua | `ANCHOR_ENERGY` | 40000000 | Дж за пойманное торнадо, умножается на силу |

### core

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| capture.lua | `SEARCH_RADIUS` | 3 |  |
| capture.lua | `CRYOSTORM_FAIL_CHANCE` | 0.05 |  |
| condensing.lua | `ENERGY_PER_STEAM` | 97000 |  |
| condensing.lua | `SEARCH_RADIUS` | 6 | от центра; турбина 3×5, поэтому с запасом |
| diary.lua | `AWAY_TICKS` | 432000 |  |
| diary.lua | `AUTONOMOUS_MACHINES` | 30 |  |
| diary.lua | `DEADLOCK_MACHINES` | 10 |  |
| diary.lua | `DEADLOCK_SHARE` | 0.8 |  |
| dungeon.lua | `TRAP_COOLDOWN` | 120 |  |
| dungeon.lua | `CORRIDOR` | 1 | полуширина коридора (ширина 3) |
| exploration.lua | `FIND_CHANCE` | 0.5 |  |
| exploration.lua | `FIND_CHANCE_HARDCORE` | 0.25 |  |
| exploration.lua | `LAUNCHES_NORMAL` | 10 |  |
| oxygen.lua | `EMERGENCY_SECONDS` | 30 | Запас экстренной системы модульной брони, секунд. |
| oxygen.lua | `STRICT_MULTIPLIER` | 3 |  |
| oxygen.lua | `REFILL_PER_SECOND` | 20 | Сколько секунд дыхания восполняется за секунду внутри пузыря. |
| oxygen.lua | `RESPAWN_GRACE_TICKS` | 3600 | Без этого на планете без воздуха возрождение заканчивалось бы новой смертью. |
| story.lua | `UNITY_AFTER` | 2 | сколько разных концовок нужно для секретной |
| story.lua | `ESCORT` | 4 | союзных стражей у узла после Пробуждения |
| story.lua | `GIFT_TICKS` | 108000 | дар древних раз в 30 минут |
| techtree.lua | `PACKS_PER_USE` | 10 |  |
| techtree.lua | `OPTIONS_DECIPHER` | 3 |  |
| techtree.lua | `OPTIONS_LLK` | 2 |  |
| techtree.lua | `REFRESH_BREAK_CHANCE` | 0.25 |  |
| techtree.lua | `WRECK_CHANCE_NAUVIS` | 0.0333333 |  |
| techtree.lua | `WRECK_CHANCE_OTHER` | 0.0166667 |  |
| techtree.lua | `VAULT_CHANCE` | 0.0125 |  |
| techtree.lua | `VAULT_DISTANCE` | 200 |  |
| techtree.lua | `GUARDIANS` | 2 |  |

### debris

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| debris.lua | `SEGMENTS` | 10 |  |
| debris.lua | `SPAWN_CHANCE` | 0.25 | шанс за проверку, что к платформе прилетит кусок |
| debris.lua | `CELL_LIMIT` | 5000 | больше мусора в одной ячейке не копится |
| debris.lua | `FREE_LAUNCHES` | 20 |  |
| debris.lua | `FALL_CHANCE_PER_DEBRIS` | 0.02 |  |
| debris.lua | `FALL_CHANCE_MAX` | 0.5 |  |
| debris.lua | `FALL_RADIUS` | 4 |  |
| debris.lua | `FALL_DAMAGE` | 150 |  |
| debris.lua | `FLAVOR_SHARE` | 0.5 |  |

### echaris

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| mechanites.lua | `CENTER_CHANCE` | 0.05 |  |
| mechanites.lua | `NEUTRAL_RADIUS` | 160 |  |
| mechanites.lua | `NEUTRAL_RADIUS_HARDCORE` | 32 |  |
| mechanites.lua | `HEAVY_DISTANCE` | 600 |  |
| mechanites.lua | `CENTER_LOCK_RADIUS` | 40 |  |
| mechanites.lua | `REINFORCEMENTS` | 3 |  |
| mechanites.lua | `ALARM_RADIUS` | 80 |  |
| mechanites.lua | `EMP_RADIUS` | 10 |  |
| mechanites.lua | `EMP_TICKS` | 300 |  |
| mechanites.lua | `WAVE_SIZE` | 10 |  |
| mechanites.lua | `PATROL_SERVERS` | 10 |  |
| mechanites.lua | `PATROL_UNITS` | 4 |  |
| mechanites.lua | `PATROL_RADIUS` | 40 |  |
| mechanites.lua | `RECLAIM_TICKS` | 54000 |  |
| mechanites.lua | `ZONE_RADIUS` | 40 |  |
| specials.lua | `STEALTH_NOTICE` | 6 |  |
| specials.lua | `STEALTH_SCAN` | 24 |  |
| specials.lua | `STEALTH_RETREAT` | 8 |  |
| specials.lua | `HACK_RADIUS` | 7 |  |
| specials.lua | `HACK_CHANCE` | 0.5 |  |
| storm.lua | `PHASES` | 4 |  |
| storm.lua | `LEVEL_MIN_TICKS` | 10800 | уровень держится 3-8 минут |
| storm.lua | `LEVEL_MAX_TICKS` | 28800 |  |
| storm.lua | `ROBOT_DAMAGE_FRACTION` | 0.04 | доля здоровья за проверку |
| storm.lua | `ROBOT_ENERGY_DRAIN` | 0.15 | доля энергии за проверку |

### nivar

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| cryostorm.lua | `PHASES` | 5 |  |
| cryostorm.lua | `MAX_COLD` | 24 |  |
| cryostorm.lua | `BROKEN_DAMAGE_FRACTION` | 0.05 |  |
| cryostorm.lua | `PACK_SIZE` | 4 |  |
| cryostorm.lua | `PACK_RADIUS` | 150 |  |
| cryostorm.lua | `PASSIVE_TTL` | 3600 | Считается дорого (пять запросов), поэтому кэшируется на минуту. |
| cryostorm.lua | `CAVE_PACK` | 3 | гнёзда, и Иней идёт к постройкам игрока в пещерах (N3). |
| cryostorm.lua | `EXTRA` | 1.5 | Расстояние считается до центра машины с запасом в полразмера машины (EXTRA). |
| cryostorm.lua | `RESCAN_CYCLES` | 10 | полный пересчёт (на случай построек от других модов без события). Всё в storage. |

### solaris

| Файл | Константа | Значение | Пояснение |
|---|---|---|---|
| creatures.lua | `NEST_CHANCE` | 0.0555556 |  |
| creatures.lua | `MOLTEN_CHANCE` | 0.0166667 |  |
| creatures.lua | `SAFE_RADIUS` | 120 |  |
| creatures.lua | `MOLTEN_DISTANCE` | 400 |  |
| creatures.lua | `ATTACK_GROUP` | 6 |  |
| overheat.lua | `PHASES` | 5 |  |
| overheat.lua | `HEAT_UP` | 1 |  |
| overheat.lua | `COOL_DOWN` | 3 |  |
| overheat.lua | `MAX_HEAT` | 24 |  |
| overheat.lua | `BROKEN_DAMAGE_FRACTION` | 0.05 |  |
| overheat.lua | `EXTRA` | 1.5 | Расстояние считается до центра машины с запасом в полразмера машины (EXTRA). |
| overheat.lua | `RESCAN_CYCLES` | 10 | другими модами без события. Всё хранится в storage (одинаково у всех игроков). |
| power.lua | `RADIUS` | 8 |  |
| power.lua | `SPECIFIC_HEAT` | 10000000 | Дж на градус (как в прототипе сверхбойлера) |
| power.lua | `MAX_TEMPERATURE` | 1000 |  |
