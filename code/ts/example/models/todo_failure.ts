import { ServiceFailure } from '../../src';

/// Error de dominio para operaciones sobre ToDo.
export class ToDoFailure extends ServiceFailure {
  constructor(opts: {
    statusCode: number;
    message: string;
    responseBody?: Record<string, unknown>;
  }) {
    super(opts);
  }

  override toString(): string {
    return `ToDoFailure: ${this.message} (statusCode: ${this.statusCode})`;
  }
}
