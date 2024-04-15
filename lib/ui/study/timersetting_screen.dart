import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nothingtodo/model/study_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'studytimer_screen.dart'; // 确保你已经创建了这个页面

class TimerSettingScreen extends StatefulWidget {
  const TimerSettingScreen({super.key});

  @override
  _TimerSettingScreenState createState() => _TimerSettingScreenState();
}

class _TimerSettingScreenState extends State<TimerSettingScreen> {
  DateTime startTime = DateTime.now();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  void dispose() {
    _summaryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  DateTime _calculateEndTime() {
    final durationInMinutes = int.tryParse(_durationController.text) ?? 0;
    return startTime.add(Duration(minutes: durationInMinutes));
  }

  void _saveStudySession() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final durationInMinutes = int.tryParse(_durationController.text) ?? 0;
      StudySession newSession = StudySession(
        startTime: startTime,
        endTime: _calculateEndTime(),
        plannedDuration: Duration(minutes: durationInMinutes),
        mode: '定时模式',
        summary: _summaryController.text,
        // 其他参数...
      );

      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('user_study_sessions')
            .doc(user.uid)
            .collection('sessions')
            .add(newSession.toMap());
        newSession.id = docRef.id;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('自习计划已保存')));

        // 跳转到自习计时页面
        Navigator.push(context, MaterialPageRoute(builder: (_) => StudyTimerScreen(initialSession: newSession)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户未登录')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置自习时间'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(labelText: '自习概要'),
            ),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: '预期时长（分钟）'), // 修改标签为分钟
              keyboardType: const TextInputType.numberWithOptions(decimal: false), // 修改键盘类型
              onChanged: (value) => setState(() {}),
            ),
            ListTile(
              title: Text('预期结束时间：${DateFormat('yyyy-MM-dd – kk:mm').format(_calculateEndTime())}'),
            ),
            ElevatedButton(
              onPressed: _saveStudySession,
              child: const Text('保存自习计划'),
            ),
          ],
        ),
      ),
    );
  }
}
