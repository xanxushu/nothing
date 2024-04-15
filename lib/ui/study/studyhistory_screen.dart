import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/model/study_session.dart'; // 替换为你的StudySession模型的正确路径
import 'package:nothingtodo/main.dart';

class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  _StudyHistoryScreenState createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  late Future<List<StudySession>> _futureStudySessions;
  @override
  void initState() {
    super.initState();
    _futureStudySessions = _fetchStudySessions();
  }

  Future<List<StudySession>> _fetchStudySessions() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    var sessionsQuery = FirebaseFirestore.instance
        .collection('user_study_sessions')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('startTime', descending: true);

    var querySnapshot = await sessionsQuery.get();
    return querySnapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自习历史记录'),
        backgroundColor: Colors.grey[200],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              // 这里调用重构自习界面的逻辑，确保自习界面能够刷新
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 1)),
                (Route<dynamic> route) => false, // 移除所有旧的页面
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<StudySession>>(
        future: _futureStudySessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("发生错误"));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                StudySession session = snapshot.data![index];
                return _buildStudySessionCard(session, context);
              },
            );
          } else {
            return const Center(child: Text("没有记录"));
          }
        },
      ),
    );
  }

  Widget _buildStudySessionCard(StudySession session, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(DateFormat('yyyy-MM-dd HH:mm').format(session.startTime)),
        children: <Widget>[
          Text(
              "开始时间：${DateFormat('yyyy-MM-dd HH:mm').format(session.startTime)}"),
          Text(
              "结束时间：${session.endTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(session.endTime!) : '未结束'}"),
          Text("模式：${session.mode}"),
          Text("预期时长：${session.plannedDuration.inMinutes}分钟"),
          Text("实际时长：${session.actualDuration.inMinutes}分钟"),
          Text("暂停次数：${session.pauseCount}"),
          Text(
              "总暂停时长：${session.pauseDurations.fold(0, (prev, d) => prev + d.inMinutes)}分钟"),
          Text("总结：${session.summary}"),
          Text("得分：${session.rating?.toStringAsFixed(1)}"),
          ListTile(
            title: TextButton(
              child: const Text("删除"),
              onPressed: () => _deleteStudySession(session.id, context),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStudySession(String sessionId, BuildContext context) async {
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('你确定要删除这条自习记录吗？'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_study_sessions')
            .doc(user.uid)
            .collection('sessions')
            .doc(sessionId)
            .delete();

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('自习记录已删除')));
        // 刷新页面或执行其他逻辑
        _refreshHistoryPage();
      }
    }
  }

  void _refreshHistoryPage() {
    setState(() {
      _futureStudySessions = _fetchStudySessions(); // 重新获取数据
    });
  }
}
