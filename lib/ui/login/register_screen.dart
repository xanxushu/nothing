import 'package:flutter/material.dart';
import 'package:nothingtodo/service/auth_service.dart'; // 导入认证服务

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String school = ''; // 毕业院校
  String major = ''; // 专业方向
  String interest = ''; // 个人兴趣
  String profession = ''; // 职业
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '电子邮箱'),
                validator: (value) => value!.isEmpty ? '请输入电子邮箱' : null,
                onSaved: (value) => email = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? '密码至少需要6个字符' : null,
                onSaved: (value) => password = value!,
              ),
              // 添加其他可选信息的输入框
              TextFormField(
                decoration: const InputDecoration(labelText: '毕业院校'),
                onSaved: (value) => school = value!,
              ),
              // ...其他字段
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      child: const Text('注册'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          _formKey.currentState!.save();
                          try {
                            // 调用注册函数
                            var user = await AuthService()
                                .registerWithEmailPassword(email, password);
                            if (user != null) {
                              Navigator.of(context).pop(); // 返回登录页面
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            // 显示错误信息
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
