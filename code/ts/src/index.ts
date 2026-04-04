/// core — service abstractions and Result pattern
export { type Result, type Success, type Failure, success, failure, isSuccess, isFailure } from './core/result';
export { ServiceFailure } from './core/service_failure';
export {
  type ServiceClient,
  ServiceClientConfig,
  ServiceRequest,
  type ServiceResponse,
  type ServiceProtocol,
} from './core/service_client';

/// http — client implementation
export { HttpServiceClient } from './http/http_service_client';
export { HttpClientException } from './http/http_client_exception';
export { httpClient } from './http/http_client'; // deprecated — removal in v0.3.0
