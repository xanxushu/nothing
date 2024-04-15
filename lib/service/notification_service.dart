import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Stream<int> getUnreadNotificationCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('notifications') // 通知集合路径
          .where('targetId', isEqualTo: user.uid) // 根据接收者ID过滤
          .where('isRead', isEqualTo: false) // 仅查找未读通知
          .snapshots()
          .map((snapshot) => snapshot.docs.length); // 返回未读通知的数量
    } else {
      return Stream.value(0); // 如果用户未登录，返回0
    }
  }
}
