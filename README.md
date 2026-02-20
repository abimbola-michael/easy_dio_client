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
  easy_dio_client: ^0.0.2
```

---

## ⚙️ Initialization

Call `DioClient.init()` once in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.init(
    baseUrl: "https://reqres.in/api",
    refreshTokenEndpoint: "/refresh",
    refreshTokenEndpointKey: "auth/refresh_token",
    tokenEndpoints: ["auth/signin"],
    accessTokenKey: "access_token",
    refreshTokenKey: "refresh_token",
    //if the exipriy time comes from the response and it should be in seconds by default
    //or specify isMillisecsExpiry to true if it's in milliseconds
    accessTokenExpiryKey: "access_token_expiry",
    refreshTokenExpiryKey: "refresh_token_expiry",
    //if the expiry time is not coming from the response, then specify it here
    accessTokenExpiry: 10 * 60,
    refreshTokenExpiry: 10 * 60,
    biometricsTokenExpiry: 100 * 60,
    //biometricsTokenExpiryKey: "biometrics_token_expiry",
    //any key that contains biometrics token data in case there's biometerics
    biometricsTokenKey: "biometrics_token",
    //any key that contains success boolean data
    successBooleanKeys: ["success"],
    //any key that contains message data
    messageKeys: ["message"],
    //any key that contains error data
    errorKeys: ["error"],
    //any other key you want to be stored in secure storage
    otherSecureStorageKeys: ["user"],
    //incase your response data is nested in a key
    dataKeys: ["data"],
    //any key that contains pagination data
    paginationKeys: ["pagination", "meta", "metadata"],
    // onModifyHeader: (headers) async {
    //in case you want your own authorizaton header or add some more things to the header
    //   headers["Authorization"] = "Bearer ${await DioClient.getAccessTokenValue()}";
    //   return headers;
    // },
    //onExtractPagination is used to extract pagination data from the response
    //after getting the pagination data using the pagination key
    onExtractPagination: (pagination) {
      debugPrint("Pagination: $pagination");
      return Pagination(
        total: pagination["total"],
        page: pagination["page"],
        limit: pagination["limit"],
        totalPage: pagination["total_page"],
        hasNextPage: pagination["has_next_page"],
        hasPreviousPage: pagination["has_previous_page"],
      );
    },
    onAuthFailure: () {
      debugPrint("Auth failed");
    },
    onGetRequest: (request) {
      debugPrint("Request: ${request.url}");
    },
    onGetResponse: (response) {
      debugPrint("Response: ${response?.data}");
    },
    onGetErrorResponse: (response) {
      debugPrint("Error Response: ${response?.data}");
    },
    onGetSuccessResponse: (response) {
      debugPrint("Success Response: ${response.data}");
    },
    onGetDioException: (e) {
      debugPrint("Dio Exception: $e");
    },
    onGetException: (e) {
      debugPrint("Exception: $e");
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

## 🔐 Get Tokens Example

```dart
final accessToken = await DioClient.getAccessTokenValue();
final refreshToken = await DioClient.getRefreshTokenValue();
final biometricToken = await DioClient.getBiometricTokenValue();
final otherSecureStorageValue = await DioClient.getSecureStorageValue("user");
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
  filePath: "/storage/emulated/0/Download/test.png",
  //filePaths: ["/storage/emulated/0/Download/test.png", "/storage/emulated/0/Download/test2.png"],
  //bytes: ...,
  //multiBytes: ....,
  fileKey: "file",
  fileName: "test.png",
);
```

---

## 📥 Download File

```dart
await DioClient().downloadFile(
  "/files/1",
  savePath: "/storage/emulated/0/Download/file.pdf",
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
