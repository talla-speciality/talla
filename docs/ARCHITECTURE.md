# Talla feature architecture

The iOS and backend entry points are composition roots. They may assemble dependencies, navigation, and process lifecycle, but feature implementation belongs in a domain module.

## Feature ownership

| Domain | Apple client | Backend |
| --- | --- | --- |
| Commerce | `Talla Speciality/Modules/Commerce` | `backend/modules/commerce` |
| Brewing | `Talla Speciality/Modules/Brewing` | `backend/modules/brewing` |
| Espresso | `Talla Speciality/Modules/Espresso` | Brew and sample sync contracts in `backend/modules/brewing` |
| Loyalty | `Talla Speciality/Modules/Loyalty` | `backend/modules/loyalty` |
| Account | `Talla Speciality/Modules/Account` | `backend/modules/account` |
| Observability | `Talla Speciality/Modules/Observability` | `backend/modules/observability` |

`ContentView.swift` owns the app shell and shared navigation state. Its feature screens and services live in the directories above. `BrewingSectionView.swift` owns the brewing navigation shell; setup, recipe building, guided runs, runtime support, and espresso profiles are separate files.

`backend/server.js` owns configuration and process lifecycle. `backend/modules/application/create-server.js` owns HTTP routing and receives its dependencies explicitly. Provider adapters, normalization, synchronization, loyalty artwork, account attestation, and telemetry live in their domain modules.

## Dependency direction

- Feature views may use shared app models and services, but the root views must not absorb feature implementations.
- The HTTP application factory receives dependencies from `server.js`; it must not import mutable server state.
- Domain helpers remain independently testable and must not start listeners or processes when imported.
- Cross-platform coffee and espresso records share the brewing sync contract so iOS and Android retain the same wire format.

## Guardrails

The backend lint command enforces composition-root budgets:

- `ContentView.swift`: at most 3,500 lines.
- `BrewingSectionView.swift`: at most 750 lines.
- `backend/server.js`: at most 9,250 lines. New behavior belongs in a domain module; the entry point only wires configuration, persistence, and the HTTP application factory.

When a root reaches its budget, extract the complete declaration or route group into the owning feature module rather than increasing the limit.
