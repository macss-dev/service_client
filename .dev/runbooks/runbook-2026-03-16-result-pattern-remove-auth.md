# RUNBOOK – Implementar patrón Result y remover autenticación (v0.2.0)

## Objective

Integrar el patrón Result (sealed classes Dart 3) en `service_client` y eliminar toda la lógica de autenticación. Breaking change: el package pasa a hacer una sola cosa bien — conectar con servicios HTTP y representar resultados de forma explícita.

## Scope

**In:**
- Crear `sealed class Result<S, F>` con subtipos `Success` y `Failure` (pattern matching exhaustivo)
- Crear clase base `ServiceFailure` con `statusCode`, `message`, `responseBody`
- Eliminar toda la lógica de auth: `Token`, `TokenVault`, `AuthReLoginException`, storage adapters
- Eliminar dependencia `cryptography` (solo usada por `AesGcmEncryptor`)
- Eliminar campo `auth` de `ServiceClientConfig`
- Limpiar `HttpServiceClient` y `httpClient()` de toda referencia a auth
- Actualizar example con patrón MVC: View (`main`) → Controller (`TodoController`) → Service (`JsonPlaceholderService`) → `Result`
- Actualizar `pubspec.yaml` a v0.2.0, `README.md`, `CHANGELOG.md`

**Out:**
- No se modifica la interfaz `ServiceClient` (send sigue retornando `ServiceResponse`)
- No se modifica `ServiceRequest` ni `ServiceResponse`
- No se migra `HttpClientException` a Result (es excepción interna del package)
- No se crean tests unitarios para Result en este plan (el compilador garantiza exhaustive checking; los tests vendrán con el uso real)
- No se crean nuevos ADRs ni specs

## Context

- Module: `service_client`
- Location: `lib/src/core/` (Result, ServiceFailure), `lib/src/http/` (limpieza auth)
- Related components: `ServiceClient`, `HttpServiceClient`, `ServiceRequest`, `ServiceResponse`, `HttpClientException`
- Assumptions:
  - SDK >= 3.0.0 (sealed classes disponibles)
  - Los consumidores actuales del package actualizarán a v0.2.0 con los breaking changes documentados
  - `HttpClientException` sigue siendo válida como excepción interna para errores de infraestructura no esperados
- Methodology: **Test Driven Development (TDD)**

## Decisions Log

- 2026-03-16: Usar sealed classes de Dart 3 (no boolean `isSuccess`) para exhaustive checking en compile-time
- 2026-03-16: `F` en `Result<S, F>` no está restringido a `ServiceFailure` — el consumidor elige su tipo de error
- 2026-03-16: `ServiceFailure` es clase concreta (no abstract) — usable directamente o extensible
- 2026-03-16: `send()` NO retorna Result — es infraestructura de bajo nivel. El servicio del consumidor convierte `ServiceResponse` en `Result`
- 2026-03-16: Remoción de auth es breaking change → v0.2.0
- 2026-03-16: Mantener `httpClient()` helper tras quitar auth — sigue siendo útil para llamadas rápidas
- 2026-03-16: El example sigue patrón MVC para demostrar el uso idiomático con controllers

## Execution Plan (TDD Checklist)

Each step follows the Red-Green-Refactor cycle. **Commit after each step passes all tests.**

### Fase 1 — Result Pattern

- [x] Step 1: Crear `lib/src/core/result.dart` — sealed class `Result<S, F>`
  - [x] Write failing test: test que importa `Result`, crea `Result.success(42)` y `Result.failure('error')`, verifica pattern matching exhaustivo con `switch`
  - [x] Implement minimum code to pass: sealed class `Result<S, F>`, `final class Success<S, F>`, `final class Failure<S, F>` con factory constructors
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `2be8627`

- [x] Step 2: Crear `lib/src/core/service_failure.dart` — clase base `ServiceFailure`
  - [x] Write failing test: test que crea `ServiceFailure(statusCode: 404, message: 'Not Found')`, verifica campos y `toString()`
  - [x] Implement minimum code to pass: clase `ServiceFailure` con `statusCode`, `message`, `responseBody`, `toString()`
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `2be8627`

