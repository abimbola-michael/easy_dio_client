import 'package:easy_dio_client/easy_dio_client.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;
  String message = "";
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> login() async {
    setState(() => loading = true);

    final response = await DioClient().post<Map<String, dynamic>>(
      "/login",
      data: {
        "email": emailController.text,
        "password": passwordController.text,
      },
    );

    if (response.success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => message = response.error ?? "Login failed");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 20,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(hintText: "Email"),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: const Text("Login"),
            ),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}
