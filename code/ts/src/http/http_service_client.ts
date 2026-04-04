import {
  type ServiceClient,
  ServiceClientConfig,
  ServiceRequest,
  type ServiceResponse,
  type ServiceProtocol,
} from '../core/service_client';
import { HttpClientException } from './http_client_exception';

export class HttpServiceClient implements ServiceClient {
  private readonly config: ServiceClientConfig;

  constructor(config: ServiceClientConfig) {
    this.config = config;
  }

  async send(request: ServiceRequest): Promise<ServiceResponse> {
    if (request.protocol !== ('http' satisfies ServiceProtocol)) {
      throw new Error('Unsupported protocol for HttpServiceClient');
    }

    const url = new URL(request.endpoint, this.config.baseUrl);
    const effectiveHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      ...this.config.defaultHeaders,
      ...(request.headers ?? {}),
    };

    const encodedBody = this.encodeBody(
      request.body,
      request.method.toUpperCase() === 'POST',
    );

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeout);

    try {
      const response = await fetch(url.toString(), {
        method: request.method.toUpperCase(),
        headers: effectiveHeaders,
        body: encodedBody,
        signal: controller.signal,
      });

      clearTimeout(timer);

      const rawBody = await response.text();

      if (response.status >= 200 && response.status < 300) {
        const data = rawBody.length > 0 ? JSON.parse(rawBody) : undefined;
        return {
          statusCode: response.status,
          headers: Object.fromEntries(response.headers.entries()),
          rawBody,
          data,
        };
      }

      let responseData: Record<string, unknown> | undefined;
      try {
        responseData = JSON.parse(rawBody) as Record<string, unknown>;
      } catch {
        // Response body is not valid JSON — leave as undefined
      }

      throw new HttpClientException({
        statusCode: response.status,
        message: request.errorMessage,
        response: responseData,
      });
    } catch (e) {
      clearTimeout(timer);

      if (e instanceof HttpClientException) throw e;

      throw new Error(`${request.errorMessage}: [Connection error] - ${e}`);
    }
  }

  async close(): Promise<void> {
    // fetch does not maintain persistent connections — no-op
  }

  /// Encodes the request body as JSON string.
  /// POST sends '{}' when body is null/undefined (B-04).
  /// If body is already a string, pass as-is (B-05).
  private encodeBody(body: unknown, isPost: boolean): string | undefined {
    if (body == null) {
      return isPost ? '{}' : undefined;
    }
    if (typeof body === 'string') return body;
    return JSON.stringify(body);
  }
}
