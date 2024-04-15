import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nothingtodo/ui/group/friends/friendsdetail.dart';
import 'package:nothingtodo/ui/group/post/createpost.dart';
import 'package:nothingtodo/ui/group/post/postdetail.dart';
import 'package:nothingtodo/model/user.dart'; // Ensure you import the models correctly
import 'package:nothingtodo/model/group.dart';
import 'package:nothingtodo/model/grouppost.dart';
//import 'package:nothingtodo/model/postcomment.dart';

class GroupFeedScreen extends StatefulWidget {
  const GroupFeedScreen({super.key});

  @override
  _GroupFeedScreenState createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  List<GroupModel> groups = []; // Updated to use Group model
  List<GroupPost> posts = []; // Updated to use GroupPost model
  String? selectedGroupId;

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  void _fetchUserGroups() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .get();
    final List<GroupModel> loadedGroups = querySnapshot.docs
        .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
        .toList();

    setState(() {
      groups = loadedGroups;
    });
  }

  void _fetchGroupPosts(String groupId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groupPosts')
        .where('groupId', isEqualTo: groupId)
        .get();

    List<GroupPost> loadedPosts = [];

    for (var doc in querySnapshot.docs) {
      var post = GroupPost.fromMap(doc.data(), doc.id);
      // 获取上传者的信息
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(post.authorId)
          .get();
      UserModel user =
          UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      // 假设你更新了 GroupPost 模型以包含 UserModel
      post.authorDetails = user;
      loadedPosts.add(post);
    }

    setState(() {
      posts = loadedPosts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGroupId = group.id;
                      _fetchGroupPosts(selectedGroupId!);
                    });
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      children: [
                        Expanded(
                          child: CircleAvatar(
                            backgroundImage:
                                NetworkImage(group.profilePictureUrl),
                            radius: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(group.name),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            // 使用 Navigator 跳转到用户详情页面
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                  user: posts[index].authorDetails!),
                            ));
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                                posts[index].authorDetails!.profilePictureUrl),
                          ),
                        ),
                        title: Text(posts[index].authorDetails!.nickname),
                        subtitle: Text(posts[index].postedTime.toString()),
                        trailing: const Icon(Icons.more_vert),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('${post.title} \n \n${post.content}'),
                      ),
                      if (post.mediaUrls.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1 / 1, // 根据你的需要调整纵横比
                          child: PageView.builder(
                            itemCount: posts[index].mediaUrls.length,
                            itemBuilder: (context, itemIndex) => Image.network(
                              posts[index].mediaUrls[itemIndex],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ButtonBar(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () {},
                          ),
                          Text('${post.likes}'),
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                              );
                            },
                          ),
                          Text('${post.comments.length} 条评论'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
