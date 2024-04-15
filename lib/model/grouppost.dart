import 'package:nothingtodo/model/user.dart';

class GroupPost {
  final String id;
  final String groupId; // 小组ID
  final String authorId; // 作者的用户ID
  UserModel? authorDetails;
  final String title; // 帖子标题
  final String content; // 帖子内容
  final List<String> mediaUrls; // 媒体内容URL列表，如图片或视频
  final DateTime postedTime; // 帖子发布时间
  final int likes; // 点赞数
  final List<String> comments; // 评论ID列表

  GroupPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    this.authorDetails,
    required this.title,
    required this.content,
    required this.mediaUrls,
    required this.postedTime,
    this.likes = 0,
    this.comments = const [],
  });

  // 将对象转换为map，便于存储到Firebase等数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'authorId': authorId,
      'title': title,
      'content': content,
      'mediaUrls': mediaUrls,
      'postedTime': postedTime,
      'likes': likes,
      'comments': comments,
    };
  }

  // 从map转换为对象，便于从数据库读取数据
  static GroupPost fromMap(Map<String, dynamic> map, String documentId) {
    return GroupPost(
      id: documentId,
      groupId: map['groupId'],
      authorId: map['authorId'],
      title: map['title'],
      content: map['content'],
      mediaUrls: List<String>.from(map['mediaUrls']),
      postedTime: map['postedTime'].toDate(),
      likes: map['likes'] ?? 0,
      comments: List<String>.from(map['comments'] ?? []),
    );
  }
}