- [x] Step 3: Exportar `Result`, `Success`, `Failure`, `ServiceFailure` desde `lib/service_client.dart`
  - [x] Write failing test: test que importa `package:service_client/service_client.dart` y usa `Result.success`, `Result.failure`, `ServiceFailure`
  - [x] Implement minimum code to pass: agregar export statements en `lib/service_client.dart`
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `2be8627`

### Fase 2 — Remoción de Auth

- [x] Step 4: Eliminar archivos de auth y storage
  - [x] Write failing test: verificar que `dart analyze` pasa sin los archivos eliminados (este paso se valida con el análisis estático tras el paso 5-8)
  - [x] Eliminar: `lib/src/http/auth_exceptions.dart`, `token.dart`, `token_vault.dart`, `lib/src/http/storage/` (5 archivos), `test/storage/` (2 archivos)
  - [x] No refactor necesario (eliminación pura)
  - [x] NO commit aún — depende de pasos 5-8 para compilar

- [x] Step 5: Limpiar `ServiceClientConfig` — eliminar campo `auth`
  - [x] Eliminar parámetro `auth` del constructor y campo `final bool auth` en `lib/src/core/service_core.dart`
  - [x] No commit aún — depende de pasos 6-8

- [x] Step 6: Limpiar `HttpServiceClient` — eliminar toda lógica de auth
  - [x] Remover imports de `auth_exceptions.dart`, `token.dart`, `token_vault.dart`
  - [x] Remover: inyección de Authorization header, detección de login, refresh de token en 401, `throw AuthReLoginException()`, `if (e is AuthReLoginException) rethrow`
  - [x] Remover: `_inferRefreshEndpoint()`, `_kCurrentUser`, función `_tryRefresh()`
  - [x] No commit aún — depende de pasos 7-8

- [x] Step 7: Limpiar `httpClient()` helper — eliminar parámetro `auth` y catch de `AuthReLoginException`
  - [x] Remover import de `auth_exceptions.dart`
  - [x] Remover parámetro `auth` de la firma
  - [x] Remover `auth` de la creación del config
  - [x] Remover `on AuthReLoginException { rethrow; }` del catch
  - [x] No commit aún — depende de paso 8

- [x] Step 8: Limpiar exports en `lib/service_client.dart` y dependencia `cryptography`
  - [x] Eliminar 6 export statements de auth/storage en `lib/service_client.dart`
  - [x] Eliminar `cryptography: ^2.9.0` de `pubspec.yaml`
  - [x] Run `dart analyze` — 0 issues found ✓
  - [x] Run tests existentes — 8/8 passed ✓
  - [x] `git commit` (all tests green, `dart analyze` clean) — **commit agrupa pasos 4-8**

### Fase 3 — Example MVC

- [x] Step 9: Crear modelo `example/models/todo.dart`
  - [x] Write failing test: test que crea `ToDo.fromJson({'id': 1, 'title': 'Test', 'completed': false})` y verifica campos
  - [x] Implement: clase `ToDo` con `id`, `title`, `isCompleted`, factory `fromJson`
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `5a80b43`

- [x] Step 10: Crear error `example/models/todo_failure.dart`
  - [x] Write failing test: test que crea `ToDoFailure(statusCode: 404, message: 'Not found')` y verifica herencia de `ServiceFailure`
  - [x] Implement: clase `ToDoFailure extends ServiceFailure`
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `5a80b43`

- [x] Step 11: Actualizar `example/services/json_placeholder_service.dart`
  - [x] Write failing test: test que verifica que `getTodo()` retorna `Result<ToDo, ToDoFailure>` (mock del ServiceClient)
  - [x] Implement: limpiar código comentado, eliminar `auth: false`, retornar `Result.success(ToDo)` o `Result.failure(ToDoFailure)`
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `5a80b43`

