import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nothingtodo/service/auth_service.dart'; // 导入认证服务
import 'edit_profile_screen.dart'; // 导入编辑个人信息页面
import 'setting_screen.dart'; // 导入设置页面
import 'package:nothingtodo/model/user.dart'; // 导入用户模型

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  UserModel? currentUserModel;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchCurrentUserModel();
  }

  void _fetchCurrentUserModel() async {
    // 假设我们将用户的经验值和等级存储在Firestore中
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      currentUserModel = UserModel.fromMap(doc.data()!, doc.id);
      setState(() {
        int past = currentUserModel!.experience;
        currentUserModel!.levelUp();
        int next = currentUserModel!.experience;
        // 如果等级发生了变化，更新Firebase中的数据
        if (past != next) {
          _updateUserLevelAndExperienceInFirebase(currentUserModel!);
        }
      });
    }
  }

  void _reloadUserInfo() {
    // 在编辑个人信息页面后，调用这个方法重新获取用户信息
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  void _updateUserLevelAndExperienceInFirebase(UserModel userModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'level': userModel.level,
        'experience': userModel.experience,
      }).then((_) {
        // 成功更新后的处理
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('等级和经验已更新')));
      }).catchError((error) {
        // 更新失败的处理
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('更新失败: $error')));
      });
    }
  }

  int _calculateExperienceNeededForNextLevel(UserModel userModel) {
    // 这里根据你的升级逻辑计算并返回距下一级还需多少经验
    // 注意，这里的计算应该与levelUp方法中的逻辑一致
    int requiredExperienceForNextLevel;
    if (userModel.level < 3) {
      requiredExperienceForNextLevel = 100 - userModel.experience;
    } else if (userModel.level == 3) {
      requiredExperienceForNextLevel = 200 - userModel.experience;
    } else if (userModel.level > 3 && userModel.level < 6) {
      requiredExperienceForNextLevel = 300 - userModel.experience;
    } else if (userModel.level >= 6 && userModel.level < 9) {
      requiredExperienceForNextLevel = 400 - userModel.experience;
    } else if (userModel.level == 9) {
      requiredExperienceForNextLevel = 500 - userModel.experience;
    } else {
      requiredExperienceForNextLevel = 0; // 如果已经是最高级别，则不再升级
    }
    return requiredExperienceForNextLevel;
  }

  @override
  Widget build(BuildContext context) {
    //user = FirebaseAuth.instance.currentUser; // 获取当前登录用户

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.grey[200],
      ),
      body: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
                '${user?.displayName}     学习等级: ${currentUserModel?.level ?? "?"}'), // 显示用户名
            accountEmail: Text(
                '${user?.email}     下级所需经验：${currentUserModel != null ? _calculateExperienceNeededForNextLevel(currentUserModel!) : "?"}'), // 显示用户邮箱
            currentAccountPicture: GestureDetector(
              onTap: () {
                // 点击头像显示大图
                _showProfilePicture(context, user?.photoURL);
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    user?.photoURL != null && user!.photoURL!.isNotEmpty
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child: user == null ||
                        user?.photoURL == null ||
                        user!.photoURL!.isEmpty
                    ? const Text(
                        "U",
                        style: TextStyle(fontSize: 40.0),
                      )
                    : null,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑个人信息'),
            onTap: () async {
              // 导航到编辑个人信息页面，并在返回时刷新用户信息
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EditProfileScreen()));
              _reloadUserInfo(); // 用户返回后，刷新信息
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              // 执行跳转到设置页面的逻辑
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('帮助与反馈'),
            onTap: () {
              // 执行跳转到帮助与反馈页面的逻辑
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('登出'),
            onTap: () async {
              await AuthService().signOut();
              Navigator.of(context)
                  .pushReplacementNamed('/login'); // 假设登录页面的路由名为'/login'
            },
          ),
        ],
      ),
    );
  }

  void _showProfilePicture(BuildContext context, String? photoURL) {
    if (photoURL != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(photoURL),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
