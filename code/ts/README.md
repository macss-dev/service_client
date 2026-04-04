# @macss/service-client

A service client abstraction for TypeScript with the Result pattern for explicit success/failure handling.

Currently ships with an **HTTP implementation** (zero production dependencies — uses native `fetch`).
The architecture is designed to support additional transport layers in the future (see [Roadmap](../../docs/roadmap.md)).

> Also available in **Dart**: [service_client](https://pub.dev/packages/service_client) · **Python**: [macss-service-client](https://pypi.org/project/macss-service-client/)

## Features

- **Transport-agnostic interface** — `ServiceClient` defines the contract; `HttpServiceClient` implements it for HTTP
- **Result pattern** with discriminated unions — compile-time exhaustive checking via `result.type`
- `ServiceFailure` base class for typed service errors
- Configurable base URL, headers, and timeout
- **Zero production dependencies** — uses native `fetch` and `AbortController`

## Installation

```bash
npm install @macss/service-client
```

## Usage

The example below follows an MVC structure: the **View** (`main`) delegates to a **Controller**,
which calls the **Service**. The service returns a `Result` that the controller resolves via
discriminated union switch.

### Model

```typescript
export class ToDo {
  readonly id: number;
  readonly title: string;
  readonly isCompleted: boolean;

  private constructor(id: number, title: string, isCompleted: boolean) {
    this.id = id;
    this.title = title;
    this.isCompleted = isCompleted;
  }

  static fromJson(json: Record<string, unknown>): ToDo {
    return new ToDo(
      json['id'] as number,
      json['title'] as string,
      json['completed'] as boolean,
    );
  }
}
```

### Error

```typescript
import { ServiceFailure } from '@macss/service-client';

export class ToDoFailure extends ServiceFailure {
  constructor(opts: {
    statusCode: number;
    message: string;
    responseBody?: Record<string, unknown>;
  }) {
    super(opts);
  }
}
```

### Service

```typescript
import {
  type Result,
  success,
  failure,
  ServiceClientConfig,
  ServiceRequest,
  type ServiceClient,
  HttpServiceClient,
  HttpClientException,
} from '@macss/service-client';

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

  static async getTodo(id: number): Promise<Result<ToDo, ToDoFailure>> {
    const request = ServiceRequest.http({
      method: 'GET',
      endpoint: `todos/${id}`,
      errorMessage: 'Failed to fetch TODO',
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
```

### Controller

The controller returns the `Result` directly — the view decides how to render each case:

```typescript
import { type Result } from '@macss/service-client';

export class TodoController {
  async fetchTodo(id: number): Promise<Result<ToDo, ToDoFailure>> {
    return JsonPlaceholderService.getTodo(id);
  }
}
```

### View (main)

The view uses a discriminated union switch to handle success and failure:

```typescript
const controller = new TodoController();
const result = await controller.fetchTodo(1);

switch (result.type) {
  case 'success':
    console.log(`${result.value.id}: ${result.value.title}`);
    break;
  case 'failure':
    console.log(`Error ${result.error.statusCode}: ${result.error.message}`);
    break;
}
```

## License

MIT © [ccisne.dev](https://ccisne.dev)