- [x] Step 12: Crear `example/controllers/todo_controller.dart`
  - [x] Write failing test: test que verifica que `TodoController.fetchTodo()` llama al service y maneja `Success`/`Failure`
  - [x] Implement: clase `TodoController` con método `fetchTodo(int id)` que retorna `Result` directamente al caller
  - [x] Refactor if needed
  - [x] `git commit` (all tests green) — `5a80b43`

- [x] Step 13: Actualizar `example/example.dart` — View
  - [x] Implement: `main()` instancia `TodoController`, llama `fetchTodo(1)`, usa pattern matching para mostrar resultado
  - [x] Run `dart run example/example.dart` — flujo MVC completo funciona ✓
  - [x] `git commit` (all tests green, example runs) — `5a80b43`

### Fase 4 — Metadata y Docs

- [ ] Step 14: Actualizar `pubspec.yaml` — versión `0.2.0`
  - [ ] Cambiar `version: 0.1.2` → `version: 0.2.0`
  - [ ] Verificar que `cryptography` ya fue eliminada en paso 8
  - [ ] `git commit`

- [ ] Step 15: Actualizar `README.md`
  - [ ] Nuevo example con Result pattern y MVC (View → Controller → Service → Result)
  - [ ] Eliminar referencias a auth, Token, TokenVault, storage adapters
  - [ ] `git commit`

- [ ] Step 16: Actualizar `CHANGELOG.md`
  - [ ] Documentar breaking changes de v0.2.0:
    - Added: `Result<S, F>` sealed class, `Success`, `Failure`, `ServiceFailure`
    - Removed: `Token`, `TokenVault`, `AuthReLoginException`, `TokenStorageAdapter`, `MemoryStorageAdapter`, `FileStorageAdapter`, `AesGcmEncryptor`, `TokenEncryptor`, `PassphraseProvider`
    - Removed: `auth` parameter from `ServiceClientConfig` and `httpClient()`
    - Removed: `cryptography` dependency
  - [ ] `git commit`

### Validación Final

- [ ] Step 17: Validación completa
  - [ ] `dart analyze` — cero errores, cero warnings
  - [ ] `dart test` — todos los tests pasan
  - [ ] `dart run example/example.dart` — flujo MVC completo funciona
  - [ ] Grep: cero referencias a `Token`, `TokenVault`, `AuthReLoginException` en lib/ y example/
  - [ ] Verificar que sealed class fuerza exhaustive check (omitir un case en switch debe generar error de compilación)

## Constraints

- v0.2.0 — breaking change respecto a v0.1.x
- No modificar la interfaz `ServiceClient` (`send` retorna `ServiceResponse`, no `Result`)
- No modificar `ServiceRequest` ni `ServiceResponse`
- `HttpClientException` se mantiene como excepción interna del package
- SDK mínimo >= 3.0.0 (sealed classes requieren Dart 3)
- Cada paso TDD debe pasar `dart analyze` antes del commit

## Validation

- `dart analyze` — cero errores y cero warnings en todo el proyecto
- `dart test` — todos los tests pasan (los de storage se eliminaron con los archivos)
- `dart run example/example.dart` — ejecuta el flujo completo: main(View) → TodoController → JsonPlaceholderService → Result → TodoController → main(View)
- Grep workspace: cero referencias a `Token`, `TokenVault`, `AuthReLoginException`, `TokenStorageAdapter`, `FileStorageAdapter`
- `Result` fuerza exhaustive check: omitir `Success` o `Failure` en un `switch` genera error de compilación

## Rollback / Safety

- Auth se elimina completamente — los consumidores que dependen de `Token`, `TokenVault`, o storage adapters deben mantener v0.1.x hasta migrar
- El código de auth puede recuperarse del historial de git (branch `main` en el commit previo a este feature branch)
- Si la migración se aborta, basta con no mergear el feature branch

## Blockers / Open Questions

- Ningún blocker identificado
- Open: ¿Crear un package separado `service_auth` para la lógica de autenticación removida? (decisión futura, fuera del scope de este runbook)
- Open: ¿Agregar métodos de conveniencia a Result (`map`, `flatMap`, `fold`)? (decisión futura — R-TEC-03: abstracciones se ganan, no se anticipan)
