class NotificationModel {
  final String id;
  final String type;
  final String content;
  final String action; // You can also use an enum or a function callback for actions.
  final bool isRead;
  final bool isHandled;

  // Additional fields you might consider:
  final DateTime timestamp; // To record the time the notification was sent.
  final String senderId; // If the notification is from a specific user or system.
  final String? senderName; // New field for sender's name
  final String? senderPhotoUrl; // New field for sender's photo URL
  final String targetId; // For directing the user to a specific page or item when they tap the notification.
  final String? targetName; // New field for sender's name
  final String? targetPhotoUrl; // New field for sender's photo URL

  NotificationModel({
    required this.id,
    required this.type,
    required this.content,
    required this.action,
    this.isRead = false,
    this.isHandled = false,
    required this.timestamp,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.targetId,
    this.targetName,
    this.targetPhotoUrl,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      type: data['type'],
      content: data['content'],
      action: data['action'],
      isRead: data['isRead'] ?? false,
      isHandled: data['isHandled'] ?? false,
      timestamp: (data['timestamp'] ).toDate(),
      senderId: data['senderId'],
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] ?? '',
      targetId: data['targetId'],
      targetName: data['targetName'],
      targetPhotoUrl: data['targetPhotoUrl'],
    );
  }

  // Method to convert notification to a map (e.g., to upload to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'action': action,
      'isRead': isRead,
      'isHandled': isHandled,
      'timestamp': timestamp,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'targetId': targetId,
      'targetName': targetName,
      'targetPhotoUrl': targetPhotoUrl,
    };
  }

  // Optional: A method to update certain fields of the notification
  NotificationModel copyWith({
    String? id,
    String? type,
    String? content,
    String? action,
    bool? isRead,
    bool? isHandled,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? targetId,
    String? targetName,
    String? targetPhotoUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      action: action ?? this.action,
      isRead: isRead ?? this.isRead,
      isHandled: isHandled ?? this.isHandled,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetPhotoUrl: targetPhotoUrl ?? this.targetPhotoUrl,
    );
  }
}