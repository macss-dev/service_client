import { describe, it, expect } from 'vitest';
import { ServiceClientConfig, ServiceRequest } from '../../src/core/service_client';

describe('ServiceClientConfig', () => {
  it('normalizes baseUrl — appends / if path does not end with /', () => {
    const config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com/v1',
    });

    expect(config.baseUrl.pathname).toMatch(/\/$/);
    expect(config.baseUrl.toString()).toBe('https://api.example.com/v1/');
  });

  it('preserves trailing / if already present', () => {
    const config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com/v1/',
    });

    expect(config.baseUrl.toString()).toBe('https://api.example.com/v1/');
  });

  it('preserves empty path', () => {
    // URL always has at least '/' as pathname in Node
    const config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com',
    });

    expect(config.baseUrl.pathname).toBe('/');
  });

  it('default timeout is 30000ms', () => {
    const config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com',
    });

    expect(config.timeout).toBe(30_000);
  });

  it('default headers is empty object', () => {
    const config = new ServiceClientConfig({
      baseUrl: 'https://api.example.com',
    });

    expect(config.defaultHeaders).toEqual({});
  });
});

describe('ServiceRequest', () => {
  it('.http() sets protocol to http', () => {
    const request = ServiceRequest.http({
      method: 'GET',
      endpoint: 'todos/1',
    });

    expect(request.protocol).toBe('http');
  });

  it('.http() default errorMessage is "Error in HTTP request"', () => {
    const request = ServiceRequest.http({
      method: 'GET',
      endpoint: 'todos/1',
    });

    expect(request.errorMessage).toBe('Error in HTTP request');
  });

  it('.http() passes all named parameters', () => {
    const headers = { Authorization: 'Bearer token' };
    const body = { title: 'Test' };

    const request = ServiceRequest.http({
      method: 'POST',
      endpoint: 'todos',
      headers,
      body,
      errorMessage: 'Failed to create todo',
    });

    expect(request.method).toBe('POST');
    expect(request.endpoint).toBe('todos');
    expect(request.headers).toEqual(headers);
    expect(request.body).toEqual(body);
    expect(request.errorMessage).toBe('Failed to create todo');
  });
});
