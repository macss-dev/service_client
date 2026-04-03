/// Encapsula el resultado de una operación que puede ser exitosa o fallida.
///
/// Usa pattern matching (`switch`) para acceder al valor o al error.
/// El compilador fuerza el manejo exhaustivo de ambos casos:
///
/// ```dart
/// switch (result) {
///   case Success(:final value): // manejar éxito
///   case Failure(:final error): // manejar fallo
/// }
/// ```
sealed class Result<S, F> {
  const Result();

  /// Crea un resultado exitoso con el [value] proporcionado.
  const factory Result.success(S value) = Success<S, F>;

  /// Crea un resultado fallido con el [error] proporcionado.
  const factory Result.failure(F error) = Failure<S, F>;
}

/// Resultado exitoso que contiene el valor de tipo [S].
final class Success<S, F> extends Result<S, F> {
  const Success(this.value);

  /// El valor producido por la operación exitosa.
  final S value;
}

/// Resultado fallido que contiene el error de tipo [F].
final class Failure<S, F> extends Result<S, F> {
  const Failure(this.error);

  /// El error que describe la razón del fallo.
  final F error;
}
