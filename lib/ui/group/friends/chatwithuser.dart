import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/service/databasehelp.dart'; // 替换为你的数据库帮助类路径
import 'package:nothingtodo/model/massage.dart'; // 替换为你的消息模型路径
import 'package:nothingtodo/model/friendship.dart'; // 确保你有这个Friend模型
import 'package:nothingtodo/ui/group/friends/friendoperate.dart'; // 替换为你的好友操作页面路径
import 'package:intl/intl.dart'; // 用于格式化日期

class ChatWithUserPage extends StatefulWidget {
  final FriendModel friend;

  const ChatWithUserPage({
    super.key,
    required this.friend,
  });

  @override
  _ChatWithUserPageState createState() => _ChatWithUserPageState();
}

class _ChatWithUserPageState extends State<ChatWithUserPage> {
  List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController(); // 添加这行

  @override
  void initState() {
    super.initState();
    _loadChatMessages();
    _listenForNewMessages();
  }

  void _loadChatMessages() async {
    // Query the local database for existing messages
    List<ChatMessage> localMessages = (await DatabaseHelper.instance.getChatMessages(userId,widget.friend.userId))
    .map((messageMap) => ChatMessage.fromMap(messageMap))
    .toList();
    setState(() {
      messages = localMessages;
    });
  }

  void _listenForNewMessages() {
    // Listen to Firestore for new messages
    //String userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection(widget.friend.userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Parse the new message
          ChatMessage newMessage = ChatMessage.fromMap(change.doc.data()!);
          // Insert the new message at the beginning of the list (since we're reversing the order in the ListView)
          setState(() {
            messages.insert(0, newMessage);
          });
          // Save the new message to the local database
          DatabaseHelper.instance.insertChatMessage(userId,widget.friend.userId,newMessage.toMap());
        }
      }
    });
  }

  void _sendMessage() async {
    final timestamp = DateTime.now();

    // Create a new message
    final ChatMessage message = ChatMessage(
      id: '$userId-${widget.friend.userId}-$timestamp',
      senderId: userId,
      receiverId: widget.friend.userId,
      timestamp: timestamp,
      type: 'text',
      content: _controller.text,
      isRead: false,
    );

    try {
      // 尝试将消息保存到本地数据库
      await DatabaseHelper.instance.insertChatMessage(userId, widget.friend.userId, message.toMap());

      // 尝试发送消息到 Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection(widget.friend.userId)
          .doc('$timestamp')
          .set(message.toMap());

      // 也在好友的文档下保存消息，以确保双方都能看到对话
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.friend.userId)
          .collection(userId)
          .doc('$timestamp')
          .set(message.toMap());

      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // 发送失败，显示提示信息
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('消息发送失败，请重试！')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 标题栏显示好友的名字和头像
        backgroundColor: Colors.grey[200],
        title: Row(
          children: <Widget>[
            CircleAvatar(
              // 假设有一个方法从好友ID获取头像
              backgroundImage: widget.friend.userInfo.profilePictureUrl.isNotEmpty
                  ? NetworkImage(widget.friend.userInfo.profilePictureUrl)
                  : const AssetImage('assets/user_placeholder.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(widget.friend.note ?? widget.friend.userInfo.nickname),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => FriendOperationsPage(friend: widget.friend)));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true, // 使消息从下往上排列
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe =
                    message.senderId == FirebaseAuth.instance.currentUser!.uid;
                final messageTime = '${DateFormat.Md()
                    .format(message.timestamp)} ${DateFormat.Hms()
                    .format(message.timestamp)}'; // 使用DateFormat来格式化时间

                // 创建一个类似于您上传的图片的聊天气泡UI
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          messageTime,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 输入框和发送按钮布局
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10, right: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: '聊点儿什么...',
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
