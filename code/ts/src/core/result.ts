/// Resultado exitoso que contiene el valor de tipo `S`.
export interface Success<S> {
  readonly type: 'success';
  readonly value: S;
}

/// Resultado fallido que contiene el error de tipo `F`.
export interface Failure<F> {
  readonly type: 'failure';
  readonly error: F;
}

/// Encapsula el resultado de una operación que puede ser exitosa o fallida.
///
/// Usa el campo discriminador `type` para pattern matching exhaustivo:
///
/// ```ts
/// switch (result.type) {
///   case 'success': // result.value disponible
///   case 'failure': // result.error disponible
/// }
/// ```
export type Result<S, F> = Success<S> | Failure<F>;

/// Crea un resultado exitoso con el valor proporcionado.
export function success<S, F = never>(value: S): Result<S, F> {
  return { type: 'success', value };
}

/// Crea un resultado fallido con el error proporcionado.
export function failure<S = never, F = unknown>(error: F): Result<S, F> {
  return { type: 'failure', error };
}

/// Type guard que estrecha `Result<S, F>` a `Success<S>`.
export function isSuccess<S, F>(result: Result<S, F>): result is Success<S> {
  return result.type === 'success';
}

/// Type guard que estrecha `Result<S, F>` a `Failure<F>`.
export function isFailure<S, F>(result: Result<S, F>): result is Failure<F> {
  return result.type === 'failure';
}
