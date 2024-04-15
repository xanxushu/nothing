import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nothingtodo/model/user.dart';
import 'package:nothingtodo/model/group.dart';
import 'package:nothingtodo/ui/group/friends/friendsdetail.dart';
import 'package:nothingtodo/ui/group/groups/friendsinvite.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupMembersPage extends StatefulWidget {
  final GroupModel group;

  const GroupMembersPage({super.key, required this.group});

  @override
  _GroupMembersPageState createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {

  @override
  void initState() {
    super.initState();
  }

  Future<UserModel> _fetchUserDetails(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>, userDoc.id);
  }

  void _toggleAdmin(String memberId) async {
    setState(() {
      if (widget.group.adminIds.contains(memberId)) {
        widget.group.adminIds.remove(memberId);
      } else {
        widget.group.adminIds.add(memberId);
      }
    });

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .update({
      'adminIds': widget.group.adminIds,
    });
  }

  void _removeMember(String memberId) async {
    setState(() {
      widget.group.memberIds.remove(memberId);
      widget.group.adminIds.remove(memberId);
    });

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .update({
      'memberIds': widget.group.memberIds,
      'adminIds': widget.group.adminIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: widget.group.memberIds.length,
        itemBuilder: (context, index) {
          final memberId = widget.group.memberIds[index];
          return FutureBuilder<UserModel>(
            future: _fetchUserDetails(memberId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final member = snapshot.data!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(member.profilePictureUrl),
                  ),
                  title: Text(member.nickname),
                  subtitle: Text(widget.group.isCreator(member.id)
                      ? '小组长'
                      : widget.group.isAdmin(member.id)
                          ? '管理员'
                          : '小组成员'),
                  trailing: widget.group.isAdmin(FirebaseAuth.instance.currentUser!.uid) ?
                    (widget.group.isCreator(member.id)
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children :[
                            IconButton(
                              icon: Icon(widget.group.isAdmin(member.id)
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline),
                              onPressed: () {
                                _toggleAdmin(member.id!);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _removeMember(member.id!);
                              },
                            ),
                          ],
                        )
                    ) : null,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserDetailPage(user: member),
                    ));
                  },
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:() {
           Navigator.of(context).push(MaterialPageRoute(builder: (context) => InviteFriendsPage(groupId: widget.group.id)));
        },
        tooltip: '邀请好友',
        child: const Icon(Icons.add),
      ),
    );
  }
}
