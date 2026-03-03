# C++ Gas Reactions (atmos_reactions)

Полная реализация **всех** газовых реакций атмосферы на C++. Соответствует `code/modules/atmospherics/gasmixtures/reactions.dm` и константам из `code/__DEFINES/reactions.dm` / `atmospherics.dm`.

## Назначение

- **Эталонная реализация** — те же формулы и константы, что в DM, для тестов и сверки с auxmos.
- **Интеграция** — можно собрать как библиотеку и вызывать из BYOND-расширения (например, заменить или дополнить auxmos).
- **Реакции с побочными эффектами** (радиация, исследование, спавн hot_ice, огонь по тайлу) идут через `ReactionCallbacks`; вызывающая сторона (DM или мост к auxmos) выполняет их после вызова реакций.

## Структура

| Файл | Описание |
|------|----------|
| `reaction_constants.hpp` | Константы (температуры, энергии, пороги) — аналог `__DEFINES/reactions.dm` и части `atmospherics.dm`. |
| `gas_ids.hpp` | Строковые ID газов (`"o2"`, `"n2"`, …). |
| `gas_mixture.hpp` | `GasMixtureView` — вид на смесь (моли, температура, объём, теплоёмкость, `reaction_results`, `analyzer_results`). |
| `reactions.hpp` | Объявления всех реакций и `ReactionCallbacks`. |
| `reactions.cpp` | Реализация всех реакций. |

## Реакции

Реализованы все реакции из DM:

- **nobliumsupression** — остановка реакций (hypernob).
- **water_vapor** — только изменение газа; вызовы тайла (`freon_gas_act`, `water_vapor_gas_act`) остаются в DM.
- **tritfire**, **plasmafire**, **genericfire** — горение; `fire_expose` и `radiation_pulse` через callbacks.
- **fusion** — плазменная fusion; радиация и частицы через callbacks.
- **nitrylformation**, **bzformation**, **stimformation**, **nobliumformation** — синтез; очки исследований через `add_research`.
- **miaster** — стерилизация миазмы; исследования через callback.
- **nitric_oxide** — разложение NO; при необходимости передаётся таблица энтальпий.
- **hagedorn**, **dehagedorn** — QCD; исследования и список газов для dehagedorn через параметры.
- **freonfire**, **freonformation**, **halon_o2removal**, **healium_formation**, **zauker_formation**, **zauker_decomp**, **nitrium_formation**, **nitrium_decomposition**, **pluox_formation**, **proto_nitrate_***, **antinoblium_replication** — все экзотические реакции.

Реакции **condensation** (конденсация реагентов) и динамические реакции по реагентам остаются в DM: они зависят от `datum/reagent` и `reagents_holder.reaction()`.

## Сборка

Заголовки и один .cpp можно подключать в любой C++17-проект. Для сборки как библиотеки добавьте в свой CMake/Makefile:

```cmake
add_library(atmos_reactions STATIC
  code/native/atmos_reactions/reactions.cpp
)
target_include_directories(atmos_reactions PUBLIC code/native/atmos_reactions)
```

## Подключение к игре (atmos_cpp.dll)

Модуль **подключён** к BlueMoon-Station:

1. **atmos_cpp.dll** — BYOND-расширение (собирается вместе с библиотекой: `.\build.ps1`). Копируется в `code/native/atmos_reactions/out/` и в корень проекта.
2. **react_cpp_bridge.dm** — при наличии `atmos_cpp` в окружении BYOND процедура `react(holder)` сериализует смесь, вызывает `call_ext("atmos_cpp", "run_reactions")(строка)`, применяет результат к смеси через auxmos (set_moles, set_temperature).
3. Данные смеси по-прежнему хранятся в **auxmos**; C++ считает только реакции и возвращает новое состояние.

**Как включить C++ реакции:** положите `atmos_cpp.dll` в каталог с `DreamDaemon.exe` (или в корень проекта, откуда запускается сервер). При старте мир один раз вызывает `call_ext("atmos_cpp", "version")()`; если вызов успешен, все последующие `air.react(holder)` идут через C++. Если DLL нет — используется auxmos (Rust), как раньше.

**Побочные эффекты** (радиация, очки исследований, спавн hot_ice, огонь по тайлу) в DLL не вызываются (callbacks = null). Результаты FIRE и FUSION возвращаются в строке и записываются в `reaction_results` / `analyzer_results` на стороне DM.
