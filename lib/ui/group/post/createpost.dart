import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nothingtodo/model/grouppost.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _selectedGroupIds = []; // 选中的小组ID列表
  List<Map<String, dynamic>> _userGroups = []; // 当前用户所在的小组列表

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  void _fetchUserGroups() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      final List<Map<String, dynamic>> groups = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
              })
          .toList();

      setState(() {
        _userGroups = groups;
      });
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(selectedImages);
      });
    }
  }

  Widget _buildImageItem(XFile image) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0), // 小间距确保图片之间有空隙
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10), // 轻微圆角效果
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red), // 红色删除图标
          onPressed: () {
            setState(() {
              _selectedImages.remove(image);
            });
          },
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    List<Widget> imageWidgets = _selectedImages
        .map((image) => _buildImageItem(image))
        .toList();

    // 添加图片的按钮
    imageWidgets.add(
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10), // 轻微圆角效果
          ),
          child: const Center(
            child: Icon(Icons.add, size: 50),
          ),
        ),
      ),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: imageWidgets,
    );
  }

  void _showGroupSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // 使用StatefulBuilder来更新底部弹出窗口的状态
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return ListView(
              children: _userGroups.map((group) {
                return CheckboxListTile(
                  title: Text(group['name']),
                  value: _selectedGroupIds.contains(group['id']),
                  onChanged: (bool? selected) {
                    if (selected ?? false) {
                      if (!_selectedGroupIds.contains(group['id'])) {
                        setStateModal(() => _selectedGroupIds.add(group['id']));
                      }
                    } else {
                      setStateModal(() => _selectedGroupIds.remove(group['id']));
                    }
                  },
                );
              }).toList(),
            );
          },
        );
      },
    ).then((_) {
      // 当底部菜单关闭后，使用页面的setState来更新UI
      setState(() {});
    });
  }


  Widget _buildSelectedGroupsDisplay() {
    return InkWell(
      onTap: _showGroupSelector, // 点击触发小组选择器
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 8.0, // 间隔
          children: _selectedGroupIds.isEmpty
              ? [const Text('选择小组')] // 如果没有选择任何小组，显示提示信息
              : _selectedGroupIds.map((id) {
                  final groupName = _userGroups.firstWhere((group) => group['id'] == id)['name'];
                  return Chip(
                    label: Text(groupName),
                    onDeleted: () {
                      setState(() {
                        _selectedGroupIds.remove(id);
                      });
                    },
                  );
                }).toList(),
        ),
      ),
    );
  }

  void _publishPost() async {
    final userId = FirebaseAuth.instance.currentUser?.uid; // 获取当前用户ID
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }

    // 如果没有选择小组，则不允许发布
    if (_selectedGroupIds.isEmpty || _selectedGroupIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择一个小组')));
      return;
    }

    final title = _titleController.text.trim(); // 获取标题
    final content = _textController.text.trim(); // 获取内容

    // 确保标题和内容不为空
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标题和内容不能为空')));
      return;
    }
    // 上传图片到Firebase Storage并获取URL
    List<String> mediaUrls = [];
    showDialog(
      context: context,
      barrierDismissible: false, // 用户不可点击对话框外部关闭对话框
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var imageFile in _selectedImages) {
        var file = File(imageFile.path);
        var storageRef = FirebaseStorage.instance.ref().child('post_media/${file.uri.pathSegments.last}');
        var uploadTask = await storageRef.putFile(file);
        var downloadUrl = await uploadTask.ref.getDownloadURL();
        mediaUrls.add(downloadUrl);
      }

      // 创建GroupPost对象
      var newPost = GroupPost(
        id: '', // Firestore会自动产生ID
        groupId: _selectedGroupIds.join(','), // 加入所有选择的小组ID，以逗号分隔
        authorId: userId,
        title: title,
        content: content,
        mediaUrls: mediaUrls,
        postedTime: DateTime.now(), // 设置当前时间为发布时间
      );


      // 将GroupPost对象保存到Firestore
      await FirebaseFirestore.instance.collection('groupPosts').add(newPost.toMap());
      Navigator.of(context).pop();
      // 发布成功，显示消息并清空字段
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('动态发布成功')));
      _titleController.clear();
      _textController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedGroupIds.clear();
      });
      // 显示发布成功信息，并清理状态...
    } catch (e) {
      // 发生异常时，关闭加载对话框并提示用户
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑动态'),
        backgroundColor: Colors.grey[200],
        actions: [
          TextButton(
            onPressed: _publishPost, // 发布动态的逻辑
            child: const Text('发布', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0), // 外边距
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10), // 轻微圆角效果
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '分享的主题...',
                  border: InputBorder.none, // 无边框
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10), // 轻微圆角效果
              ),
              child: TextField(
                controller: _textController,
                maxLines: 5, // 增加文本框的行数
                decoration: const InputDecoration(
                  hintText: '分享点什么...',
                  border: InputBorder.none, // 无边框
                ),
              ),
            ),
            const SizedBox(height: 10), // 在文本框和图片选择器之间添加间隙
            _buildImageGrid(),
            const SizedBox(height: 20),
            _buildSelectedGroupsDisplay(),
          ],
        ),
      ),
    );
  }
}
