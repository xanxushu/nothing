import 'package:flutter/material.dart';
import 'package:nothingtodo/ui/group/groups/creategroup.dart';
import 'package:nothingtodo/ui/group/groups/groupmembers.dart';
import 'package:nothingtodo/model/group.dart';

class GroupManagementPage extends StatefulWidget {
  final GroupModel group;

  const GroupManagementPage({super.key, required this.group});

  @override
  _GroupManagementPageState createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小组管理'),
        backgroundColor: Colors.grey[200],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '信息管理'),
            Tab(text: '成员管理'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CreateGroupPage(group: widget.group), // 小组信息管理页面
          GroupMembersPage(group: widget.group), // 小组成员管理页面
        ],
      ),
    );
  }
}
