/// Error base para fallos de servicios HTTP.
///
/// Contiene la información mínima de un error HTTP: código de estado,
/// mensaje descriptivo, y opcionalmente el cuerpo de la respuesta parseado.
///
/// Los consumidores pueden usar esta clase directamente o extenderla
/// para crear errores de dominio específicos:
///
/// ```dart
/// class ToDoFailure extends ServiceFailure {
///   ToDoFailure({required super.statusCode, required super.message});
/// }
/// ```
class ServiceFailure {
  const ServiceFailure({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  /// Código de estado HTTP (e.g., 404, 500).
  final int statusCode;

  /// Mensaje descriptivo del error.
  final String message;

  /// Cuerpo de la respuesta HTTP parseado como JSON, si está disponible.
  final Map<String, dynamic>? responseBody;

  @override
  String toString() =>
      'ServiceFailure: $message (statusCode: $statusCode)';
}
