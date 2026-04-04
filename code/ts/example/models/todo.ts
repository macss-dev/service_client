/// Modelo de dominio para un item ToDo de JSONPlaceholder.
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

  toString(): string {
    return `ToDo(id: ${this.id}, title: "${this.title}", isCompleted: ${this.isCompleted})`;
  }
}
