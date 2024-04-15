import 'package:flutter/material.dart';
import 'package:nothingtodo/model/friendship.dart'; // 替换为您的FriendModel路径
import 'package:nothingtodo/model/user.dart'; // 替换为您的UserModel路径
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/main.dart';
import 'package:nothingtodo/ui/group/friends/friendsdetail.dart'; // 替换为您的主页路径

class FriendOperationsPage extends StatefulWidget {
  final FriendModel friend;

  const FriendOperationsPage({super.key, required this.friend});

  @override
  _FriendOperationsPageState createState() => _FriendOperationsPageState();
}

class _FriendOperationsPageState extends State<FriendOperationsPage> {
  final TextEditingController _remarkController = TextEditingController();
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    String userID = FirebaseAuth.instance.currentUser!.uid;
    getUserModelById(userID).then((UserModel user) {
      setState(() {
        currentUser = user;
      });
    });
  }

  List<Widget> buildSimilarInfoWidgets(
      UserModel currentUser, UserModel friendInfo) {
    List<Widget> widgets = [];

    // 比较城市
    if (currentUser.city == friendInfo.city) {
      widgets.add(Text("你们来自相同的城市：${currentUser.city}"));
    }

    // 比较学校
    if (currentUser.school == friendInfo.school) {
      widgets.add(Text("你们同在 ${currentUser.school} 学习"));
    }

    if (currentUser.major == friendInfo.major) {
      widgets.add(Text("你们都是 ${currentUser.major} 专业的学生"));
    }

    // 比较兴趣
    if (currentUser.interest == friendInfo.interest) {
      widgets.add(Text("你们都对 ${currentUser.interest} 很感兴趣！"));
    }

    if (currentUser.profession == friendInfo.profession) {
      widgets.add(Text("你们都是从事 ${currentUser.profession} 方面工作的！"));
    }

    if (currentUser.birthdate == friendInfo.birthdate) {
      widgets.add(Text("你们都是 ${currentUser.birthdate} 出生的"));
    }
    // 可以继续添加其他相似信息的比较和小部件添加逻辑

    return widgets;
  }

  Future<UserModel> getUserModelById(String userId) async {
    // 从Firestore获取用户信息并转换为UserModel
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      return UserModel.fromMap(userSnapshot.data()!, userSnapshot.id);
    } else {
      throw Exception("User not found");
    }
  }

  void _updateFriendNote() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String friendId = widget.friend.userId;

    // 获取Firestore中当前用户的好友文档引用
    DocumentReference friendDocRef = FirebaseFirestore.instance
        .collection('friendships')
        .doc(userId)
        .collection('friends')
        .doc(friendId);

    // 更新备注信息
    await friendDocRef
        .update({"note": _remarkController.text})
        .then((_) => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('修改备注成功！'))))
        .catchError((error) => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('修改备注失败，请重试！'))));
  }

  void _deleteFriend() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String friendId = widget.friend.userId;
    try{
      // 删除当前用户的好友列表中的该好友
      DocumentReference userFriendDocRef = FirebaseFirestore.instance
          .collection('friendships')
          .doc(userId)
          .collection('friends')
          .doc(friendId);
      await userFriendDocRef.delete();

      // 删除该好友的好友列表中的当前用户
      DocumentReference friendUserDocRef = FirebaseFirestore.instance
          .collection('friendships')
          .doc(friendId)
          .collection('friends')
          .doc(userId);
      await friendUserDocRef.delete();

      // 删除后返回上一个页面
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 2)), 
        (Route<dynamic> route) => false, // 移除所有旧的页面
        );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除好友成功！')));
    }
    catch(e){
      ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除好友失败，请重试！')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.userInfo.nickname),
        backgroundColor: Colors.grey[200],
      ),
      body: currentUser == null
          ? const CircularProgressIndicator()
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserDetailPage(user: widget.friend.userInfo)),
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        NetworkImage(widget.friend.userInfo.profilePictureUrl),
                  ),
                ),
                const SizedBox(height: 20),
                ...buildSimilarInfoWidgets(
                    currentUser!, widget.friend.userInfo), // 将生成的相似信息小部件列表展开到这里
                TextField(
                  controller: _remarkController,
                  decoration: const InputDecoration(labelText: '设置备注'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateFriendNote,
                  child: const Text('保存备注'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('删除好友'),
                          content: const Text('确定要删除这位好友吗？'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('取消'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              onPressed: _deleteFriend,
                              child: const Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('删除好友'),
                ),
              ],
            ),
    );
  }
}
