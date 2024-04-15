class GroupMessage {
  final String id;
  final String senderId; // 发送者ID
  final String groupId; // 小组ID
  final DateTime timestamp; // 消息时间戳
  final String type; // 消息类型，例如：text, image等
  final String content; // 消息内容
  final bool isRead; // 是否已读

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.groupId,
    required this.timestamp,
    required this.type,
    required this.content,
    this.isRead = false,
  });

  // 将对象转换为map，便于存储到Firebase等数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'groupId': groupId,
      'timestamp': timestamp,
      'type': type,
      'content': content,
      'isRead': isRead,
    };
  }

  // 从map转换为对象，便于从数据库读取数据
  static GroupMessage fromMap(Map<String, dynamic> map, String documentId) {
    return GroupMessage(
      id: documentId,
      senderId: map['senderId'],
      groupId: map['groupId'],
      timestamp:map['timestamp'].toDate(),
      type: map['type'],
      content: map['content'],
      isRead: map['isRead'],
    );
  }
}