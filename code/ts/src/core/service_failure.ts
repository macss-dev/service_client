/// Error base para fallos de servicios HTTP.
///
/// Contiene la información mínima de un error HTTP: código de estado,
/// mensaje descriptivo, y opcionalmente el cuerpo de la respuesta parseado.
///
/// Los consumidores pueden extenderla para crear errores de dominio específicos:
///
/// ```ts
/// class ToDoFailure extends ServiceFailure {
///   constructor(opts: { statusCode: number; message: string }) {
///     super(opts);
///   }
/// }
/// ```
export class ServiceFailure {
  readonly statusCode: number;
  readonly message: string;
  readonly responseBody?: Record<string, unknown>;

  constructor(opts: {
    statusCode: number;
    message: string;
    responseBody?: Record<string, unknown>;
  }) {
    this.statusCode = opts.statusCode;
    this.message = opts.message;
    this.responseBody = opts.responseBody;
  }

  toString(): string {
    return `ServiceFailure: ${this.message} (statusCode: ${this.statusCode})`;
  }
}
