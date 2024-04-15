import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// 引入其他必要的库，例如用于Apple登录的库

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 电子邮箱注册
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(); // 发送验证邮件
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Firebase Auth错误处理
      if (e.code == 'weak-password') {
        throw '密码太简单。';
      } else if (e.code == "ERROR_EMAIL_ALREADY_IN_USE") {
        throw '电子邮箱已经被注册。';
      } else if (e.code == "ERROR_INVALID_EMAIL") {
        throw '电子邮箱格式无效。';
      } else {
        throw '注册失败，请稍后重试。';
      }
    } catch (e) {
      // 其他错误处理
      throw '发生未知错误，请稍后重试。';
    }
  }

  // 电子邮箱登录
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Firebase Auth错误处理
      if (e.code == 'user-not-found') {
        throw '用户不存在。';
      } else if (e.code == 'wrong-password') {
        throw '密码错误。';
      } else if (e.code == 'invalid-email') {
        throw '电子邮箱格式无效。';
      } else {
        throw '登录失败，请稍后重试。';
      }
    } catch (e) {
      // 其他错误处理
      throw '发生未知错误，请稍后重试。';
    }
  }

  // Google登录
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // 处理错误
      throw 'Google登录失败，请稍后重试。';
    }
  }

  /* Apple登录（需添加相应的依赖和配置）
  Future<User?> signInWithApple() async {
    // 实现Apple登录逻辑
    // 错误处理
  }*/

  // 登出
  Future<void> signOut() async {
    User? currentUser = _firebaseAuth.currentUser;

    // 检查是否使用Google账号登录
    var isGoogleUser = currentUser?.providerData.any((profile) => profile.providerId == 'google.com') ?? false;
    if (isGoogleUser) {
      await GoogleSignIn().signOut(); // Google账号登出
    }

    await _firebaseAuth.signOut(); // Firebase登出
}

}
