# easy_dio_client

A simple and opinionated Dio wrapper for Flutter that provides:

- Unified API responses
- Automatic token refresh handling
- Secure token storage
- File upload & download helpers
- Pagination parsing
- Model conversion using `convert<T>()`
- Global request lifecycle hooks

Built on top of `dio`.

---

## ✨ Features

- GET, POST, PUT, PATCH, DELETE helpers
- File upload (path or bytes)
- File download
- Token refresh handling
- Automatic auth session management
- Pagination extraction
- Global request/response hooks
- Custom interceptors support

---

## 📦 Installation

```yaml
dependencies:
  easy_dio_client: ^0.0.1
```

---

## ⚙️ Initialization

Call `DioClient.init()` once in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.init(
    baseUrl: "https://api.example.com",
    refreshTokenEndpoint: "/auth/refresh",
    refreshTokenEndpointKey: "refresh_token",
    accessTokenKey: "access_token",
    refreshTokenKey: "refresh_token",
    accessTokenExpiryKey: "access_token_expiry",
    refreshTokenExpiryKey: "refresh_token_expiry",
    onAuthFailure: () {
      debugPrint("User logged out");
    },
  );

  runApp(const MyApp());
}
```

---

## 🚦 App Flow (Splash → Login → Home)

The example app follows this flow:

1. SplashScreen checks `isLoggedIn()`
2. If true → HomePage
3. If false → LoginPage

### Splash Screen Example

```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 5));
    final isLoggedIn = await DioClient.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomePage() : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text("Dio Client"),
        )),
    );
  }
}
```

---

## 🔐 Login Example

```dart
final response = await DioClient().post<Map<String, dynamic>>(
  "/login",
  data: {
    "email": "test@mail.com",
    "password": "123456",
  },
);
```

---

## 🚪 Logout

```dart
await DioClient.logout();
```

---

## 📡 Basic Requests

### GET + convert to model

```dart
final response = await DioClient().get<UserModel>(
  "/users",
  dataKey: "data",
  convert: (json) => UserModel.fromJson(json),
);

final users = response.datas;
```

### POST

```dart
await DioClient().post("/users", data: {"name": "John"});
```

### PUT

```dart
await DioClient().put("/users/2", data: {"name": "Updated"});
```

### PATCH

```dart
await DioClient().patch("/users/2", data: {"job": "Engineer"});
```

### DELETE

```dart
await DioClient().delete("/users/2");
```

---

## 📤 Upload File

```dart
await DioClient().uploadFile(
  "/upload",
  filePath: "/storage/emulated/0/Download/image.png",
);
```

---

## 📥 Download File

```dart
await DioClient().downloadFile(
  "/storage/emulated/0/Download/file.pdf",
  "/files/download",
);
```

---

## 📄 ApiResponse

```dart
ApiResponse<T> {
  bool success;
  bool skipped;
  String? message;
  String? error;
  int? statusCode;
  dynamic fullData;
  T? data;
  List<T>? datas;
  Pagination? pagination;
}
```

---

## 🧪 Example App

The example app demonstrates:

- Splash screen login check
- Login flow
- Session persistence using `isLoggedIn()`
- Logout handling
- GET, POST, PUT, PATCH, DELETE
- File upload & download
- JSON → Model mapping using `convert<T>()`

See `example/main.dart`.

---

## 📜 License

MIT
