class Note {
  int? id;
  final String title;
  final String content;
  final DateTime dateTime;
  final String priority;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
      priority: map['priority'],
    );
  }
}
