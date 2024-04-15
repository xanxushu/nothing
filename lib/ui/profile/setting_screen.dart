import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../anime/animeloading.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.grey[200],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('密码修改'),
            leading: const Icon(Icons.lock),
            onTap: () {
              _changePassword(context);
            },
          ),
          const ListTile(
            title: Text('社交权限'),
            leading: Icon(Icons.how_to_reg),
            // onTap: () {}, // 待实现
          ),
          const ListTile(
            title: Text('通知设置'),
            leading: Icon(Icons.notifications),
            // onTap: () {}, // 待实现
          ),
          const ListTile(
            title: Text('基础设置'),
            leading: Icon(Icons.miscellaneous_services),
            // onTap: () {}, // 待实现
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('请输入您的旧密码和新密码。'),
                TextField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(labelText: '旧密码'),
                  obscureText: true,
                ),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: '新密码'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () async {
                // 修改密码的逻辑
                String oldPassword = _oldPasswordController.text;
                String newPassword = _newPasswordController.text;
                await _updatePassword(oldPassword, newPassword);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!, 
      password: oldPassword,
    );

    // 显示加载动画
    showLoadingDialog(context);

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码更新成功')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密码更新失败: ${e.message}')));
    } finally {
      // 无论成功还是失败，都关闭加载动画
      Navigator.of(context).pop(); // 关闭对话框
    }
  }


  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
