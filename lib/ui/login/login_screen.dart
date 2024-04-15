import 'package:flutter/material.dart';
import 'package:nothingtodo/service/auth_service.dart';
import 'register_screen.dart';
import '../anime/animeloading.dart'; // 导入自定义加载动画

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  void _performLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      showLoadingDialog(context); // 显示加载动画
      try {
        var user = await AuthService().signInWithEmailPassword(email, password);
        if (user != null) {
          Navigator.of(context).pop(); // 首先关闭加载动画
          Navigator.of(context).pushReplacementNamed('/home'); // 跳转到主页
        }
      } catch (e) {
        Navigator.of(context).pop(); // 首先关闭加载动画
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } 
    }
  }

  void _performGoogleLogin() async {
    showLoadingDialog(context); // 显示加载动画
    try {
      var user = await AuthService().signInWithGoogle();
      if (user != null) {
        Navigator.of(context).pop(); // 首先关闭加载动画
        Navigator.of(context).pushReplacementNamed('/home'); // 跳转到主页
      }
    } catch (e) {
      Navigator.of(context).pop(); // 首先关闭加载动画
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // ...电子邮箱和密码输入框
              TextFormField(
                decoration: const InputDecoration(labelText: '电子邮箱'),
                validator: (value) => value!.isEmpty ? '请输入电子邮箱' : null,
                onSaved: (value) => email = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? '请输入密码' : null,
                onSaved: (value) => password = value!,
              ),
              ElevatedButton(
                onPressed: _performLogin,
                child: const Text('登录'), // 使用新的登录函数
              ),
              ElevatedButton(
                onPressed: _performGoogleLogin,
                child: const Text('Google 账号登录'), // 使用新的Google登录函数
              ),
              // ...注册按钮
              TextButton(
                child: const Text('没有账号？注册一个'),
                onPressed: () {
                  // 导航到注册页面
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
