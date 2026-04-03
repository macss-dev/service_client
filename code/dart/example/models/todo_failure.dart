import '../../lib/service_client.dart';

/// Error de dominio para operaciones sobre ToDo.
class ToDoFailure extends ServiceFailure {
  const ToDoFailure({
    required super.statusCode,
    required super.message,
    super.responseBody,
  });

  @override
  String toString() => 'ToDoFailure: $message (statusCode: $statusCode)';
}
