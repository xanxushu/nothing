import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/model/notification.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  Future<List<DocumentSnapshot>> searchUsers(String query) async {
    // Implement your Firebase user search logic here. For example:
    QuerySnapshot searchResults = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: query)
        .get();

    return searchResults.docs;
  }

  Future<bool> isAlreadyFriend(String userId, String potentialFriendId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('friendships')
        .doc(userId)
        .collection('friends')
        .doc(potentialFriendId)
        .get();

    return docSnapshot.exists;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加好友'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '搜索用户',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      searchController.clear();
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: searchQuery.isNotEmpty ? searchUsers(searchQuery) : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var userData = snapshot.data![index].data() as Map<String, dynamic>;
                      var targetUserId = snapshot.data![index].id;
                      String senderId = FirebaseAuth.instance.currentUser!.uid; // 发送者的用户ID，即当前登录的用户
                      return ListTile(
                        leading: CircleAvatar(
                          // Replace with user's profile picture if it exists.
                          backgroundImage: NetworkImage(userData['profilePictureUrl'] ?? ''),
                        ),
                        title: Text(userData['nickname'] ?? 'No Name'),
                        trailing: FutureBuilder<bool>(
                          future: isAlreadyFriend(senderId, targetUserId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // 当检查是否已经是好友的操作还在进行中时，显示一个加载指示器
                              return const CircularProgressIndicator();
                            } else if (snapshot.data == true) {
                              // 如果已经是好友，显示“发消息”按钮
                              return ElevatedButton(
                                onPressed: () {
                                  // 跳转到与该好友的聊天界面
                                  //Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatWithUserPage(userId: targetUserId)));
                                },
                                child: const Text('发消息'),
                              );
                            } else {
                              // 如果不是好友，显示“添加”按钮
                              return ElevatedButton(
                        // 在 ListTile 的 trailing 部分的 ElevatedButton 的 onPressed 中实现
                        onPressed: () async {
                          // 假设 `userData` 包含了用户的ID和昵称等信息
                 

                          // 创建通知数据
                          NotificationModel notification = NotificationModel(
                            id: '', // 通知'的ID，可以使用Firebase的doc ID
                            type: 'newfriend',
                            content: '想要添加你为好友',
                            action: 'pending', // 初始化为待处理状态
                            isRead: false,
                            isHandled: false,
                            timestamp: DateTime.now(),
                            senderId: senderId,
                            targetId: targetUserId,
                          );

                          // 存储到Firebase
                          try {
                            await FirebaseFirestore.instance
                                .collection('notifications') // 假设存储通知的集合名为'notifications'
                                .add(notification.toMap());

                            // 反馈给用户
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('好友请求已发送')));
                          } catch (e) {
                            // 出错时反馈给用户
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
                          }
                        },

                          child: const Text('添加'),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('搜索出错: ${snapshot.error}');
                } else {
                  return searchQuery.isNotEmpty
                      ? const Center(child: Text('没有找到用户'))
                      : Container(); // Show nothing if not searching
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
