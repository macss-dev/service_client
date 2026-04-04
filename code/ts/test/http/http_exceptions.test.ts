import { describe, it, expect } from 'vitest';
import { HttpClientException } from '../../src/http/http_client_exception';

describe('HttpClientException', () => {
  it('stores statusCode, message, and optional response', () => {
    const exception = new HttpClientException({
      statusCode: 422,
      message: 'Validation failed',
      response: { errors: ['name is required'] },
    });

    expect(exception.statusCode).toBe(422);
    expect(exception.message).toBe('Validation failed');
    expect(exception.response).toEqual({ errors: ['name is required'] });
  });

  it('response defaults to undefined', () => {
    const exception = new HttpClientException({
      statusCode: 500,
      message: 'Internal Server Error',
    });

    expect(exception.response).toBeUndefined();
  });

  it('toString includes statusCode and message', () => {
    const exception = new HttpClientException({
      statusCode: 404,
      message: 'Not Found',
    });

    expect(exception.toString()).toBe('HttpClientException: Not Found (statusCode: 404)');
  });
});
