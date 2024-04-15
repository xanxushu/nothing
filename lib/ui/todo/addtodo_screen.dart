import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '/model/todo_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:nothingtodo/model/tag.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Color hexToColor(String hexString) {
  return Color(int.parse(hexString.substring(1, 7), radix: 16) + 0xFF000000);
}

class AddTodoScreen extends StatefulWidget {
  final TodoItem? todoItem; // 用于编辑待办事项，如果是新建则为null
  final bool isEditing; // 标记是否为编辑状态

  const AddTodoScreen({super.key, this.todoItem, this.isEditing = false});

  @override
  _AddTodoScreenState createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _frequency = '仅一次';
  bool _alarmNeeded = false;
  Tag? _selectedTag;
  List<Tag> tags = [/* ...现有标签列表... */];

  // Flutter本地通知插件的实例
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final CollectionReference tagsCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('tags');

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('ic_launcher');
    //var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android:
            initializationSettingsAndroid); //iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    if (widget.isEditing && widget.todoItem != null) {
      _title = widget.todoItem!.title;
      _description = widget.todoItem!.description;
      _selectedDate = widget.todoItem!.dueDate;
      //_selectedTag = widget.todoItem!.tag;
      _frequency = widget.todoItem!.frequency;
      _alarmNeeded = widget.todoItem!.alarmNeeded;
    }
    _loadTags();
  }

  Future<void> _loadTags() async {
    if (!mounted) return; // 加入这行代码
    QuerySnapshot querySnapshot = await tagsCollection.get();
    List<Tag> loadedTags = querySnapshot.docs
        .map((doc) => Tag.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    if (!mounted) return; // 再次检查，以防在请求过程中组件被卸载
    setState(() {
      tags = loadedTags;
      // 可以选择在这里更新 _selectedTag 为 tags 列表中的一个有效项
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑待办事项'),
        backgroundColor: Colors.grey[200],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: '待办标题'),
              validator: (value) => value!.isEmpty ? '请输入待办标题' : null,
              onSaved: (value) => _title = value!,
            ),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: '待办描述'),
              onSaved: (value) => _description = value!,
            ),
            DropdownButtonFormField<Tag>(
              value: _selectedTag,
              items: tags.map<DropdownMenuItem<Tag>>((Tag tag) {
                return DropdownMenuItem<Tag>(
                  value: tag,
                  child: Text(tag.name,
                      style: TextStyle(color: hexToColor(tag.color))),
                );
              }).toList(),
              onChanged: (Tag? newValue) {
                setState(() {
                  _selectedTag = newValue;
                });
              },
              decoration: const InputDecoration(labelText: '标签'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 显示一个弹窗或导航到一个新页面来创建新标签
                Tag? newTag = await _showCreateTagDialog();
                if (newTag != null) {
                  await tagsCollection.add(newTag.toMap());
                  _loadTags(); // 重新加载标签
                }
              },
              child: const Text('新建标签'),
            ),
            ListTile(
              title: Text("待办日期: ${_selectedDate.toLocal()}"),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text("待办时间: ${_selectedTime.format(context)}"),
              leading: const Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            DropdownButtonFormField(
              value: _frequency,
              items: <String>['仅一次', '每天', '每周', '每月', '每年']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _frequency = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: '重复频率'),
            ),
            SwitchListTile(
              title: const Text('设置日程'),
              value: _alarmNeeded,
              onChanged: (bool value) {
                setState(() {
                  _alarmNeeded = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _saveTodoItem,
              child: const Text('保存待办事项'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleAlarm() async {
    var scheduledNotificationDateTime = tz.TZDateTime.from(
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      tz.local, // 使用本地时区
    );

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'alarm_notif',
      'Alarm Notification',
      channelDescription: 'Channel for Alarm notification',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '待办事项提醒',
      _title,
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    //print("success alerm");
  }

  Future<void> _createCalendarEvent() async {
    final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
    var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return;
      }
    }

    var calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data!.isEmpty) {
      return;
    }

    final String? calendarId = calendarsResult.data!.first.id;
    if (calendarId == null) {
      // 处理日历ID为空的情况
      return;
    }

    // 设置日历事件的开始和结束时间
    final tz.TZDateTime eventStartTime = tz.TZDateTime.from(
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      tz.local,
    );
    final tz.TZDateTime eventEndTime =
        eventStartTime.add(const Duration(hours: 1)); // 假设事件持续1小时
    RecurrenceRule? recurrenceRule;
    switch (_frequency) {
      case '每天':
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Daily);
        break;
      case '每周':
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Weekly);
        break;
      case '每月':
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Monthly);
        break;
      case '每年':
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Yearly);
        break;
      default:
        recurrenceRule = null; // 对于"仅一次"的情况，不设置重复规则
        break;
    }
    final Event event = Event(
      calendarId,
      title: _title,
      start: eventStartTime,
      end: eventEndTime,
      recurrenceRule: recurrenceRule,
    );
    event.reminders = [Reminder(minutes: 30)]; // 事件开始前 30 分钟提醒
    await deviceCalendarPlugin.createOrUpdateEvent(event);
  }

  void _saveTodoItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户未登录')));
        return;
      }

      try {
        if (widget.isEditing && widget.todoItem != null) {
          // 更新逻辑
          await FirebaseFirestore.instance
              .collection('todos')
              .doc(currentUser.uid)
              .collection('userTodos')
              .doc(widget.todoItem!.id)
              .update({
            'title': _title,
            'description': _description,
            'dueDate': DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
            'frequency': _frequency,
            'alarmNeeded': _alarmNeeded,
            'tag': _selectedTag?.toMap(),
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('待办更新成功！')));
        } else {
          // 创建新待办逻辑
              TodoItem newItem = TodoItem(
                title: _title,
                description: _description,
                dueDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
                frequency: _frequency,
                alarmNeeded: _alarmNeeded,
                tag: _selectedTag,
                isCompleted: false,
                isPinned: false,
                created: DateTime.now(),
              );

                await FirebaseFirestore.instance
                  .collection('todos')
                  .doc(currentUser.uid)
                  .collection('userTodos')
                  .add(newItem.toMap());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建待办成功！')));
          _scheduleAlarm();
          if (_alarmNeeded) { 
            _createCalendarEvent();
          }
        }
        // 使用try-catch包裹Navigator.pop确保即使发生异常也不会影响程序执行
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    }
  }


  Future<Tag?> _showCreateTagDialog() async {
    String tagName = '';
    Color tagColor = Colors.white; // 默认颜色为白色

    return showDialog<Tag>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新建标签'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(hintText: "标签名称"),
                  onChanged: (value) {
                    tagName = value;
                  },
                ),
                // 颜色选择器
                ColorPicker(
                  pickerColor: tagColor,
                  onColorChanged: (Color color) {
                    tagColor = color;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(); // 不创建标签，关闭弹窗
              },
            ),
            TextButton(
              child: const Text('创建'),
              onPressed: () async {
                if (tagName.isNotEmpty) {
                  Tag newTag =
                      Tag(name: tagName, color: tagColor.value.toString());
                  await tagsCollection.add(newTag.toMap());
                  await _loadTags(); // 重新加载标签

                  // 在列表中查找新创建的标签并更新_selectedTag
                  var foundTag = tags.firstWhere(
                    (tag) => tag.name == newTag.name,
                    orElse: () => newTag,
                  );

                  // 更新_selectedTag
                  setState(() {
                    _selectedTag = foundTag;
                  });

                  Navigator.of(context).pop(); // 关闭弹窗
                }
              },
            ),
          ],
        );
      },
    );
  }
}
