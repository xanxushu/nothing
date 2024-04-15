import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 用于格式化日期
import 'package:nothingtodo/model/groupmessage.dart'; // 小组消息模型
import 'package:nothingtodo/model/group.dart'; // 小组模型
import 'package:nothingtodo/ui/group/groups/groupoperate.dart'; // 引入小组管理页面
import 'package:nothingtodo/ui/group/groups/groupdetail.dart'; // 引入小组详情页面

class ChatWithGroupPage extends StatefulWidget {
  final GroupModel group;

  const ChatWithGroupPage({
    super.key,
    required this.group,
  });

  @override
  _ChatWithGroupPageState createState() => _ChatWithGroupPageState();
}

class _ChatWithGroupPageState extends State<ChatWithGroupPage> {
  List<GroupMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController();
  Map<String, String> userNicknames = {}; // 存储用户ID和昵称的映射
  Map<String, String> userProfilePictures = {}; // 存储用户ID和头像URL的映射


  @override
  void initState() {
    super.initState();
    _loadGroupMessages();
  }

  void _loadGroupMessages() async {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .collection('messages')
        .orderBy('timestamp', descending: false) // 获取最新消息
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              // 将文档数据转换为 GroupMessage 对象
              GroupMessage message = GroupMessage.fromMap(change.doc.data()!, change.doc.id);

              // 检查消息发送者是否已经加载过信息
              if (!userNicknames.containsKey(message.senderId) || !userProfilePictures.containsKey(message.senderId)) {
                // 如果没有加载过发送者信息，从数据库获取
                FirebaseFirestore.instance.collection('users').doc(message.senderId).get().then((userDoc) {
                  if (userDoc.exists) {
                    // 获取用户昵称和头像URL
                    setState(() {
                      userNicknames[message.senderId] = userDoc.data()!['nickname'];
                      userProfilePictures[message.senderId] = userDoc.data()!['profilePictureUrl'] ?? '';
                      messages.insert(0, message);
                    });
                  }
                });
              } else {
                // 如果已经加载过，直接插入消息到列表
                setState(() {
                  messages.insert(0, message);
                });
              }
            }
          }
        });
  }


  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      // 如果消息为空，则不做任何处理
      return;
    }
    final timestamp = DateTime.now();

    // 创建新消息对象
    final GroupMessage message = GroupMessage(
      id: '', // Firestore 会自动生成ID
      senderId: userId,
      groupId: widget.group.id,
      timestamp: timestamp,
      type: 'text',
      content: _controller.text,
      isRead: false,
    );

    // 发送消息到 Firestore
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .collection('messages')
          .add(message.toMap());

      _controller.clear(); // 发送成功后清空输入框

      // 滚动到最底部以显示新消息
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      // 发送失败，显示提示信息
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('消息发送失败，请重试！')));
    }
  }

  Widget _buildMessageItem(GroupMessage message) {
    bool isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            backgroundImage: userProfilePictures.containsKey(message.senderId)
                ? NetworkImage(userProfilePictures[message.senderId]!)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    userNicknames[message.senderId] ?? 'Unknown', // 显示昵称
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  DateFormat.jm().format(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name), // 这里显示小组名字
        backgroundColor: Colors.grey[200],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (userId == widget.group.creatorId) {
                // 如果当前用户是小组创建者，导航到小组管理页面
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => GroupManagementPage(group: widget.group)));
              } else {
                // 如果不是，导航到小组详情页面
                //Navigator.of(context).push(MaterialPageRoute(builder: (context) => GroupManagementPage(group: widget.group)));
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => GroupDetailPage(group: widget.group)));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // 使消息从下往上排列
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
