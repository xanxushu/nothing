import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/model/study_session.dart';
import 'package:nothingtodo/ui/study/studyfinish_screen.dart';

class StudyTimerScreen extends StatefulWidget {
  final StudySession? initialSession;

  const StudyTimerScreen({super.key, this.initialSession});

  @override
  _StudyTimerScreenState createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> with WidgetsBindingObserver {
  Timer? _studyTimer;
  Duration _studyDuration = Duration.zero;
  int _pauseCount = 0;
  DateTime? _pauseStarted;
  Duration _totalPauseDuration = Duration.zero;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startOrContinueStudyTimer();
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startOrContinueStudyTimer() {
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _studyDuration += const Duration(seconds: 1);
      });
    });
  }

  void _pauseStudyTimer() {
    _studyTimer?.cancel();
    _pauseStarted = DateTime.now();
  }

  void _resumeStudyTimer() {
    if (_pauseStarted != null) {
      final pauseDuration = DateTime.now().difference(_pauseStarted!);
      _totalPauseDuration += pauseDuration;
      _pauseCount += 1;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('暂停 #$_pauseCount，持续时间：${_formatDuration(pauseDuration)}'),
      ));

      _pauseStarted = null;
    }
    _startOrContinueStudyTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _resumeStudyTimer();
    } else if (state == AppLifecycleState.paused) {
      _pauseStudyTimer();
    }
  }

  String _formatDuration(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _endStudySession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户未登录')));
      return;
    }

    final endTime = DateTime.now();
    final actualDuration = _studyDuration;
    double rating = 4.0; // 假设基础得分为4分

    // 如果有计划时长且实际时长小于计划时长，可能需要调整评分逻辑
    if (widget.initialSession != null && widget.initialSession!.plannedDuration != Duration.zero && actualDuration < widget.initialSession!.plannedDuration) {
      // 这里可以根据实际情况调整得分减少的逻辑
      rating -= 1.0;
    }

    // 根据暂停次数调整得分，每少暂停一次加0.5分，最高不超过5分
    rating += (0.5 * (3 - _pauseCount)).clamp(0, 1);
    rating = rating.clamp(0, 5); // 确保得分在0到5之间

    // 创建或更新自习会话
    StudySession sessionToUpdateOrCreate;

    if (widget.initialSession != null) {
      // 更新现有会话
      sessionToUpdateOrCreate = widget.initialSession!.copyWith(
        endTime: endTime,
        actualDuration: actualDuration,
        pauseCount: _pauseCount,
        pauseDurations: widget.initialSession!.pauseDurations + [_totalPauseDuration],
        rating: rating, // 更新评分
      );
    } else {
      // 创建新的自习会话
      sessionToUpdateOrCreate = StudySession(
        startTime: _startTime,
        endTime: endTime,
        plannedDuration: Duration.zero,
        actualDuration: actualDuration,
        mode: '随时模式',
        summary: '',
        pauseCount: _pauseCount,
        pauseDurations: [_totalPauseDuration],
        rating: rating, // 设置评分
      );
    }

    // 保存会话到Firebase
    try {
      final collectionRef = FirebaseFirestore.instance.collection('user_study_sessions').doc(user.uid).collection('sessions');
      if (widget.initialSession != null) {
        // 更新现有记录
        await collectionRef.doc(widget.initialSession!.id).update(sessionToUpdateOrCreate.toMap());
      } else {
        // 创建新记录
        await collectionRef.add(sessionToUpdateOrCreate.toMap());
      }

      if (actualDuration.inMinutes >= 60 && rating >= 3.5) {
        // 增加10点经验
        // 假设用户的经验值存储在Firestore的user文档中的experience字段
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot userSnapshot = await transaction.get(userRef);
          int currentExperience = (userSnapshot.data() as Map<String, dynamic>)['experience'] ?? 0;
          transaction.update(userRef, {'experience': currentExperience + 10});
        })
        .then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('自习会话已保存,经验+10'))))
        .catchError((error) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('经验增加失败！'))));
      }else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('自习会话已保存,本次自习未达到经验值增加条件！')));
      }
      // 跳转到自习完成界面
      Navigator.push(context, MaterialPageRoute(builder: (context) => StudyFinishScreen(session: sessionToUpdateOrCreate)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自习计时'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '您已自习：${_formatDuration(_studyDuration)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _endStudySession,
              child: const Text('结束自习'),
            ),
          ],
        ),
      ),
    );
  }
}
