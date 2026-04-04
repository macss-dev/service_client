import { describe, it, expect } from 'vitest';
import { success, failure, isSuccess, isFailure, type Result } from '../../src/core/result';
import { ServiceFailure } from '../../src/core/service_failure';

describe('Result', () => {
  it('success() creates a Success with the provided value', () => {
    const result = success<number, string>(42);

    expect(result.type).toBe('success');
    expect(isSuccess(result)).toBe(true);
    if (isSuccess(result)) {
      expect(result.value).toBe(42);
    }
  });

  it('failure() creates a Failure with the provided error', () => {
    const result = failure<number, string>('something went wrong');

    expect(result.type).toBe('failure');
    expect(isFailure(result)).toBe(true);
    if (isFailure(result)) {
      expect(result.error).toBe('something went wrong');
    }
  });

  it('discriminated union is exhaustive — both cases handled via switch on type', () => {
    const s = success<string, number>('ok');
    const f = failure<string, number>(404);

    function describe(r: Result<string, number>): string {
      switch (r.type) {
        case 'success':
          return `value: ${r.value}`;
        case 'failure':
          return `error: ${r.error}`;
      }
    }

    expect(describe(s)).toBe('value: ok');
    expect(describe(f)).toBe('error: 404');
  });

  it('Success.value holds the correct typed value', () => {
    const result = success<number[], string>([1, 2, 3]);

    if (isSuccess(result)) {
      expect(result.value).toEqual([1, 2, 3]);
    }
  });

  it('Failure.error holds the correct typed error (ServiceFailure)', () => {
    const result = failure<string, ServiceFailure>(
      new ServiceFailure({ statusCode: 500, message: 'Internal Server Error' }),
    );

    if (isFailure(result)) {
      expect(result.error.statusCode).toBe(500);
      expect(result.error.message).toBe('Internal Server Error');
    }
  });
});

describe('ServiceFailure', () => {
  it('stores statusCode, message, and optional responseBody', () => {
    const sf = new ServiceFailure({
      statusCode: 404,
      message: 'Not Found',
      responseBody: { detail: 'Resource does not exist' },
    });

    expect(sf.statusCode).toBe(404);
    expect(sf.message).toBe('Not Found');
    expect(sf.responseBody).toEqual({ detail: 'Resource does not exist' });
  });

  it('responseBody defaults to undefined', () => {
    const sf = new ServiceFailure({
      statusCode: 500,
      message: 'Internal Server Error',
    });

    expect(sf.responseBody).toBeUndefined();
  });

  it('toString includes statusCode and message', () => {
    const sf = new ServiceFailure({
      statusCode: 422,
      message: 'Validation failed',
    });

    expect(sf.toString()).toBe('ServiceFailure: Validation failed (statusCode: 422)');
  });
});
