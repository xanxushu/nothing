import 'package:nothingtodo/model/user.dart';

class FriendModel {
  final String userId;
  final UserModel userInfo;
  final DateTime addedTime;
  final String? note;

  FriendModel({
    required this.userId,
    required this.userInfo,
    required this.addedTime,
    this.note,
  });

  factory FriendModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FriendModel(
      userId: documentId,
      userInfo: UserModel.fromMap(data['userInfo'], documentId),
      addedTime: (data['addedTime']).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userInfo': userInfo.toMap(),
      'addedTime': addedTime,
      'note': note,
    };
  }
}