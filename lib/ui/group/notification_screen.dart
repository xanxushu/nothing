import 'package:flutter/material.dart';
import 'package:nothingtodo/model/notification.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nothingtodo/model/user.dart'; 
import 'package:nothingtodo/model/friendship.dart'; 

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // This list would be populated by your data source (e.g., Firebase)
  List<NotificationModel> notifications = [];

  Future<void> _loadNotifications() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<NotificationModel> loadedNotifications = [];
      for (var doc in notificationsQuery.docs) {
        var notificationData = doc.data();
        var senderInfo = await FirebaseFirestore.instance
            .collection('users')
            .doc(notificationData['senderId'])
            .get();

        var senderData = senderInfo.data();
        var notification = NotificationModel.fromMap(notificationData, doc.id)
            .copyWith(
                senderName: senderData?['nickname'],
                senderPhotoUrl: senderData?['profilePictureUrl']);
        loadedNotifications.add(notification);
      }

      setState(() {
        notifications = loadedNotifications;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<UserModel> getUserModelById(String userId) async {
    // 从Firestore获取用户信息并转换为UserModel
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      return UserModel.fromMap(userSnapshot.data()!, userSnapshot.id);
    } else {
      throw Exception("User not found");
    }
  }

  Future<void> addFriendBidirectional(String userId1, String userId2, UserModel userInfo1, UserModel userInfo2) async {
    final user1FriendModel = FriendModel(
      userId: userId2,
      userInfo: userInfo2,
      addedTime: DateTime.now(),
    );

    final user2FriendModel = FriendModel(
      userId: userId1,
      userInfo: userInfo1,
      addedTime: DateTime.now(),
    );

    final user1FriendDoc = FirebaseFirestore.instance
        .collection('friendships')
        .doc(userId1)
        .collection('friends')
        .doc(userId2);

    final user2FriendDoc = FirebaseFirestore.instance
        .collection('friendships')
        .doc(userId2)
        .collection('friends')
        .doc(userId1);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(user1FriendDoc, user1FriendModel.toMap());
      transaction.set(user2FriendDoc, user2FriendModel.toMap());
    });
  }

  Future<void> _acceptFriendRequest(String senderId, String receiverId) async {
    // 获取sender和receiver的UserModel
    UserModel senderUserInfo = await getUserModelById(senderId);
    UserModel receiverUserInfo = await getUserModelById(receiverId);

    await addFriendBidirectional(senderId, receiverId, senderUserInfo, receiverUserInfo);
  }

  Future<void> updateNotificationStatus(String notificationId, String action) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'isHandled': true,
      'action': action,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return NotificationTile(
            notification: notifications[index],
            onAccept: () async{
              var notification = notifications[index];
              await updateNotificationStatus(notification.id, '已同意');
              _acceptFriendRequest(notification.senderId, notification.targetId);
              _loadNotifications(); // 重新加载通知列表以反映状态更新
            },
            onDecline: () {
              // TODO: Implement decline logic
            },
            onDelete: () {
              // TODO: Implement delete logic
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onAccept,
    required this.onDecline,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider backgroundImage;
      if (notification.senderPhotoUrl != null && notification.senderPhotoUrl!.isNotEmpty) {
        backgroundImage = NetworkImage(notification.senderPhotoUrl!);
      } else {
        backgroundImage = const AssetImage('assets/user_placeholder.png');
      }

    return ListTile(
      leading: CircleAvatar(
        // In a real app, you would load the image from a URL
        backgroundImage: backgroundImage
      ),
      title: Text('${notification.senderName} ${notification.content}'),
      subtitle: Text('${notification.timestamp}'),
      trailing: notification.isHandled
        ? Text(notification.action)
        : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onAccept,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDecline,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: () async {
        // Mark the notification as read when tapped
        if (!notification.isRead) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification.id)
              .update({'isRead': true});
          // Optionally, refresh the notifications list or update the UI
        }
      },
    );
  }
}
