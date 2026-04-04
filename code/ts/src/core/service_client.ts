/// Transport protocol used by a ServiceRequest.
///
/// Currently only 'http' is implemented. Future versions may add
/// additional protocols (gRPC, WebSocket, message queues).
export type ServiceProtocol = 'http';

export class ServiceClientConfig {
  readonly baseUrl: URL;
  readonly defaultHeaders: Record<string, string>;
  readonly timeout: number;

  constructor(opts: {
    baseUrl: URL | string;
    defaultHeaders?: Record<string, string>;
    /** Timeout in milliseconds. Default: 30000 (30s). */
    timeout?: number;
  }) {
    this.baseUrl = ServiceClientConfig._normalizeBaseUrl(
      typeof opts.baseUrl === 'string' ? new URL(opts.baseUrl) : opts.baseUrl,
    );
    this.defaultHeaders = opts.defaultHeaders ?? {};
    this.timeout = opts.timeout ?? 30_000;
  }

  /// Ensure the path ends with `/` for correct endpoint resolution.
  private static _normalizeBaseUrl(url: URL): URL {
    const path = url.pathname;
    if (path === '' || path.endsWith('/')) {
      return url;
    }
    const normalized = new URL(url.toString());
    normalized.pathname = `${path}/`;
    return normalized;
  }
}

export class ServiceRequest {
  readonly protocol: ServiceProtocol;
  readonly method: string;
  readonly endpoint: string;
  readonly headers?: Record<string, string>;
  readonly body?: unknown;
  readonly errorMessage: string;

  constructor(opts: {
    protocol: ServiceProtocol;
    method: string;
    endpoint: string;
    headers?: Record<string, string>;
    body?: unknown;
    errorMessage?: string;
  }) {
    this.protocol = opts.protocol;
    this.method = opts.method;
    this.endpoint = opts.endpoint;
    this.headers = opts.headers;
    this.body = opts.body;
    this.errorMessage = opts.errorMessage ?? 'Error in service request';
  }

  static http(opts: {
    method: string;
    endpoint: string;
    headers?: Record<string, string>;
    body?: unknown;
    errorMessage?: string;
  }): ServiceRequest {
    return new ServiceRequest({
      protocol: 'http',
      method: opts.method,
      endpoint: opts.endpoint,
      headers: opts.headers,
      body: opts.body,
      errorMessage: opts.errorMessage ?? 'Error in HTTP request',
    });
  }
}

export interface ServiceResponse {
  readonly statusCode: number;
  readonly headers: Record<string, string>;
  readonly rawBody: string;
  readonly data?: unknown;
}

export interface ServiceClient {
  send(request: ServiceRequest): Promise<ServiceResponse>;
  close(): Promise<void>;
}
