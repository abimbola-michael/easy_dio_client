import 'package:easy_dio_client/src/dio_client.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<UserModel> users = [];
  String log = "";

  Future<void> getTokens() async {
    final accessToken = await DioClient.getAccessTokenValue();
    final refreshToken = await DioClient.getRefreshTokenValue();
    final biometricToken = await DioClient.getBiometricTokenValue();
    final otherSecureStorageValue =
        await DioClient.getSecureStorageValue("user");
    setState(() {
      log =
          "Access Token: $accessToken\nRefresh Token: $refreshToken\nBiometric Token: $biometricToken\nOther Secure Storage Value: $otherSecureStorageValue";
    });
  }

  /// GET + convert
  Future<void> fetchUsers() async {
    final response = await DioClient().get<UserModel>(
      "/users",
      queryParameters: {"page": 1},
      dataKey: "data",
      convert: (json) => UserModel.fromJson(json),
    );

    if (response.success) {
      setState(() {
        users = response.datas ?? [];
        log = "Fetched users";
      });
    }
  }

  /// POST
  Future<void> createUser() async {
    final res = await DioClient().post(
      "/users",
      data: {"name": "John", "job": "Developer"},
    );
    setState(() => log = "POST: ${res.fullData}");
  }

  /// PUT
  Future<void> updateUser() async {
    final res = await DioClient().put("/users/2", data: {"name": "Updated"});
    setState(() => log = "PUT: ${res.fullData}");
  }

  /// PATCH
  Future<void> patchUser() async {
    final res = await DioClient().patch("/users/2", data: {"job": "Engineer"});
    setState(() => log = "PATCH: ${res.fullData}");
  }

  /// DELETE
  Future<void> deleteUser() async {
    final res = await DioClient().delete("/users/2");
    setState(() => log = "DELETE status: ${res.statusCode}");
  }

  /// Upload file
  Future<void> uploadFile() async {
    final res = await DioClient().uploadFile(
      "/upload",
      filePath: "/storage/emulated/0/Download/test.png",
    );
    setState(() => log = "UPLOAD: ${res.fullData}");
  }

  /// Download file
  Future<void> downloadFile() async {
    final res = await DioClient().downloadFile(
      "/storage/emulated/0/Download/file.pdf",
      "/files/1",
    );
    setState(() => log = "DOWNLOAD: ${res.success}");
  }

  Future<void> logout() async {
    await DioClient.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Easy Dio Cilent"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: fetchUsers, child: const Text("GET")),
              ElevatedButton(onPressed: createUser, child: const Text("POST")),
              ElevatedButton(onPressed: updateUser, child: const Text("PUT")),
              ElevatedButton(onPressed: patchUser, child: const Text("PATCH")),
              ElevatedButton(
                onPressed: deleteUser,
                child: const Text("DELETE"),
              ),
              ElevatedButton(
                onPressed: uploadFile,
                child: const Text("UPLOAD"),
              ),
              ElevatedButton(
                onPressed: downloadFile,
                child: const Text("DOWNLOAD"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(log),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final user = users[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                  title: Text("${user.firstName} ${user.lastName}"),
                  subtitle: Text(user.email),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
