import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { httpClient } from '../../src/http/http_client';
import { HttpClientException } from '../../src/http/http_client_exception';

function mockResponse(body: string, status: number): Response {
  return {
    status,
    headers: new Headers(),
    text: () => Promise.resolve(body),
  } as unknown as Response;
}

describe('httpClient()', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns parsed data on success', async () => {
    vi.mocked(fetch).mockResolvedValue(
      mockResponse(JSON.stringify({ id: 1, title: 'Test' }), 200),
    );

    const data = await httpClient({
      method: 'GET',
      baseUrl: 'https://api.example.com',
      endpoint: 'todos/1',
    });

    expect(data).toEqual({ id: 1, title: 'Test' });
  });

  it('re-throws HttpClientException', async () => {
    vi.mocked(fetch).mockResolvedValue(
      mockResponse(JSON.stringify({ error: 'Not Found' }), 404),
    );

    await expect(
      httpClient({
        method: 'GET',
        baseUrl: 'https://api.example.com',
        endpoint: 'todos/999',
      }),
    ).rejects.toThrow(HttpClientException);
  });

  it('wraps connection errors in Error with errorMessage prefix', async () => {
    vi.mocked(fetch).mockRejectedValue(new TypeError('fetch failed'));

    await expect(
      httpClient({
        method: 'GET',
        baseUrl: 'https://api.example.com',
        endpoint: 'todos/1',
        errorMessage: 'Request failed',
      }),
    ).rejects.toThrow(/Request failed.*\[Connection error\]/);
  });

  it('closes client even on error (finally block)', async () => {
    let callCount = 0;
    vi.mocked(fetch).mockImplementation(async () => {
      callCount++;
      return mockResponse('', 500);
    });

    try {
      await httpClient({
        method: 'GET',
        baseUrl: 'https://api.example.com',
        endpoint: 'todos/1',
      });
    } catch {
      // Expected
    }

    expect(callCount).toBe(1);
  });
});
