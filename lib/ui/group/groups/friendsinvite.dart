import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/model/friendship.dart'; // 假设你有一个FriendModel类

class InviteFriendsPage extends StatefulWidget {
  final String groupId;

  const InviteFriendsPage({super.key, required this.groupId});

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  final List<FriendModel> _friendsList = [];
  final Map<String, bool?> _selectedFriends = {};
  List<String> _groupMembersIds = []; // 小组成员的ID列表

  @override
  void initState() {
    super.initState();
    _loadGroupMembers().then((_) => _loadFriendsList());
  }

  Future<void> _loadGroupMembers() async {
    var groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (groupDoc.exists) {
      var groupData = groupDoc.data()!;
      _groupMembersIds = List<String>.from(groupData['memberIds']);
    }
  }

  void _loadFriendsList() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance.collection('friendships').doc(userId).collection('friends').get();
    var friends = snapshot.docs.map((doc) => FriendModel.fromMap(doc.data(), doc.id)).toList();
    setState(() {
      _friendsList.addAll(friends);
      for (var friend in friends) {
        // 如果好友已在小组成员列表中，则不允许选择
        _selectedFriends[friend.userId] = _groupMembersIds.contains(friend.userId) ? null : false;
      }
    });
  }

  void _inviteSelectedFriends() async {
    final selectedFriendIds = _selectedFriends.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();
    if (selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("请选择至少一个好友进行邀请")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'memberIds': FieldValue.arrayUnion(selectedFriendIds),
      });
      Navigator.pop(context); // 邀请成功后返回
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("邀请成功")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("邀请失败: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('邀请好友'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _inviteSelectedFriends,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _friendsList.length,
        itemBuilder: (context, index) {
          var friend = _friendsList[index];
          bool? isSelected = _selectedFriends[friend.userId];
          // 如果好友已在群聊中，则不显示该好友
          if (isSelected == null) return Container();

          return CheckboxListTile(
            title: Text(friend.note ?? friend.userInfo.nickname),
            //subtitle: Text(friend.email), // 假设FriendModel有email字段
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                _selectedFriends[friend.userId] = value!;
              });
            },
          );
        },
      ),
    );
  }
}