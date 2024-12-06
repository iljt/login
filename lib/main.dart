import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'login_util.dart';

Future<void> main() async {
  // main函数中有await时，需要先调用此方法否则会有警告
  WidgetsFlutterBinding.ensureInitialized();
  // 集成firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoogleAndAppleLogin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GoogleAndAppleLogin'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                // 登录按钮点击事件
                print('Google login clcik');
                var user = LoginUtil.currentUser();
                if (user != null) {
                  print("user== $user");
                  await LoginUtil.signOut();
                }
                String? token = await LoginUtil.signInWithGoogle();
                print("token== $token");
              },
              child: const Text('Google登录'),
            ),
           const SizedBox(height: 16), // 按钮之间的间距
            ElevatedButton(
              onPressed: () {
                // 注册按钮点击事件
                print('Apple login clcik');
              },
              child: const Text('Apple登录'),
            ),
          ],
        ),
      ),
    );
  }
}
