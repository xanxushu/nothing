import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 用户不能通过点击外部来关闭对话框
    builder: (BuildContext context) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // 加载指示器
              SizedBox(width: 20), // 一些间距
              Text("加载中，请稍候..."), // 提示文本
            ],
          ),
        ),
      );
    },
  );
}
