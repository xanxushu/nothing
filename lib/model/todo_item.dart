import 'tag.dart';

class TodoItem {
  String id;
  String title;
  String description;
  DateTime dueDate;
  String frequency;
  bool alarmNeeded;
  Tag? tag; // Tag 对象
  bool isCompleted; // 完成状态
  DateTime created; // 创建时间
  bool isPinned; // 是否置顶


  TodoItem({
    this.id = '',
    required this.title,
    this.description = '',
    required this.dueDate,
    this.frequency = '仅一次',
    this.alarmNeeded = false,
    this.tag,
    this.isCompleted = false, // 默认为未完成状态
    DateTime? created,
    this.isPinned = false,
  }) : created = created ?? DateTime.now(); // 如果未指定创建时间，则默认为当前时间

  // 将 TodoItem 转换为 Map，以便上传到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'frequency': frequency,
      'alarmNeeded': alarmNeeded,
      'tag': tag?.toMap(),
      'isCompleted': isCompleted,
      'created': created,
      'isPinned': isPinned,
    };
  }

  // 从 Firestore 数据创建 TodoItem 实例
  factory TodoItem.fromMap(Map<String, dynamic> map, String id) {
    return TodoItem(
      id: id,
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'].toDate(), // Firebase Timestamp 转换为 DateTime
      frequency: map['frequency'],
      alarmNeeded: map['alarmNeeded'],
      tag: map['tag'] != null ? Tag.fromMap(map['tag']) : null,
      isCompleted: map['isCompleted'] ?? false, // 处理可能的空值
      created: map['created'] != null ? map['created'].toDate() : DateTime.now(), // 处理可能的空值
      isPinned: map['isPinned'] ?? false,
    );
  }
}
