import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../anime/animeloading.dart';
import 'dart:io';
import 'package:nothingtodo/model/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nickname = '';
  String _gender = '';
  DateTime _birthdate = DateTime.now();
  String _city = '';
  String _school = '';
  String _major = '';
  String _interest = '';
  String _profession = '';
  String _profilePictureUrl = '';
  int _level = 1;
  int _experience = 0;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture(); // 在初始化时加载当前用户的头像URL
    _loadUserInfo(); // 加载其他用户信息
  }

  @override
  void dispose() {
    // 清理控制器资源
    _nicknameController.dispose();
    _cityController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _interestController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _loadProfilePicture() {
    // 从 Firebase 加载当前用户的头像URL
    String? photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    if (photoUrl != null) {
      setState(() {
        _profilePictureUrl = photoUrl;
      });
    }
  }

  void _loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userInfo = await users.doc(user.uid).get();
      if (userInfo.exists) {
        setState(() {
          _level = userInfo['level'] ?? 1;
          _experience = userInfo['experience'] ?? 0;
          _nickname = userInfo['nickname'] ?? '';
          _nicknameController.text = _nickname;
          _gender = userInfo['gender'] ?? '';
          _birthdate = (userInfo['birthdate'] as Timestamp).toDate();
          _city = userInfo['city'] ?? '';
          _cityController.text = _city;
          _school = userInfo['school'] ?? '';
          _schoolController.text = _school;
          _major = userInfo['major'] ?? '';
          _majorController.text = _major;
          _interest = userInfo['interest'] ?? '';
          _interestController.text = _interest;
          _profession = userInfo['profession'] ?? '';
          _professionController.text = _profession;
        });
      }
    }
  }

  // 假设用户信息存储在Firestore的users集合中
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人信息'),
        backgroundColor: Colors.grey[200],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12.0),
          children: <Widget>[
            // 头像
            GestureDetector(
              onTap: _updateProfilePicture,
              child: CircleAvatar(
                radius: 60, // 调整头像大小
                backgroundImage: _profilePictureUrl.isNotEmpty
                    ? NetworkImage(_profilePictureUrl)
                    : null,
                child: _profilePictureUrl.isEmpty
                    ? const Icon(Icons.camera_alt, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // 昵称
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: '昵称'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请填写昵称';
                }
                return null;
              },
              onSaved: (value) => _nickname = value ?? '',
            ),
            const SizedBox(height: 10),
            // 性别选择
            DropdownButtonFormField<String>(
              value: _gender.isNotEmpty ? _gender : null,
              decoration: const InputDecoration(labelText: '性别'),
              items: <String>['男', '女', '非二元', '不愿透露']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 10),
            // 出生日期选择
            // 使用 TextFormField 结合 InkWell 或 GestureDetector 来弹出日期选择器
            InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _birthdate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _birthdate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '出生年月日'),
                child: Text(
                  '${_birthdate.year}-${_birthdate.month.toString().padLeft(2, '0')}-${_birthdate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 所在城市
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: '所在城市'),
              onSaved: (value) => _city = value ?? '',
            ),
            const SizedBox(height: 10),
            // 毕业院校
            TextFormField(
              controller: _schoolController,
              decoration: const InputDecoration(labelText: '毕业院校'),
              onSaved: (value) => _school = value ?? '',
            ),
            const SizedBox(height: 10),
            // 专业方向
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: '专业方向'),
              onSaved: (value) => _major = value ?? '',
            ),
            const SizedBox(height: 10),
            // 个人兴趣
            TextFormField(
              controller: _interestController,
              decoration: const InputDecoration(labelText: '个人兴趣'),
              onSaved: (value) => _interest = value ?? '',
            ),
            const SizedBox(height: 10),
            // 职业
            TextFormField(
              controller: _professionController,
              decoration: const InputDecoration(labelText: '职业'),
              onSaved: (value) => _profession = value ?? '',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileInfo,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 裁剪图片
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: '裁剪',
              toolbarColor: Colors.blueGrey,
              statusBarColor: Colors.blueGrey,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: Colors.blueGrey,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: '裁剪',
          ),
        ],
      );

      if (croppedFile != null) {
        File file = File(croppedFile.path);
        String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        String filePath = 'userProfile/$userId/avatar.png';
        showLoadingDialog(context);
        try {
          // 上传裁剪后的图片到Firebase Storage
          TaskSnapshot snapshot =
              await FirebaseStorage.instance.ref(filePath).putFile(file);

          // 获取下载URL
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // 更新用户头像信息
          User? user = FirebaseAuth.instance.currentUser;
          await user?.updatePhotoURL(downloadUrl);

          // 更新状态以在界面上显示新头像
          setState(() {
            _profilePictureUrl = downloadUrl;
          });
        } catch (e) {
          // 处理上传或更新头像时的错误
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('头像更新错误: $e')));
        } finally {
          // 关闭加载动画
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _saveProfileInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 创建UserModel实例
      UserModel user = UserModel(
        nickname: _nickname,
        gender: _gender,
        birthdate: _birthdate,
        city: _city,
        school: _school,
        major: _major,
        interest: _interest,
        profession: _profession,
        profilePictureUrl: _profilePictureUrl,
        level: _level, // 默认等级为1
        experience: _experience, // 默认经验值为0
      );

      // 显示加载动画
      showLoadingDialog(context);

      try {
        // 保存用户信息到Firestore
        User? auther = FirebaseAuth.instance.currentUser;
        if (auther != null) {
          await users
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .set(user.toMap(), SetOptions(merge: true));

          // 更新Firebase Auth的用户昵称和头像
          await auther.updateDisplayName(_nickname);
          await auther.updatePhotoURL(_profilePictureUrl);
        }
        // 反馈给用户
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('个人信息已更新')));
      } catch (e) {
        // 出错时反馈给用户
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      } finally {
        // 无论成功还是失败，都关闭加载动画
        Navigator.of(context).pop(); // 关闭对话框
      }
    }
  }
}
