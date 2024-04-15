import 'package:flutter/material.dart';
/*import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;*/
//import 'package:flutter_calendar_carousel/classes/event.dart';
//import 'package:flutter_calendar_carousel/classes/event_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/model/todo_item.dart'; // 确保引入了 TodoItem 类
import 'package:nothingtodo/model/tag.dart';
import 'addtodo_screen.dart'; // 导入添加待办事项页面
import 'package:intl/intl.dart'; // 需要导入 intl 包
//import 'package:flutter/src/material/dialog.dart'


Color hexToColor(String hexString) {
  return Color(int.parse(hexString.substring(1, 7), radix: 16) + 0xFF000000);
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with WidgetsBindingObserver {
  //bool _isListView = true;
  List<TodoItem> todoItems = [];
  String _sortMethod = 'created'; // 可选值: 'created', 'due'
  bool _isAscending = true;
  String _searchKeyword = '';
  List<String> _selectedTags = []; // 可以包含特殊值 '无标签'
  bool showCompleted = true;
  List<Tag> tags = []; // 在类中定义tags
  bool _showOverdue = false; 
  //DateTime _selectedDate = DateTime.now();
  //Map<DateTime, List<TodoItem>> _dateToTodoItemsMap = {};
  bool isExpanded = false; // 新增状态变量，false 表示周视图，true 表示月视图



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodoItems();
    _loadTags(); // 加载标签
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTodoItems(); // 可能的数据依赖变化时重新加载数据
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTodoItems(); // 当应用回到活跃状态，重新加载待办列表
    }
  }

  void _loadTodoItems() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // 获取并筛选用户的待办事项
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('todos')
          .doc(currentUser.uid)
          .collection('userTodos')
          //.orderBy('isPinned', descending: true) // 确保先按照isPinned字段排序
          //.orderBy(_sortMethod, descending: !_isAscending) // 然后根据其他排序标准排序
          .get();

      List<TodoItem> loadedItems = snapshot.docs
          .map((doc) => TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // 应用筛选和排序
      _filterAndSortItems(loadedItems);
      //_populateDateToTodoItemsMap(loadedItems); // 将待办事项按日期分类
    }
  }

  /*void _populateDateToTodoItemsMap(List<TodoItem> items) {
    Map<DateTime, List<TodoItem>> dateMap = {};
    for (var item in items) {
      DateTime startDate = item.dueDate;
      DateTime nextDate = startDate;
      DateTime endDate = startDate.add(const Duration(days: 365)); // 向后延伸一年

      while (nextDate.isBefore(endDate)) {
        DateTime dateKey = DateTime(nextDate.year, nextDate.month, nextDate.day);
        if (!dateMap.containsKey(dateKey)) {
          dateMap[dateKey] = [];
        }
        dateMap[dateKey]!.add(item);

        nextDate = _getNextOccurrence(nextDate, item.frequency);
      }
    }

    setState(() {
      _dateToTodoItemsMap = dateMap;
    });
  }*/

  void _loadTags() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // 获取用户的标签
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tags')
          .get();

      List<Tag> loadedTags = snapshot.docs
          .map((doc) => Tag.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        tags = loadedTags; // 更新标签列表
      });
    }
  }

  void _filterAndSortItems(List<TodoItem> items) {
    // 应用文本搜索和标签筛选
    items = items.where((item) {
      bool matchesKeyword = _searchKeyword.isEmpty || item.title.contains(_searchKeyword);

      bool matchesTag = false;
      if (_selectedTags.isEmpty || (_selectedTags.contains('无标签') && item.tag == null)) {
        matchesTag = true;
      } else if (item.tag != null && _selectedTags.contains(item.tag!.name)) {
        matchesTag = true;
      }
      bool isOverdue = item.dueDate.isBefore(DateTime.now()) && !item.isCompleted;
      bool matchesCompletion = showCompleted || !item.isCompleted;

      return matchesKeyword && matchesTag && matchesCompletion && (!_showOverdue || isOverdue);
    }).toList();

    // 应用排序

    if (_sortMethod == 'created') {
      items.sort((a, b) => _isAscending ? a.created.compareTo(b.created) : b.created.compareTo(a.created));
    } else if (_sortMethod == 'due') {
      items.sort((a, b) => _isAscending ? a.dueDate.compareTo(b.dueDate) : b.dueDate.compareTo(a.dueDate));
    }

    // 首先根据 isPinned 字段进行排序，以确保置顶的待办事项能排在前面
    items.sort((a, b) {
      // 将布尔值转换为整数进行比较
      int pinValA = a.isPinned ? 1 : 0;
      int pinValB = b.isPinned ? 1 : 0;
      return pinValB.compareTo(pinValA); // 注意：要置顶的话，应该是 B 比 A，这样isPinned为true的会排在前面
    });

    setState(() {
      todoItems = items;
    });
  }


  void _toggleCompleted(TodoItem item) async {
    // 更新待办事项的完成状态
    item.isCompleted = !item.isCompleted;

    // 保存更新到数据库
    await FirebaseFirestore.instance
        .collection('todos')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('userTodos')
        .doc(item.id)
        .update({'isCompleted': item.isCompleted});

    _loadTodoItems(); // 重新加载待办事项
  }

  /*void _updateFilteredItems() {
    FirebaseFirestore.instance
        .collection('todos')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('userTodos')
        .get()
        .then((QuerySnapshot querySnapshot) {
          List<TodoItem> filteredItems = [];
          for (var doc in querySnapshot.docs) {
            var item = TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);

            // 根据搜索关键词进行筛选
            bool matchesKeyword = _searchKeyword.isEmpty || item.title.contains(_searchKeyword);

            // 根据标签进行筛选
            bool matchesTag = _selectedTags.isEmpty ||
                              (item.tag != null && _selectedTags.contains(item.tag!.name)) ||
                              (_selectedTags.contains('无标签') && item.tag == null);

            // 根据完成状态进行筛选
            bool matchesCompletion = showCompleted || !item.isCompleted;

            // 应用所有筛选条件
            if (matchesKeyword && matchesTag && matchesCompletion) {
              filteredItems.add(item);
            }
          }

          // 更新状态
          setState(() {
            todoItems = filteredItems;
          });
        });
  }*/

  Future<void> _showFilterDialog() async {
    // 保持局部状态，用于对话框中的即时更新
    List<String> tempSelectedTags = List.from(_selectedTags);
    bool tempShowCompleted = showCompleted;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('筛选待办事项'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // 标签筛选
                    Wrap(
                      children: tags.map((tag) {
                        return FilterChip(
                          label: Text(tag.name),
                          selected: tempSelectedTags.contains(tag.name),
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                tempSelectedTags.add(tag.name);
                              } else {
                                tempSelectedTags.removeWhere((t) => t == tag.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    // “无标签”选项
                    CheckboxListTile(
                      title: const Text('无标签'),
                      value: tempSelectedTags.contains('无标签'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelectedTags.add('无标签');
                          } else {
                            tempSelectedTags.remove('无标签');
                          }
                        });
                      },
                    ),
                    // 显示已完成待办事项
                    CheckboxListTile(
                      title: const Text('显示已完成'),
                      value: tempShowCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          tempShowCompleted = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('超时未完成'),
                      value: _showOverdue,
                      onChanged: (bool? value) {
                        setState(() {
                          _showOverdue = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('应用'),
                  onPressed: () {
                    setState(() {
                      _selectedTags = tempSelectedTags;
                      showCompleted = tempShowCompleted;
                      _loadTodoItems();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body:Column(
      children: <Widget>[
        // 顶部工具栏
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /*IconButton(
              icon: Icon(_isListView ? Icons.calendar_today : Icons.list),
              onPressed: () {
                setState(() {
                  _isListView = !_isListView;
                });
              },
            ),*/
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  if (_sortMethod == value) {
                    // 如果选择的是相同的排序方法，则切换排序方向
                    _isAscending = !_isAscending;
                  } else {
                    // 如果选择了不同的排序方法，则重置为正序
                    _isAscending = true;
                    _sortMethod = value;
                  }
                  _loadTodoItems();
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'created',
                  child: Text('按创建时间'),
                ),
                const PopupMenuItem<String>(
                  value: 'due',
                  child: Text('按截止日期'),
                ),
              ],
              child: const Icon(Icons.sort),
            ),
            //const Text('待办事项'),
            // 搜索框
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索待办...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchKeyword = value;
                    _loadTodoItems();
                  });
                },
              ),
            ),
            // 筛选按钮
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () async {
              await _showFilterDialog();
              _loadTodoItems();
            },
            ),
            /*IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddTodoScreen()),
                );

                if (result == true) {
                  _loadTodoItems(); // 如果有待办事项被添加，重新加载数据
                }
              },
            ),*/
          ],
        ),
        //_buildSortFilterBar(), // 在这里调用排序、筛选和搜索栏
        Expanded(
          child: /*_isListView ?*/ _buildTodoListView() /*: _buildCalendarView()*/,
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddTodoScreen()),
        );

        if (result == true) {
          _loadTodoItems(); // 如果有待办事项被添加，重新加载数据
        }
      },
      child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoListView() {
    return ListView.builder(
      itemCount: todoItems.length,
      itemBuilder: (context, index) {
        TodoItem item = todoItems[index];
        String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(item.dueDate); // 格式化日期时间
        bool isOverdue = item.dueDate.isBefore(DateTime.now()) && !item.isCompleted;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          color: item.isCompleted ? Colors.grey[200] : Colors.white,
          child: ExpansionTile(
            leading: Checkbox(
              value: item.isCompleted,
              onChanged: (bool? value) {
                _toggleCompleted(item);
              },
            ),
            title: Text(item.title),
            subtitle: Text(
              "$formattedDate - ${item.tag?.name ?? '无标签'} | ${item.frequency}",
              style: TextStyle(
                color: item.tag != null ? hexToColor(item.tag!.color) : Colors.black,
                decoration: isOverdue ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // 限制Row所占空间的大小
              children: <Widget>[
                // 如果待办事项被置顶，显示置顶图标
                if (item.isPinned)
                  const Icon(Icons.push_pin, color: Colors.blueGrey),
                // 如果待办事项逾期，显示警告图标
                if (isOverdue)
                  const Icon(Icons.warning, color: Colors.red),
              ],
            ),
            children: <Widget>[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('待办: ${item.title}'),
                    Text('频率: ${item.frequency}'),
                    Text('创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(item.created)}'),
                    Text('截止日期: $formattedDate'),
                    Text('是否设置日程: ${item.alarmNeeded}'),
                    Text('标签: ${item.tag?.name ?? '无标签'}'),
                    Text('描述: ${item.description}'),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        TextButton(
                          child: const Text('编辑'),
                          onPressed: () => _editTodoItem(item),
                        ),
                        TextButton(
                          child: const Text('删除'),
                          onPressed: () => _deleteTodoItem(item.id),
                        ),
                        TextButton(
                          child: Text(item.isPinned ? '取消置顶' : '置顶'), // 根据 isPinned 状态动态设置文本
                          onPressed: () => _pinTodoItem(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  /*
  Widget _buildCalendarView() {
    EventList<Event> markedDates = EventList<Event>(events: {});
    _dateToTodoItemsMap.forEach((date, todos) {
      markedDates.add(
        date,
        Event(
          date: date,
          title: '有待办',
          // 可以添加其他 Event 类的属性
        ),
      );
    });

    var appBarHeight = AppBar().preferredSize.height;
    var statusBarHeight = MediaQuery.of(context).padding.top;
    var availableHeight = MediaQuery.of(context).size.height - appBarHeight - statusBarHeight;


    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
          ],
        ),
        AnimatedContainer(
            duration: const Duration(milliseconds: 500), // 动画时间
            height: isExpanded ? availableHeight * 0.6 : availableHeight * 0.2,
            child: CalendarCarousel<Event>(
              //showOnlyCurrentMonthDate: true,
              //showHeader: false,
              //showHeaderButton: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              headerTextStyle: const TextStyle(color: Colors.blue, fontSize: 20),
              iconColor: Colors.blue,
              todayButtonColor: Colors.blueAccent,
              todayBorderColor: Colors.blue,
              weekFormat: !isExpanded, // 根据 isExpanded 状态决定是周视图还是月视图
              markedDatesMap: markedDates,
              height: availableHeight * (isExpanded ? 0.6 : 0.2),
              onDayPressed: (DateTime date, List<Event> events) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: isExpanded ? availableHeight * 0.4 : availableHeight * 0.8,
            child: _buildTodoListForSelectedDate(),
          ),
        ),
      ],
    );
  }
  


  Widget _buildTodoListForSelectedDate() {
    List<TodoItem> todos = _dateToTodoItemsMap[_selectedDate] ?? [];
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        TodoItem item = todos[index];
        return Card(
          margin: const EdgeInsets.all(8.0), // 添加一些间距
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(item.description),
            // 可以根据需要添加前置或后置图标
            leading: Icon(Icons.check_circle, 
              color: item.isCompleted ? Colors.green : Colors.grey),
            // 添加点击效果
            onTap: () {
              // 可以在这里添加点击卡片后的行为
            },
          ),
        );
      },
    );
  }*/

  DateTime _getNextOccurrence(DateTime date, String frequency) {
    switch (frequency) {
      case '每天':
        return date.add(const Duration(days: 1));
      case '每周':
        return date.add(const Duration(days: 7));
      case '每月':
        return DateTime(date.year, date.month + 1, date.day);
      case '每年':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 365)); // 对于'仅一次'，延长到一年后
    }
  }

  Future<void> _deleteTodoItem(String id) async {
    // Show confirmation dialog
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('你确定要删除这个待办事项吗?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;

    // If the user confirmed the delete action
    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('todos')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('userTodos')
            .doc(id)
            .delete();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('待办事项删除成功')),
        );

        // Reload the todo list
        _loadTodoItems();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请重试')),
        );
      }
    }
  }

  Future<void> _editTodoItem(TodoItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(
          todoItem: item,
          isEditing: true,
        ),
      ),
    );

    // 检查编辑页面返回的结果
    if (result == true) {
      _loadTodoItems(); // 如果编辑后保存了待办事项，重新加载数据
    }
  }

  void _pinTodoItem(TodoItem item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户未登录')));
      return;
    }

    final newIsPinned = !item.isPinned; // 切换置顶状态

    try {
      await FirebaseFirestore.instance
          .collection('todos')
          .doc(currentUser.uid)
          .collection('userTodos')
          .doc(item.id)
          .update({'isPinned': newIsPinned});

      // 显示操作成功的提示消息，区分置顶和取消置顶操作
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newIsPinned ? '待办已置顶' : '已取消置顶'))
      );

      // 重新加载待办事项列表以反映状态变化
      _loadTodoItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$e')));
    }
  }

}