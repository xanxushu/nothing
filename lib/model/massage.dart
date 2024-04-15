class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final String type;
  final String content;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.type,
    required this.content,
    this.isRead = false,
  });

  // Factory method to create a ChatMessage object from a map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: map['type'],
      content: map['content'],
      isRead: map['isRead'],
    );
  }

  // Method to convert a ChatMessage object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'content': content,
      'isRead': isRead,
    };
  }
}
