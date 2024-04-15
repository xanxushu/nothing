import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/ui/study/timersetting_screen.dart';
import 'package:nothingtodo/ui/study/studytimer_screen.dart';
import 'package:nothingtodo/model/study_session.dart';
import 'package:nothingtodo/main.dart';
import 'package:nothingtodo/ui/study/studyhistory_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

// 根据你项目的结构，导入StudySession模型

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with WidgetsBindingObserver {
  int weeklyStudyDayGoal = 5; // 默认每周目标天数
  int dailyStudyMinuteGoal = 60; // 默认每日目标学习分钟数
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (user != null) {
      _loadGoals(); // 加载存储的目标值
    }
    // 初始加载数据
    _fetchStudyDaysThisWeek();
    _fetchStudyDurationToday();
  }

  // 从 Firestore 加载存储的目标值
  Future<void> _loadGoals() async {
    final docRef =
        FirebaseFirestore.instance.collection('study_goals').doc(user!.uid);

    docRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          weeklyStudyDayGoal = docSnapshot.data()?['weeklyStudyDayGoal'] ?? 5;
          dailyStudyMinuteGoal =
              docSnapshot.data()?['dailyStudyMinuteGoal'] ?? 60;
        });
      }
    });
  }

  // 将目标值保存到 Firestore
  Future<void> _saveGoals() async {
    final docRef =
        FirebaseFirestore.instance.collection('study_goals').doc(user!.uid);

    await docRef.set({
      'weeklyStudyDayGoal': weeklyStudyDayGoal,
      'dailyStudyMinuteGoal': dailyStudyMinuteGoal
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用回到前台时，刷新数据
    if (state == AppLifecycleState.resumed) {
      _fetchStudyDaysThisWeek();
      _fetchStudyDurationToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日事，今日毕！'),
        backgroundColor: Colors.grey[200],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<int>(
              future: _fetchStudyDaysThisWeek(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                int studyDaysThisWeek = snapshot.data ?? 0;
                return _buildCardWithProgressIndicator(
                  title: '本周自习天数',
                  progress: studyDaysThisWeek.toDouble(),
                  total: weeklyStudyDayGoal.toDouble(),
                  progressColor: Colors.orange,
                  onTap: () => _setWeeklyGoal(context),
                );
              },
            ),
            FutureBuilder<Duration>(
              future: _fetchStudyDurationToday(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                Duration todayDuration = snapshot.data ?? Duration.zero;
                return _buildCardWithProgressIndicator(
                  title: '今日自习时间',
                  progress: todayDuration.inMinutes.toDouble(),
                  total: dailyStudyMinuteGoal.toDouble(), // 假设每天目标是4小时，即240分钟
                  progressColor: Colors.blue,
                  onTap: () => _setDailyGoal(context),
                );
              },
            ),
            _buildStatisticChart(context),
            _buildAverageScoreChart(context),
            _buildHistoryRecordCard(),
          ],
        ),
      ),
      floatingActionButton: _buildStartStudyButton(context),
    );
  }

  Widget _buildCardWithProgressIndicator({
    required String title,
    required double progress,
    required double total,
    required Color progressColor,
    required VoidCallback onTap,
  }) {
    // 这个函数会创建带有进度指示器的卡片
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress / total,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              const SizedBox(height: 10),
              Text('$progress / $total'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticChart(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchStudyTimeLastFiveDays(), // Your data fetching function
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        } else {
          final data = snapshot.data!;
          List<BarChartGroupData> barGroups = [];
          int index = 0;

          data.forEach((key, value) {
            barGroups.add(
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    width:
                        MediaQuery.of(context).size.width / (data.length * 2),
                    color: Colors.blue,
                    borderRadius: BorderRadius.zero, // Rectangular bars
                    rodStackItems: [
                      BarChartRodStackItem(0, value, Colors.blue),
                    ],
                    borderSide: BorderSide.none, // Remove the border side
                  ),
                ],
                showingTooltipIndicators: [
                  0
                ], // Show tooltip indicator at the top of each bar
              ),
            );
            index++;
          });

          final maxY = data.values.fold(
                  0.0, (prev, element) => element > prev ? element : prev) +
              10;

          return Card(
            elevation: 0, // No shadow
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)), // Removed Y-axis titles
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data.keys
                                    .elementAt(value.toInt()), // X-axis titles
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false), // Removed the grid
                    borderData: FlBorderData(show: false), // Removed the border
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.transparent,
                        tooltipPadding:
                            const EdgeInsets.all(0), // Adjust padding as needed
                        tooltipMargin: 0, // Adjust tooltip margin as needed
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(0)} min',
                            const TextStyle(color: Colors.blue),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildAverageScoreChart(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: fetchAverageScoresLastFiveDays(), // 您的数据获取函数
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        } else {
          final data = snapshot.data!;
          List<FlSpot> spots = [];
          List<String> dateLabels = data.keys.toList();

          for (int i = 0; i < dateLabels.length; i++) {
            spots.add(FlSpot(i.toDouble(), data[dateLabels[i]]!));
          }

          return Card(
            elevation: 0, // 无阴影
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 这里禁用顶部标题
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text('${value.toInt()}'); // Y轴标题
                          },
                          reservedSize: 28,
                          interval: 1, // 显示每个标签
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dateLabels[value.toInt()], // X轴标题
                                style: const TextStyle(color: Colors.green),
                              ),
                            );
                          },
                          reservedSize: 42,
                          interval: 1, // 显示每个标签
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false), // 移除网格
                    borderData: FlBorderData(show: false), // 移除边框
                    lineTouchData: const LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildHistoryRecordCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StudyHistoryScreen()));
      },
      child: Card(
        margin: const EdgeInsets.all(8.0), // 保持外边距一致
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 内边距一致
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('历史自习记录',
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10), // 添加一点间距
              FutureBuilder<List<StudySession>>(
                future: _fetchLatestStudySessions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('没有自习记录');
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(), // 禁用滚动
                    shrinkWrap: true, // 使ListView本身尺寸适应子项
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final session = snapshot.data![index];
                      final startTime = DateFormat('yyyy.MM.dd-HH:mm')
                          .format(session.startTime);
                      final mode = session.mode;
                      final duration = '${session.actualDuration.inMinutes}分钟';
                      return Text("$startTime, $mode, $duration",
                          style: const TextStyle(fontSize: 16.0));
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8), // 项之间的间距
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartStudyButton(BuildContext context) {
    // 创建开始自习的按钮
    return FloatingActionButton.extended(
      onPressed: () => _showStudyModeSelection(context), // 按钮点击事件
      icon: const Icon(Icons.play_arrow), // 按钮图标
      label: const Text('开始自习'), // 按钮文本
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 圆角矩形
    );
  }

  void _showStudyModeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('定时模式'),
                onTap: () {
                  Navigator.pop(context); // 关闭底部菜单
                  _navigateToTimerSettingScreen(context); // 导航到定时模式设置界面
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('随时模式'),
                onTap: () {
                  Navigator.pop(context); // 关闭底部菜单
                  _startImmediateStudySession(context); // 开始随时模式自习
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToTimerSettingScreen(BuildContext context) async {
    // 使用await关键字等待页面返回结果
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TimerSettingScreen()),
    );

    // 根据返回结果决定是否刷新数据
    if (result == true) {
      _fetchStudyDaysThisWeek();
      _fetchStudyDurationToday();
    }
  }

  void _startImmediateStudySession(BuildContext context) async {
    // 同样，监听随时模式自习结束后的返回结果
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudyTimerScreen()),
    );

    if (result == true) {
      _fetchStudyDaysThisWeek();
      _fetchStudyDurationToday();
    }
  }

  void refreshData() {
    _fetchStudyDaysThisWeek();
    _fetchStudyDurationToday();
  }

  Future<int> _fetchStudyDaysThisWeek() async {
    var now = DateTime.now();
    // 获取当前周的第一天，并设置时间为00:00:00
    var firstDayOfWeek =
        DateTime(now.year, now.month, now.day - now.weekday + 1);
    // 获取当前周的最后一天，并设置时间为23:59:59
    var lastDayOfWeek = DateTime(now.year, now.month,
        now.day + DateTime.daysPerWeek - now.weekday, 23, 59, 59);

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    var sessionsQuery = FirebaseFirestore.instance
        .collection('user_study_sessions')
        .doc(user.uid)
        .collection('sessions')
        .where('startTime', isGreaterThanOrEqualTo: firstDayOfWeek)
        .where('startTime', isLessThanOrEqualTo: lastDayOfWeek);

    var querySnapshot = await sessionsQuery.get();
    var days = querySnapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id).startTime)
        .toSet()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    //print(querySnapshot);
    return days.length;
  }

  Future<Duration> _fetchStudyDurationToday() async {
    var today = DateTime.now();
    var startOfDay = DateTime(today.year, today.month, today.day);
    var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return Duration.zero;

    var sessionsQuery = FirebaseFirestore.instance
        .collection('user_study_sessions')
        .doc(user.uid)
        .collection('sessions')
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThanOrEqualTo: endOfDay);

    var querySnapshot = await sessionsQuery.get();
    var totalDuration = querySnapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id).actualDuration)
        .fold(
            Duration.zero, (previousValue, element) => previousValue + element);

    return totalDuration;
  }

  Future<List<StudySession>> _fetchLatestStudySessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('user_study_sessions')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .limit(3)
        .get();

    return querySnapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, double>> fetchStudyTimeLastFiveDays() async {
    var now = DateTime.now();
    Map<String, double> studyTimeMap = {};

    // Initialize the last five days with zeros
    for (int i = 6; i >= 0; i--) {
      var date = now.subtract(Duration(days: i));
      String dateKey = DateFormat('MM/dd').format(date);
      studyTimeMap[dateKey] = 0.0;
    }

    var user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var fiveDaysAgo = now.subtract(const Duration(days: 6));
      var sessionsQuery = FirebaseFirestore.instance
          .collection('user_study_sessions')
          .doc(user.uid)
          .collection('sessions')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fiveDaysAgo))
          .orderBy('startTime');

      var querySnapshot = await sessionsQuery.get();

      for (var doc in querySnapshot.docs) {
        var session = StudySession.fromMap(doc.data(), doc.id);
        var dateKey = DateFormat('MM/dd').format(session.startTime);
        var durationInMinutes = session.actualDuration.inMinutes.toDouble();

        studyTimeMap.update(dateKey, (value) => value + durationInMinutes,
            ifAbsent: () => durationInMinutes);
      }
    }

    return studyTimeMap;
  }

  Future<Map<String, double>> fetchAverageScoresLastFiveDays() async {
    var now = DateTime.now();
    Map<String, double> averageScoresMap = {};

    // Initialize the last five days with zeros
    for (int i = 6; i >= 0; i--) {
      var date = now.subtract(Duration(days: i));
      String dateKey = DateFormat('MM/dd').format(date);
      averageScoresMap[dateKey] = 0.0;
    }

    var user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var fiveDaysAgo = now.subtract(const Duration(days: 6));
      var sessionsQuery = FirebaseFirestore.instance
          .collection('user_study_sessions')
          .doc(user.uid)
          .collection('sessions')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fiveDaysAgo))
          .orderBy('startTime');

      var querySnapshot = await sessionsQuery.get();
      Map<String, List<double>> scoresPerDay = {};

      for (var doc in querySnapshot.docs) {
        var session = StudySession.fromMap(doc.data(), doc.id);
        var dateKey = DateFormat('MM/dd').format(session.startTime);
        scoresPerDay.putIfAbsent(dateKey, () => []).add(session.rating ?? 0.0);
      }

      scoresPerDay.forEach((key, value) {
        averageScoresMap[key] = value.reduce((a, b) => a + b) / value.length;
      });
    }
    averageScoresMap
        .updateAll((key, value) => double.parse(value.toStringAsFixed(1)));
    return averageScoresMap;
  }

  void _setWeeklyGoal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置每周自习天数目标'),
          content: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int value) {
              weeklyStudyDayGoal = value;
            },
            children: List<Widget>.generate(8, (int index) {
              return Center(child: Text('$index 天'));
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveGoals();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 1)), // 使用修改后的 MyHomePage 构造函数
                  (Route<dynamic> route) => false, // 移除所有旧的页面
                );
                // 这里添加逻辑以保存用户设置的每周目标天数
                // 例如，更新状态或保存到持久化存储
                
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 在您的 State 类中添加一个方法来设置每日目标
  void _setDailyGoal(BuildContext context) {
    TextEditingController controller =
        TextEditingController(text: dailyStudyMinuteGoal.toString()); // 默认值
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置每日自习时间目标'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '分钟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                dailyStudyMinuteGoal = int.parse(controller.text);
                _saveGoals();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 1)), // 使用修改后的 MyHomePage 构造函数
                  (Route<dynamic> route) => false, // 移除所有旧的页面
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
