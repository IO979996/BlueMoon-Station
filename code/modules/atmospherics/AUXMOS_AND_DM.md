# Граница между auxmos и DM в атмосфере

BlueMoon-Station использует **форк auxmos** с реакциями в Rust: [IO979996/auxmos-bluemoon](https://github.com/IO979996/auxmos-bluemoon). Репозиторий и ветка задаются в корне проекта в `dependencies.sh` (`AUXMOS_REPO`, `AUXMOS_VERSION`). Сборка идёт с фичей `bluemoon_reactions`.

Кратко: где выполняется логика в Rust (auxmos), а где в DM.

## Auxmos (Rust)

Вызывается через FFI из `code/__DEFINES/bindings.dm`. Все процедуры `datum/gas_mixture` (get_moles, set_temperature, merge, remove, thermal_energy и т.д.) и часть подсистемы воздуха это обёртки над auxmos.

- **Газовая смесь:** хранение молей, температуры, объёма, теплоёмкость, transfer_to, merge, remove, remove_ratio, temperature_share, equalize_with, copy_from, clear. Чтение/запись идут в Rust.
- **Реакции:** вызов `air.react(holder)` уходит в `byond:react_hook_ffi`. В auxmos выполняется цикл по реакциям, проверка min_requirements (TEMP, ENER, газы) и вызов логики каждой реакции. Список реакций синхронизируется из DM через `auxtools_update_reactions()` (данные из `SSair.gas_reactions` и их min_requirements).
- **Тайлы:** регистрация тайла в атмосфере (`turf.update_air_ref()` -> `hook_register_turf_ffi`). Обработка тайлов за тик: `process_turf_hook_ffi` (шаринг с соседями), `equalize_hook_ffi` (уравнивание), `groups_hook_ffi` (excited groups), `finish_process_turfs_ffi` (финализация). То есть расчёт переноса газа между тайлами и равновесие делаются в Rust.
- **Инициализация:** `auxtools_atmos_init(gas_data)`, `_auxtools_register_gas(gas)` при создании газа. Реакции подтягиваются из DM при старте и при добавлении новой реакции (`add_reaction` -> `auxtools_update_reactions`).

## DM

- **Подсистема SSair:** порядок фаз (rebuild pipenets, pipenets, atmos machinery, active turfs, equalize, excited groups, finish turfs, high pressure, hotspots, heat). Все фазы тайлов делегируют в auxmos через `process_turfs_auxtools`, `process_turf_equalize_auxtools`, `process_excited_groups_auxtools`, `finish_turf_processing_auxtools`. В DM только вызов этих процедур и пауза по TICK_REMAINING_MS.
- **Пайпы:** `datum/pipeline.process()` в DM: reconcile_air(), затем `air?.react(src)`. То есть мерж воздуха сети и вызов реакций; сам react выполняется в auxmos. Цикл по сетям и вызов process() для каждой сети в DM.
- **Атмос-машины:** цикл по `atmos_machinery`, вызов `process_atmos()` у каждой машины в DM. Внутри машин может быть вызов `airs[i].react(...)` или работа с газом через процедуры gas_mixture (реализация в auxmos).
- **Очаги огня (hotspots):** в DM: цикл по `SSair.hotspots`, логика hotspot (perform_exposure). Там вызывается `affected.react(src)` для снятой с тайла порции газа; реакция считается в auxmos.
- **Высокое давление, тепло тайлов:** списки и циклы в DM, воздействие на газ через gas_mixture (auxmos).
- **Реакции (описание):** типы реакций и min_requirements заданы в DM (`code/modules/atmospherics/gasmixtures/reactions.dm`). Они используются для тестов и для синхронизации в auxmos через `update_reactions_ffi`. Сами расчёты реакций в auxmos.
- **Ранний выход в react:** в `bindings.dm` перед вызовом FFI проверяется `total_moles()` (реализация в auxmos); при пустой смеси возврат NO_REACTION без вызова Rust.

## Итог

- **Auxmos:** ядро симуляции (данные смесей, перенос между тайлами, равновесие, цикл реакций по min_requirements и вызов логики реакций).
- **DM:** расписание SSair, пайпеты и машины (кто когда вызывает process), очаги огня, высокое давление, описание реакций и газов; вызовы к gas_mixture и react уходят в auxmos.
