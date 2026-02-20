import 'package:flutter/material.dart';
import 'package:easy_dio_client/easy_dio_client.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.init(
    baseUrl: "https://reqres.in/api/",
    refreshTokenEndpoint: "auth/refresh",
    refreshTokenEndpointKey: "refresh_token",
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const SplashScreen());
  }
}
