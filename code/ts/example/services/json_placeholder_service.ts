import {
  type Result,
  success,
  failure,
  ServiceClientConfig,
  ServiceRequest,
  type ServiceClient,
  HttpServiceClient,
  HttpClientException,
} from '../../src';
import { ToDo } from '../models/todo';
import { ToDoFailure } from '../models/todo_failure';

/// Servicio que conecta con la API pública de JSONPlaceholder.
export class JsonPlaceholderService {
  private static readonly config = new ServiceClientConfig({
    baseUrl: 'https://jsonplaceholder.typicode.com',
    defaultHeaders: { 'Content-Type': 'application/json' },
    timeout: 30_000,
  });

  private static client: ServiceClient | undefined;
  private static get service(): ServiceClient {
    this.client ??= new HttpServiceClient(this.config);
    return this.client;
  }

  /// Obtiene un ToDo por su id.
  ///
  /// Retorna Success<ToDo> si el request fue exitoso,
  /// o Failure<ToDoFailure> si hubo un error HTTP.
  static async getTodo(id: number): Promise<Result<ToDo, ToDoFailure>> {
    const request = ServiceRequest.http({
      method: 'GET',
      endpoint: `todos/${id}`,
      errorMessage: 'Failed to fetch TODO from JSONPlaceholder',
    });

    try {
      const response = await this.service.send(request);
      const data = response.data as Record<string, unknown>;
      return success(ToDo.fromJson(data));
    } catch (e) {
      if (e instanceof HttpClientException) {
        return failure(
          new ToDoFailure({
            statusCode: e.statusCode,
            message: e.message,
            responseBody: e.response,
          }),
        );
      }
      throw e;
    }
  }
}
