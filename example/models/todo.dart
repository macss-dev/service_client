/// Modelo de dominio para un item ToDo de JSONPlaceholder.
class ToDo {
  const ToDo({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory ToDo.fromJson(Map<String, dynamic> json) => ToDo(
        id: json['id'] as int,
        title: json['title'] as String,
        isCompleted: json['completed'] as bool,
      );

  final int id;
  final String title;
  final bool isCompleted;

  @override
  String toString() => 'ToDo(id: $id, title: "$title", isCompleted: $isCompleted)';
}
