import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { ServiceClientConfig, ServiceRequest } from '../../src/core/service_client';
import { HttpServiceClient } from '../../src/http/http_service_client';
import { HttpClientException } from '../../src/http/http_client_exception';

function mockResponse(body: string, status: number, headers: Record<string, string> = {}): Response {
  return {
    status,
    headers: new Headers(headers),
    text: () => Promise.resolve(body),
  } as unknown as Response;
}

describe('HttpServiceClient', () => {
  let config: ServiceClientConfig;

  beforeEach(() => {
    config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com/v1',
      defaultHeaders: { 'X-Api-Key': 'test-key' },
    });
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('send() resolves URL from baseUrl + endpoint', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 200));

    const client = new HttpServiceClient(config);
    await client.send(ServiceRequest.http({ method: 'GET', endpoint: 'todos/1' }));

    expect(fetch).toHaveBeenCalledWith(
      'https://api.example.com/v1/todos/1',
      expect.objectContaining({ method: 'GET' }),
    );
  });

  it('send() merges headers: Content-Type → defaultHeaders → request headers', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 200));

    const client = new HttpServiceClient(config);
    await client.send(
      ServiceRequest.http({
        method: 'GET',
        endpoint: 'todos/1',
        headers: { Authorization: 'Bearer token' },
      }),
    );

    const calledHeaders = vi.mocked(fetch).mock.calls[0][1]?.headers as Record<string, string>;
    expect(calledHeaders['Content-Type']).toBe('application/json');
    expect(calledHeaders['X-Api-Key']).toBe('test-key');
    expect(calledHeaders['Authorization']).toBe('Bearer token');
  });

  it('send() request headers override defaultHeaders', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 200));

    const client = new HttpServiceClient(config);
    await client.send(
      ServiceRequest.http({
        method: 'GET',
        endpoint: 'todos/1',
        headers: { 'X-Api-Key': 'override-key' },
      }),
    );

    const calledHeaders = vi.mocked(fetch).mock.calls[0][1]?.headers as Record<string, string>;
    expect(calledHeaders['X-Api-Key']).toBe('override-key');
  });

  it('send() GET request does not send body', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 200));

    const client = new HttpServiceClient(config);
    await client.send(ServiceRequest.http({ method: 'GET', endpoint: 'todos/1' }));

    const calledBody = vi.mocked(fetch).mock.calls[0][1]?.body;
    expect(calledBody).toBeUndefined();
  });

  it('send() POST sends {} when body is null', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 201));

    const client = new HttpServiceClient(config);
    await client.send(ServiceRequest.http({ method: 'POST', endpoint: 'todos' }));

    const calledBody = vi.mocked(fetch).mock.calls[0][1]?.body;
    expect(calledBody).toBe('{}');
  });

  it('send() POST sends JSON.stringify(body) when body is object', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 201));

    const client = new HttpServiceClient(config);
    await client.send(
      ServiceRequest.http({
        method: 'POST',
        endpoint: 'todos',
        body: { title: 'Test', completed: false },
      }),
    );

    const calledBody = vi.mocked(fetch).mock.calls[0][1]?.body as string;
    const parsed = JSON.parse(calledBody);
    expect(parsed.title).toBe('Test');
    expect(parsed.completed).toBe(false);
  });

  it('send() PATCH sends body only when not null', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 200));

    const client = new HttpServiceClient(config);
    // PATCH with no body
    await client.send(ServiceRequest.http({ method: 'PATCH', endpoint: 'todos/1' }));

    const calledBody = vi.mocked(fetch).mock.calls[0][1]?.body;
    expect(calledBody).toBeUndefined();
  });

  it('send() body passes String as-is without double-encoding', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('{}', 201));

    const preEncoded = JSON.stringify({ title: 'Pre-encoded' });
    const client = new HttpServiceClient(config);
    await client.send(
      ServiceRequest.http({
        method: 'POST',
        endpoint: 'todos',
        body: preEncoded,
      }),
    );

    const calledBody = vi.mocked(fetch).mock.calls[0][1]?.body as string;
    expect(calledBody).toBe(preEncoded);
    // Not double-encoded — should not start with "\"
    expect(calledBody.startsWith('"')).toBe(false);
  });

  it('send() returns ServiceResponse with parsed JSON data on 2xx', async () => {
    vi.mocked(fetch).mockResolvedValue(
      mockResponse(JSON.stringify({ id: 1, title: 'Test' }), 200),
    );

    const client = new HttpServiceClient(config);
    const response = await client.send(
      ServiceRequest.http({ method: 'GET', endpoint: 'todos/1' }),
    );

    expect(response.statusCode).toBe(200);
    expect(response.data).toEqual({ id: 1, title: 'Test' });
    expect(response.rawBody).toBeTruthy();
  });

  it('send() returns ServiceResponse with data=undefined for empty body', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('', 204));

    const client = new HttpServiceClient(config);
    const response = await client.send(
      ServiceRequest.http({ method: 'DELETE', endpoint: 'todos/1' }),
    );

    expect(response.statusCode).toBe(204);
    expect(response.data).toBeUndefined();
  });

  it('send() throws HttpClientException on 4xx with parsed response body', async () => {
    vi.mocked(fetch).mockResolvedValue(
      mockResponse(JSON.stringify({ error: 'Not Found', detail: 'Todo 999 does not exist' }), 404),
    );

    const client = new HttpServiceClient(config);

    await expect(
      client.send(
        ServiceRequest.http({
          method: 'GET',
          endpoint: 'todos/999',
          errorMessage: 'Failed to fetch todo',
        }),
      ),
    ).rejects.toThrow(HttpClientException);

    try {
      await client.send(
        ServiceRequest.http({
          method: 'GET',
          endpoint: 'todos/999',
          errorMessage: 'Failed to fetch todo',
        }),
      );
    } catch (e) {
      const err = e as HttpClientException;
      expect(err.statusCode).toBe(404);
      expect(err.message).toBe('Failed to fetch todo');
      expect(err.response?.['error']).toBe('Not Found');
    }
  });

  it('send() throws HttpClientException on 5xx with errorMessage from request', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('Internal Server Error', 500));

    const client = new HttpServiceClient(config);

    await expect(
      client.send(
        ServiceRequest.http({
          method: 'GET',
          endpoint: 'health',
          errorMessage: 'Health check failed',
        }),
      ),
    ).rejects.toThrow(HttpClientException);
  });

  it('send() throws HttpClientException with response=undefined when body is not JSON', async () => {
    vi.mocked(fetch).mockResolvedValue(mockResponse('<html>Error</html>', 502));

    const client = new HttpServiceClient(config);

    try {
      await client.send(ServiceRequest.http({ method: 'GET', endpoint: 'todos/1' }));
    } catch (e) {
      const err = e as HttpClientException;
      expect(err.statusCode).toBe(502);
      expect(err.response).toBeUndefined();
    }
  });

  it('send() throws Error with connection error message on network failure', async () => {
    vi.mocked(fetch).mockRejectedValue(new TypeError('fetch failed'));

    const client = new HttpServiceClient(config);

    await expect(
      client.send(
        ServiceRequest.http({
          method: 'GET',
          endpoint: 'todos/1',
          errorMessage: 'Request failed',
        }),
      ),
    ).rejects.toThrow(/\[Connection error\]/);
  });

  it('close() completes without error', async () => {
    const client = new HttpServiceClient(config);
    await expect(client.close()).resolves.toBeUndefined();
  });
});
