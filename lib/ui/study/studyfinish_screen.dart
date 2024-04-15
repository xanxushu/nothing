import 'package:flutter/material.dart';
import 'package:nothingtodo/model/study_session.dart';
import 'package:nothingtodo/main.dart';

class StudyFinishScreen extends StatelessWidget {
  final StudySession session;

  const StudyFinishScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("自习总结"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "恭喜你完成本次自习！",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text("本次自习预期时长为${session.plannedDuration != Duration.zero ? '${session.plannedDuration.inMinutes}分钟' : '无预期时长'}；"),
            Text("实际自习时长为${session.actualDuration.inMinutes}分钟。"),
            Text("期间共暂停${session.pauseCount}次，"),
            ...session.pauseDurations.asMap().entries.map((entry) => Text("第${entry.key + 1}次暂停时长为${entry.value.inMinutes}分钟，")),
            Text("共暂停${session.pauseDurations.fold(Duration.zero, (prev, element) => prev + element).inMinutes}分钟。"),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "本次自习得分：\n${session.rating?.toStringAsFixed(2) ?? '未评分'}",
                style: TextStyle(
                  fontSize: 24,
                  color: _getScoreColor(session.rating),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 使用 Navigator.pushAndRemoveUntil 方法跳转到自习页面
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 1)), // 使用修改后的 MyHomePage 构造函数
                    (Route<dynamic> route) => false, // 移除所有旧的页面
                  );
                },
                child: const Text("完成"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 4) {
      return Colors.green;
    } else if (score >= 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
