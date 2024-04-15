class UserModel {
  final String? id;
  final String nickname;
  final String gender;
  final DateTime birthdate;
  final String city;
  final String school;
  final String major;
  final String interest;
  final String profession;
  final String profilePictureUrl;
  int level; // 新增属性：用户等级
  int experience; // 新增属性：用户经验值

  UserModel({
    this.id,
    required this.nickname,
    required this.gender,
    required this.birthdate,
    required this.city,
    required this.school,
    required this.major,
    required this.interest,
    required this.profession,
    required this.profilePictureUrl,
    this.level = 1, // 默认等级为1
    this.experience = 0, // 默认经验值为0
  });

  // 将用户模型转换为Map，以便保存到Firestore
  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'gender': gender,
      'birthdate': birthdate,
      'city': city,
      'school': school,
      'major': major,
      'interest': interest,
      'profession': profession,
      'profilePictureUrl': profilePictureUrl,
      'level': level,
      'experience': experience,
    };
  }

  // 从Firestore的Map数据转换为用户模型
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      nickname: map['nickname'] ?? '',
      gender: map['gender'] ?? '',
      birthdate: (map['birthdate']).toDate(),
      city: map['city'] ?? '',
      school: map['school'] ?? '',
      major: map['major'] ?? '',
      interest: map['interest'] ?? '',
      profession: map['profession'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      level: map['level'] ?? 1, // 如果未提供，则默认为1级
      experience: map['experience'] ?? 0, // 如果未提供，则默认为0经验值
    );
  }
  
  // 方法：用户升级的逻辑，需要根据实际的经验值规则来实现
  void levelUp() {
    int requiredExperienceForNextLevel;

    while (true) {
      // 根据当前等级决定升级所需经验
      if (level < 3) {
        requiredExperienceForNextLevel = 100;
      } else if (level == 3) {
        requiredExperienceForNextLevel = 200;
      } else if (level > 3 && level < 6) {
        requiredExperienceForNextLevel = 300;
      } else if (level >= 6 && level < 9) {
        requiredExperienceForNextLevel = 400;
      } else if (level == 9) {
        requiredExperienceForNextLevel = 500;
      } else {
        // 如果已经是最高级别，则不再升级
        break;
      }

      // 检查是否有足够的经验升级
      if (experience >= requiredExperienceForNextLevel) {
        // 减去升级所需的经验，并增加等级
        experience -= requiredExperienceForNextLevel;
        level++;

        // 如果升级后的经验仍然满足下一级别的要求，继续循环判断是否可以继续升级
      } else {
        // 如果经验值不足以升级到下一级别，则退出循环
        break;
      }
    }
  }
}