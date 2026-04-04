/// Parity tests — validates TypeScript SDK against shared JSON fixtures.
///
/// Reads fixtures from code/tests/fixtures/ and verifies that
/// the TS implementation produces identical results to Dart and Python.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { success, failure, isSuccess, isFailure } from '../src/core/result';
import { ServiceFailure } from '../src/core/service_failure';
import { ServiceClientConfig, ServiceRequest } from '../src/core/service_client';
import { HttpClientException } from '../src/http/http_client_exception';

type FixtureCase = Record<string, unknown>;
interface Fixture {
  cases: FixtureCase[];
}

function loadFixture(name: string): Fixture {
  const path = resolve(__dirname, '../../tests/fixtures', `${name}.json`);
  return JSON.parse(readFileSync(path, 'utf-8')) as Fixture;
}

describe('Parity: Result', () => {
  const fixture = loadFixture('result');

  for (const c of fixture.cases) {
    const id = c['id'] as string;
    const input = c['input'] as Record<string, unknown>;
    const expected = c['expect'] as Record<string, unknown>;

    it(id, () => {
      if (input['type'] === 'success') {
        const result = success(input['value']);
        expect(isSuccess(result)).toBe(expected['is_success']);
        expect(isFailure(result)).toBe(expected['is_failure']);
        if (isSuccess(result)) {
          expect(result.value).toEqual(expected['value']);
        }
      } else {
        if (typeof input['error'] === 'object' && input['error'] !== null) {
          const errorMap = input['error'] as Record<string, unknown>;
          const sf = new ServiceFailure({
            statusCode: errorMap['status_code'] as number,
            message: errorMap['message'] as string,
          });
          const result = failure(sf);
          expect(isFailure(result)).toBe(true);
          if (isFailure(result)) {
            const err = result.error as ServiceFailure;
            expect(err.statusCode).toBe(expected['error_status_code']);
            expect(err.message).toBe(expected['error_message']);
          }
        } else {
          const result = failure(input['error']);
          expect(isFailure(result)).toBe(true);
          if (isFailure(result)) {
            expect(result.error).toEqual(expected['error']);
          }
        }
      }
    });
  }
});

describe('Parity: ServiceClientConfig', () => {
  const fixture = loadFixture('service_client_config');

  for (const c of fixture.cases) {
    const id = c['id'] as string;
    const input = c['input'] as Record<string, unknown>;
    const expected = c['expect'] as Record<string, unknown>;

    it(id, () => {
      const config = new ServiceClientConfig({
        baseUrl: input['base_url'] as string,
      });

      if ('base_url_ends_with_slash' in expected) {
        expect(config.baseUrl.pathname.endsWith('/')).toBe(
          expected['base_url_ends_with_slash'],
        );
      }
      if ('timeout_seconds' in expected) {
        expect(config.timeout / 1000).toBe(expected['timeout_seconds']);
      }
      if ('default_headers' in expected) {
        expect(config.defaultHeaders).toEqual(expected['default_headers']);
      }
    });
  }
});

describe('Parity: ServiceRequest', () => {
  const fixture = loadFixture('service_request');

  for (const c of fixture.cases) {
    const id = c['id'] as string;
    const input = c['input'] as Record<string, unknown>;
    const expected = c['expect'] as Record<string, unknown>;

    it(id, () => {
      const request = ServiceRequest.http({
        method: input['method'] as string,
        endpoint: input['endpoint'] as string,
        headers: input['headers'] as Record<string, string> | undefined,
        body: input['body'] as unknown,
        errorMessage: (input['error_message'] as string) ?? undefined,
      });

      if ('protocol' in expected) {
        expect(request.protocol).toBe(expected['protocol']);
      }
      if ('error_message' in expected) {
        expect(request.errorMessage).toBe(expected['error_message']);
      }
      if ('method' in expected) {
        expect(request.method).toBe(expected['method']);
      }
      if ('endpoint' in expected) {
        expect(request.endpoint).toBe(expected['endpoint']);
      }
      if ('headers' in expected) {
        expect(request.headers).toEqual(expected['headers']);
      }
      if ('body' in expected) {
        expect(request.body).toEqual(expected['body']);
      }
    });
  }
});

describe('Parity: Errors', () => {
  const fixture = loadFixture('errors');

  for (const c of fixture.cases) {
    const id = c['id'] as string;
    const input = c['input'] as Record<string, unknown>;
    const expected = c['expect'] as Record<string, unknown>;

    it(id, () => {
      if ((id as string).startsWith('service-failure')) {
        const sf = new ServiceFailure({
          statusCode: input['status_code'] as number,
          message: input['message'] as string,
          responseBody: input['response_body'] as Record<string, unknown> | undefined,
        });

        expect(sf.statusCode).toBe(input['status_code']);
        expect(sf.message).toBe(input['message']);

        if ('response_body_is_null' in expected) {
          expect(sf.responseBody).toBeUndefined();
        }
        if ('response_body' in expected) {
          expect(sf.responseBody).toEqual(expected['response_body']);
        }
        if ('to_string_contains' in expected) {
          const str = sf.toString();
          for (const s of expected['to_string_contains'] as string[]) {
            expect(str).toContain(s);
          }
        }
      } else {
        const exc = new HttpClientException({
          statusCode: input['status_code'] as number,
          message: input['message'] as string,
          response: input['response'] as Record<string, unknown> | undefined,
        });

        expect(exc.statusCode).toBe(input['status_code']);
        expect(exc.message).toBe(input['message']);

        if ('response_is_null' in expected) {
          expect(exc.response).toBeUndefined();
        }
        if ('response' in expected) {
          expect(exc.response).toEqual(expected['response']);
        }
        if ('to_string_contains' in expected) {
          const str = exc.toString();
          for (const s of expected['to_string_contains'] as string[]) {
            expect(str).toContain(s);
          }
        }
      }
    });
  }
});
