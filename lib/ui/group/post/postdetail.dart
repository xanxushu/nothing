import 'package:flutter/material.dart';
import 'package:nothingtodo/model/grouppost.dart';
import 'package:nothingtodo/model/postcomment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/model/user.dart';
import 'package:flukit/flukit.dart';

class PostDetailScreen extends StatefulWidget {
  final GroupPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<Comment> comments = [];
  final TextEditingController _commentController = TextEditingController();
  String? respondingToCommentId;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  void fetchComments() async {
    FirebaseFirestore.instance
        .collection('groupPosts')
        .doc(widget.post.id)
        .collection('comments')
        .where('parentId', isEqualTo: null)
        .orderBy('postedTime', descending: true)
        .snapshots()
        .listen((snapshot) async {
      List<Comment> loadedComments = [];

      // 异步获取所有评论和回复
      for (var doc in snapshot.docs) {
        Comment comment = Comment.fromMap(doc.data(), doc.id);

        // 异步加载用户模型
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(comment.authorId)
            .get();
        UserModel user = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>, userDoc.id);
        comment.author = user;

        // 如果有回复并且回复是以列表的形式存储
        if (comment.replyCount != 0 &&
            doc.data().containsKey('replies') &&
            doc.data()['replies'] is List) {
          List<Comment> replies = [];
          List<dynamic> repliesList = doc.data()['replies'];
          for (var replyMap in repliesList) {
            if (replyMap is Map<String, dynamic>) {
              Comment reply = Comment.fromMap(replyMap, replyMap['id']);

              // 加载回复的发送者信息
              var replyUserDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(reply.authorId)
                  .get();
              if (replyUserDoc.exists) {
                UserModel replyUser = UserModel.fromMap(
                    replyUserDoc.data() as Map<String, dynamic>,
                    replyUserDoc.id);
                reply.author = replyUser;
              }

              replies.add(reply);
            }
          }
          comment.replies = replies;
        }

        loadedComments.add(comment);
      }

      // 在获取完所有数据后更新状态
      if (mounted) {
        setState(() {
          comments = loadedComments;
        });
      }
    });
  }

  void postComment(String postId, String content, {String? parentId}) async {
    if (content.isEmpty) return;

    // 获取当前用户ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 创建新评论对象
    var newComment = Comment(
      id: '', // Firestore 自动生成ID
      postId: postId,
      authorId: userId,
      content: content,
      postedTime: DateTime.now(),
      parentId: parentId, // 添加parentId以区分评论类型
      replyCount: 0, // 初始化回复计数
      replies: [], // 初始化回复列表
    );

    // 添加新评论到数据库
    DocumentReference commentDocRef = await FirebaseFirestore.instance
        .collection('groupPosts')
        .doc(postId)
        .collection('comments')
        .add(newComment.toMap());

    // 如果是回复评论，更新被回复的评论的回复计数和回复列表
    if (parentId != null) {
      FirebaseFirestore.instance
          .collection('groupPosts')
          .doc(postId)
          .collection('comments')
          .doc(parentId)
          .update({
        'replyCount': FieldValue.increment(1),
        'replies': FieldValue.arrayUnion([newComment.toMap()])
      });
    } else {
      // 如果是直接评论帖子，更新帖子的评论ID列表
      FirebaseFirestore.instance.collection('groupPosts').doc(postId).update({
        'comments': FieldValue.arrayUnion([commentDocRef.id])
      });
    }

    // 清空评论框
    _commentController.clear();
  }

  void showReplyField(Comment comment) {
    // 设置当前被回复的评论ID
    setState(() {
      respondingToCommentId = comment.id;
    });
    _commentController.text =
        '@${comment.author!.nickname} '; // 这假设你能从authorId获取到用户名
  }

  void postReply() {
    if (respondingToCommentId != null) {
      // 回复评论
      postComment(widget.post.id, _commentController.text,
          parentId: respondingToCommentId);
    } else {
      // 发布新评论
      postComment(widget.post.id, _commentController.text);
    }
    // 清空回复状态和输入框内容
    setState(() {
      respondingToCommentId = null;
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Row(
          children: <Widget>[
            CircleAvatar(
              // 假设有一个方法从好友ID获取头像
              backgroundImage: widget
                      .post.authorDetails!.profilePictureUrl.isNotEmpty
                  ? NetworkImage(widget.post.authorDetails!.profilePictureUrl)
                  : const AssetImage('assets/user_placeholder.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(widget.post.authorDetails!.nickname),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 帖子图片
            if (widget.post.mediaUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1/1,
              child: Swiper.builder(
                indicatorAlignment: AlignmentDirectional.bottomCenter,
                circular: true,
                childCount: widget.post.mediaUrls.length,
                indicator: RectangleSwiperIndicator(
                  itemColor: Colors.grey,
                  itemActiveColor: Colors.lightBlueAccent,
                ),
                itemBuilder: (context, index) => Image.network(widget.post.mediaUrls[index], fit: BoxFit.contain),
              ),
            ),
            // 帖子标题和内容
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.post.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // 点赞和评论按钮
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    // 点赞操作逻辑
                  },
                ),
                Text(widget.post.likes.toString()),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    // 评论操作逻辑
                  },
                ),
                Text(widget.post.comments.length.toString()),
              ],
            ),
            ListView.builder(
              shrinkWrap: true, // 让ListView本身决定内部大小
              physics:
                  const NeverScrollableScrollPhysics(), // 作为 SingleChildScrollView 的子视图
              itemCount: comments.length,
              itemBuilder: (context, index) => CommentWidget(
                comment: comments[index],
                onReply: () {
                  showReplyField(comments[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: respondingToCommentId != null ? '回复评论' : '写评论...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: postReply,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage:
                comment.author?.profilePictureUrl.isNotEmpty == true
                    ? NetworkImage(comment.author!.profilePictureUrl)
                    : const AssetImage('assets/user_placeholder.png')
                        as ImageProvider,
          ),
          title: Text(comment.author?.nickname ?? '匿名用户'),
          subtitle: Text(comment.content),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.thumb_up),
                onPressed: () {
                  // 点赞操作逻辑
                },
              ),
              Text(comment.likes.toString()),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: onReply,
              ),
            ],
          ),
        ),
        if (comment.replies != null)
          ...comment.replies!.map((reply) => Padding(
                padding: const EdgeInsets.only(left: 70.0),
                child: CommentWidget(
                  comment: reply,
                  onReply: (){}
                ),
              )),
      ],
    );
  }
}
