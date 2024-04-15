import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // 引入图片选择器
import 'package:nothingtodo/model/group.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:nothingtodo/ui/anime/animeloading.dart'; // 引入加载对话框

class CreateGroupPage extends StatefulWidget {
  final GroupModel? group; // 可选参数，用于编辑现有小组

  const CreateGroupPage({super.key, this.group });

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String? _profilePictureUrl;
  String? _groupId;
  final _ownerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      // 如果有传入小组对象，则用它的信息初始化表单
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
      _tagsController.text = widget.group!.tags.join(', ');
      _profilePictureUrl = widget.group!.profilePictureUrl;
      _groupId = widget.group!.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:widget.group == null ? AppBar(
        title: const Text('编辑小组信息'),
        backgroundColor: Colors.grey[200],
      ): null,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          GestureDetector(
            onTap: _updateGroupPicture,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _profilePictureUrl != null
                  ? NetworkImage(_profilePictureUrl!)
                  : const AssetImage('assets/group_placeholder.png')
                      as ImageProvider,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '小组名称'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: '小组描述'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: '小组标签（用英文逗号分隔）'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createOrUpdateGroup,
            child: const Text('保存信息'),
          ),
        ],
      ),
    );
  }

  void _createOrUpdateGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('未登录')));
      return;
    }

    List<String> tags =
        _tagsController.text.split(',').map((tag) => tag.trim()).toList();

    if (widget.group == null) {
      // 创建新的小组
      GroupModel newGroup = GroupModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        creatorId: user.uid,
        adminIds: [],
        memberIds: [user.uid],
        tags: tags,
        createdTime: DateTime.now(),
        profilePictureUrl: _profilePictureUrl ?? '',
      );

      var docRef = await FirebaseFirestore.instance
          .collection('groups')
          .add(newGroup.toMap());
      FirebaseFirestore.instance
          .collection('groups')
          .doc(docRef.id)
          .update({'id': docRef.id});
    } else {
      // 更新现有小组
      FirebaseFirestore.instance.collection('groups').doc(_groupId).update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'tags': tags,
        'profilePictureUrl': _profilePictureUrl,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_groupId == null ? '小组创建成功' : '小组更新成功')));
    if (_groupId != null) {
      Navigator.pop(context); // 返回上一页
    } else {
      Navigator.pop(context);
    }
  }

  void _updateGroupPicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: '裁剪',
              toolbarColor: Colors.blueGrey,
              statusBarColor: Colors.blueGrey,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: Colors.blueGrey,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: '裁剪',
          ),
        ],
      );

      if (croppedFile != null) {
        File file = File(croppedFile.path);
        String filePath = 'groupProfile/$_ownerId/avatar.png';
        showLoadingDialog(context);
        try {
          // 上传裁剪后的图片到Firebase Storage
          TaskSnapshot snapshot =
              await FirebaseStorage.instance.ref(filePath).putFile(file);

          // 获取下载URL
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // 更新状态以在界面上显示新头像
          setState(() {
            _profilePictureUrl = downloadUrl;
          });
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('头像更新错误: $e')));
        } finally {
          // 关闭加载对话框
          Navigator.of(context).pop();
        }
      }
    }
  }
}
