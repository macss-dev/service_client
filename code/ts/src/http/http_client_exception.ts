/// Excepción lanzada cuando ocurre un error HTTP del lado del cliente (4xx) o servidor (5xx).
export class HttpClientException extends Error {
  readonly statusCode: number;
  readonly response?: Record<string, unknown>;

  constructor(opts: {
    statusCode: number;
    message: string;
    response?: Record<string, unknown>;
  }) {
    super(opts.message);
    this.name = 'HttpClientException';
    this.statusCode = opts.statusCode;
    this.response = opts.response;
  }

  override toString(): string {
    return `HttpClientException: ${this.message} (statusCode: ${this.statusCode})`;
  }
}
