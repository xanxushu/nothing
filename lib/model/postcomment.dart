import 'package:nothingtodo/model/user.dart';

class Comment {
  final String id;
  final String postId; // 所评论的帖子ID
  final String authorId; // 评论作者的用户ID
  UserModel? author; // 评论作者的用户信息
  final String content; // 评论内容
  final DateTime postedTime; // 评论发布时间
  final String? parentId; // 回复的目标评论ID，如果此属性为空，则表示这是对帖子的直接评论
  int likes;
  final int replyCount; // 这条评论下回复的数量
  List<Comment>? replies; // 评论的回复列表

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.author,
    required this.content,
    required this.postedTime,
    this.parentId,
    this.replyCount = 0,
    this.likes = 0,
    this.replies,
  });

  // 将对象转换为map，便于存储到数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'postedTime': postedTime,
      'parentId': parentId,
      'replyCount': replyCount,
      'replies': replies?.map((reply) => reply.toMap()).toList(),
    };
  }

  // 从map转换为对象，便于从数据库读取数据
  static Comment fromMap(Map<String, dynamic> map, String documentId) {
    return Comment(
      id: documentId,
      postId: map['postId'],
      authorId: map['authorId'],
      content: map['content'],
      postedTime: map['postedTime'].toDate(),
      parentId: map['parentId'],
      replyCount: map['replyCount'] ?? 0,
      replies: map['replies'] != null
          ? List<Comment>.from((map['replies'] as List<dynamic>)
              .map((replyMap) {
                // 确保 replyMap 是 Map 类型，如果不是，可能需要进行适当的解码
                if (replyMap is Map<String, dynamic>) {
                  return Comment.fromMap(replyMap, replyMap['id']);
                } else {
                  // 如果 replyMap 不是 Map，这里处理错误或进行解码
                  // 如果 replyMap 是一个 JSON 字符串，您可能需要先解码它
                  return null; // h或者其他错误处理逻辑
                }
              })
              .where((reply) => reply != null)
              .toList())
          : null,

    );
  }

  // 更新回复数量
  Comment copyWithReplyCount(int newReplyCount) {
    return Comment(
      id: id,
      postId: postId,
      authorId: authorId,
      author: author,
      content: content,
      postedTime: postedTime,
      parentId: parentId,
      replyCount: newReplyCount,
      replies: replies,
    );
  }
}
