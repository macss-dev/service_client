import { ServiceClientConfig, ServiceRequest, type ServiceClient } from '../core/service_client';
import { HttpClientException } from './http_client_exception';
import { HttpServiceClient } from './http_service_client';

/// Convenience function for one-shot HTTP requests.
///
/// Creates a temporary HttpServiceClient, sends the request,
/// and closes the client. Returns the parsed response data.
///
/// @deprecated Use HttpServiceClient directly. Will be removed in v0.3.0.
export async function httpClient(opts: {
  method: string;
  baseUrl: string;
  endpoint: string;
  headers?: Record<string, string>;
  body?: Record<string, unknown>;
  errorMessage?: string;
}): Promise<unknown> {
  const errorMessage = opts.errorMessage ?? 'Error in HTTP request';
  let client: ServiceClient | undefined;

  const config = new ServiceClientConfig({
    baseUrl: opts.baseUrl,
    defaultHeaders: opts.headers ?? {},
  });

  try {
    client = new HttpServiceClient(config);

    const request = ServiceRequest.http({
      method: opts.method,
      endpoint: opts.endpoint,
      body: opts.body,
      errorMessage,
    });

    const response = await client.send(request);
    return response.data;
  } catch (e) {
    if (e instanceof HttpClientException) throw e;
    throw new Error(`${errorMessage}: [Connection error] - ${e}`);
  } finally {
    await client?.close();
  }
}
