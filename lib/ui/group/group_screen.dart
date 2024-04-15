import 'package:flutter/material.dart';
import 'package:nothingtodo/ui/group/chatpage.dart';
import 'package:nothingtodo/ui/group/groupfeed.dart';
import 'package:nothingtodo/ui/group/notification_screen.dart';
import 'package:nothingtodo/service/notification_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交流'),
        backgroundColor: Colors.grey[200],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '聊天'),
            Tab(text: '动态'),
          ],
        ),
        actions: <Widget>[
          StreamBuilder<int>(
            stream: NotificationService().getUnreadNotificationCountStream(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) {
                count = snapshot.data!;
              }
              return IconButton(
                icon: Stack(
                  children: <Widget>[
                    const Icon(Icons.notifications),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                },
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatsPage(), // 第一个页面：当前聊天
          GroupFeedScreen(), // 第二个页面：加入的小组动态
        ],
      ),
    );
  }
}
