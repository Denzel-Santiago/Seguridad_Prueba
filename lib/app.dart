import 'package:flutter/material.dart';
import 'login.dart';
import 'shared/theme/theme.dart';
import 'shared/theme/util.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme(context, "Roboto", "Roboto");
    final theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: theme.light(),
      darkTheme: theme.dark(),
      home: const LoginScreen(),
    );
  }
}
