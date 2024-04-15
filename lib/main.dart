import 'package:flutter/material.dart';
import 'ui/todo/todo_screen.dart';
import 'ui/study/study_screen.dart';
import 'ui/group/group_screen.dart';
import 'ui/profile/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'service/firebase_options.dart';
import 'ui/login/login_screen.dart'; // 导入登录页面
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones(); // 初始化时区数据
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nothingtodo is the best',
      routes: {
        '/home': (context) => const MyHomePage(), // 主页
        '/login': (context) => const LoginScreen(), // 登录页面
        // 定义其他路由
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        secondaryHeaderColor: Colors.grey[200],
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // 显示加载指示器
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          } else if (snapshot.hasData) {
            return const MyHomePage(); // 用户已登录，显示主页
          } else {
            return const LoginScreen(); // 无用户登录，显示登录页面
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int initialPageIndex;

  const MyHomePage({super.key, this.initialPageIndex = 0});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
  }

  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const TodoScreen(),
    const StudyScreen(),
    const GroupScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        toolbarHeight: 5,
        //title: const Text('Efficiency App'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      backgroundColor: Colors.grey[200],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        enableFeedback: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '待办',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '自习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: '交流',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        backgroundColor: Colors.grey[200], // 设置导航栏背景颜色
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // 设置未选中项的颜色
        onTap: _onItemTapped,
      ),
    );
  }
}
