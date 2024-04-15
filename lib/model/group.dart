class GroupModel {
  String id;
  final String name;
  final String description;
  final String creatorId; // 组长（创建者）的用户ID
  final List<String> adminIds; // 管理员的用户ID列表
  final List<String> memberIds; // 普通成员的用户ID列表
  final List<String> tags; // 小组标签，用于分类和推送
  final DateTime createdTime; // 小组创建时间
  final String profilePictureUrl; // 小组头像URL

  GroupModel({
    this.id = ' ',
    required this.name,
    required this.description,
    required this.creatorId,
    this.adminIds = const [],
    required this.memberIds,
    this.tags = const [],
    required this.createdTime,
    required this.profilePictureUrl,
  });

  // 将对象转换为map，便于存储到Firebase等数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'tags': tags,
      'createdTime': createdTime,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // 从map转换为对象，便于从数据库读取数据
  static GroupModel fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      id: documentId,
      name: map['name'],
      description: map['description'],
      creatorId: map['creatorId'],
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberIds: List<String>.from(map['memberIds']),
      tags: List<String>.from(map['tags'] ?? []),
      createdTime: (map['createdTime'] ).toDate(),
      profilePictureUrl: map['profilePictureUrl'],
    );
  }

  // 添加管理员
  GroupModel addAdmin(String adminId) {
    return GroupModel(
      id: id,
      name: name,
      description: description,
      creatorId: creatorId,
      adminIds: List.from(adminIds)..add(adminId),
      memberIds: memberIds,
      createdTime: createdTime,
      profilePictureUrl: profilePictureUrl,
    );
  }

  // 移除管理员
  GroupModel removeAdmin(String? adminId) {
    return GroupModel(
      id: id,
      name: name,
      description: description,
      creatorId: creatorId,
      adminIds: List.from(adminIds)..remove(adminId),
      memberIds: memberIds,
      createdTime: createdTime,
      profilePictureUrl: profilePictureUrl,
    );
  }

  // 检查是否为管理员
  bool isAdmin(String? userId) {
    return adminIds.contains(userId);
  }

  // 检查是否为组长
  bool isCreator(String? userId) {
    return creatorId == userId;
  }
}
