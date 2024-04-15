import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/ui/group/friends/searchuser.dart';
import 'package:nothingtodo/model/friendship.dart'; // 确保你有这个Friend模型
import 'package:nothingtodo/ui/group/friends/chatwithuser.dart';
import 'package:nothingtodo/model/user.dart'; // 确保你有这个User模型
import 'package:nothingtodo/ui/group/groups/creategroup.dart'; // 确保你有这个CreateGroupPage页面
import 'package:nothingtodo/model/group.dart'; // 引入GroupModel
import 'package:nothingtodo/ui/group/groups/chatingroup.dart'; // 引入ChatWithGroupPage页面

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<dynamic> itemsList = []; // 使用dynamic类型来存储好友和小组

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await _loadFriendsList();
    await _loadGroupsList();
  }

  Future<void> _loadFriendsList() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('friendships')
          .doc(userId)
          .collection('friends')
          .get();
      final friends = snapshot.docs.map((doc) => FriendModel.fromMap(doc.data(), doc.id)).toList();
      setState(() {
        itemsList.addAll(friends); // 添加好友到列表
      });
    }
  }

  Future<void> _loadGroupsList() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: userId) // 假设小组信息中有成员ID列表
          .get();
      final groups = snapshot.docs.map((doc) => GroupModel.fromMap(doc.data(), doc.id)).toList();
      setState(() {
        itemsList.addAll(groups); // 添加小组到列表
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: itemsList.length,
        itemBuilder: (context, index) {
          final item = itemsList[index];
          if (item is FriendModel) {
            // 好友信息UI
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: item.userInfo.profilePictureUrl.isNotEmpty
                    ? NetworkImage(item.userInfo.profilePictureUrl)
                    : const AssetImage('assets/user_placeholder.png') as ImageProvider,
              ),
              title: Text(item.note ?? item.userInfo.nickname),
              subtitle: const Text('聊点儿什么...'), // 示例文本，你可以根据需要修改
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatWithUserPage(friend: item)));
              },
            );
          } else if (item is GroupModel) {
            // 小组信息UI
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: item.profilePictureUrl.isNotEmpty
                    ? NetworkImage(item.profilePictureUrl)
                    : const AssetImage('assets/group_placeholder.png') as ImageProvider,
              ),
              title: Text(item.name),
              subtitle: const Text('聊点儿什么...'), // 示例文本，你可以根据需要修改
              // 根据你的逻辑实现小组聊天页面或小组详情页面的导航
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatWithGroupPage(group: item)));
              },
            );
          }
          return Container(); // 为了安全起见，加上默认返回项
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // 确保用户已登录

    // 假设你有一个方法来异步获取当前用户模型，包括等级信息
    final userModel = await _fetchCurrentUserModel(userId);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        List<Widget> menuItems = [
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('添加好友'),
            onTap: () {
              Navigator.of(context).pop(); // Dismiss the modal bottom sheet
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddFriendPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('添加小组'),
            onTap: () {
              Navigator.of(context).pop(); // Dismiss the modal bottom sheet
              // Implement add group functionality
              },
            ),
        ];

        // 只有当用户等级大于等于4级时才添加创建小组的选项
        if (userModel!.level >= 4) {
          menuItems.add(
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text('创建小组'),
              onTap: () {
                Navigator.of(context).pop(); // Dismiss the modal bottom sheet
                // 导航到创建小组页面，根据你的实际路由和页面调整
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateGroupPage()));
              },
            ),
          );
        }

        return Wrap(children: menuItems);
      },
    );
  }

  // 示例：从Firebase获取当前用户的UserModel
  Future<UserModel?> _fetchCurrentUserModel(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

}
