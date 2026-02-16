import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_dio_client/src/api_response.dart';
import 'package:easy_dio_client/src/auth_session_manager.dart';
import 'package:easy_dio_client/src/map_extensions.dart';
import 'package:easy_dio_client/src/secure_storage.dart';
import 'package:flutter/material.dart';

import 'package:http_parser/http_parser.dart';

class DioClient {
  // Dio instance
  final Dio _dio = Dio();

  // Callback for handling authentication failures
  static void Function()? _onAuthFailure;

  static void Function(Request request)? _onGetRequest;
  static void Function(Response? response)? _onGetResponse;
  static void Function(Response response)? _onGetSuccessResponse;
  static void Function(Response? response)? _onGetErrorResponse;
  static void Function(Exception exception)? _onGetException;
  static void Function(DioException exception)? _onGetDioException;

  static String _baseUrl = "";

  // receiveTimeout
  static Duration _receiveTimeout = Duration(milliseconds: 60000);
  // connectTimeout
  static Duration _connectionTimeout = Duration(milliseconds: 60000);

  static ResponseType _responseType = ResponseType.json;

  static String _refreshTokenEndpoint = "";
  static String _refreshTokenEndpointKey = "refresh_token";

  static String _accessTokenKey = "access_token";
  static String _refreshTokenKey = "refresh_token";
  static String? _biometricsTokenKey;

  static String? _refreshTokenExpiryKey;
  static String? _accessTokenExpiryKey;
  static String? _biometricsTokenExpiryKey;

  static String get refreshTokenEndpointKey => _refreshTokenEndpointKey;
  static String get accessTokenKey => _accessTokenKey;

  static String get refreshTokenEndpoint => _refreshTokenEndpoint;
  static String get refreshTokenKey => _refreshTokenKey;
  static String? get biometricsTokenKey => _biometricsTokenKey;

  static String? get refreshTokenExpiryKey => _refreshTokenExpiryKey;
  static String? get accessTokenExpiryKey => _accessTokenExpiryKey;
  static String? get biometricsTokenExpiryKey => _biometricsTokenExpiryKey;

  static int? _refreshTokenExpiry;
  static int? _accessTokenExpiry;
  static int? _biometricsTokenExpiry;
  static bool _isMillisecsExpiry = false;

  static List<String> _otherSecureStorageKeys = [];

  static List<String> _paginationKeys = [];
  static List<String> _dataKeys = [];
  static List<String> _errorKeys = [];
  static List<String> _messageKeys = [];
  static List<String> _successBooleanKeys = [];
  static Pagination Function(Map<String, dynamic> pagination)? _onGetPagination;
  static Future Function(Map<String, dynamic> headers)? _onModifyHeader;
  static Interceptors? _interceptors;
  Set<String> currentRequests = {};
  static int refreshTokenRetryCount = 5;
  static int currentRefreshTokenRetryCount = 0;

  static void init({
    required String baseUrl,
    required String refreshTokenEndpoint,
    Duration receiveTimeout = const Duration(milliseconds: 60000),
    Duration connectionTimeout = const Duration(milliseconds: 60000),
    ResponseType responseType = ResponseType.json,
    required String refreshTokenEndpointKey,
    required String accessTokenKey,
    required String refreshTokenKey,
    String? biometricsTokenKey,
    String? refreshTokenExpiryKey,
    String? accessTokenExpiryKey,
    String? biometricsTokenExpiryKey,
    int? refreshTokenExpiry,
    int? accessTokenExpiry,
    int? biometricsTokenExpiry,
    bool isMillisecsExpiry = false,
    List<String> otherSecureStorageKeys = const ["user"],
    List<String> paginationKeys = const ["pagination"],
    List<String> dataKeys = const ["data"],
    List<String> errorKeys = const ["error"],
    List<String> messageKeys = const ["message"],
    List<String> successBooleanKeys = const ["success"],
    Pagination Function(Map<String, dynamic> pagination)? onGetPagination,
    Future Function(Map<String, dynamic> headers)? onModifyHeader,
    void Function()? onAuthFailure,
    void Function(Request request)? onGetRequest,
    void Function(Response? response)? onGetResponse,
    void Function(Response response)? onGetSuccessResponse,
    void Function(Response? response)? onGetErrorResponse,
    void Function(Exception exception)? onGetException,
    void Function(DioException exception)? onGetDioException,
    Interceptors? interceptors,
  }) {
    _baseUrl = baseUrl;
    _receiveTimeout = receiveTimeout;
    _connectionTimeout = connectionTimeout;
    _refreshTokenEndpoint = refreshTokenEndpoint;
    _refreshTokenEndpointKey = refreshTokenEndpointKey;
    _accessTokenKey = accessTokenKey;
    _refreshTokenKey = refreshTokenKey;
    _biometricsTokenKey = biometricsTokenKey;
    _refreshTokenExpiryKey = refreshTokenExpiryKey;
    _accessTokenExpiryKey = accessTokenExpiryKey;
    _biometricsTokenExpiryKey = biometricsTokenExpiryKey;
    _refreshTokenExpiry = refreshTokenExpiry;
    _accessTokenExpiry = accessTokenExpiry;
    _biometricsTokenExpiry = biometricsTokenExpiry;
    _isMillisecsExpiry = isMillisecsExpiry;
    _otherSecureStorageKeys = otherSecureStorageKeys;
    _paginationKeys = paginationKeys;
    _dataKeys = dataKeys;
    _errorKeys = errorKeys;
    _messageKeys = messageKeys;
    _successBooleanKeys = successBooleanKeys;
    _onGetPagination = onGetPagination;
    _onModifyHeader = onModifyHeader;
    _onAuthFailure = onAuthFailure;
    _onGetRequest = onGetRequest;
    _onGetResponse = onGetResponse;
    _onGetSuccessResponse = onGetSuccessResponse;
    _onGetErrorResponse = onGetErrorResponse;
    _onGetException = onGetException;
    _onGetDioException = onGetDioException;
    _responseType = responseType;
    _interceptors = interceptors;
  }

  static Future<bool> isLoggedIn() async {
    final token = await SecureStorage.get(accessTokenKey);
    return token != null;
  }

  static Future<void> logout() async {
    AuthSessionManager.dispose();
    await SecureStorage.remove(accessTokenKey);
    await SecureStorage.remove(refreshTokenKey);
    if (biometricsTokenKey != null) {
      await SecureStorage.remove(biometricsTokenKey!);
    }
    if (accessTokenExpiryKey != null) {
      await SecureStorage.remove(accessTokenExpiryKey!);
    }
    if (refreshTokenExpiryKey != null) {
      await SecureStorage.remove(refreshTokenExpiryKey!);
    }
    if (biometricsTokenExpiryKey != null) {
      await SecureStorage.remove(biometricsTokenExpiryKey!);
    }
  }

  static Future<void> refreshToken() async {
    final refreshToken = await SecureStorage.get(refreshTokenKey);

    try {
      await DioClient().post(
        refreshTokenEndpoint,
        data: {refreshTokenEndpointKey: refreshToken},
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response?.statusCode == 401) {
        debugPrint("⚠️ Auth failed. UnAuthorized");

        DioClient.logout();

        _onAuthFailure?.call();
      } else {
        final isNetwork =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;

        if (!isNetwork) return;
        if (currentRefreshTokenRetryCount >= refreshTokenRetryCount) {
          currentRefreshTokenRetryCount = 0;
          return;
        }
        Future.delayed(const Duration(seconds: 3)).then((_) {
          currentRefreshTokenRetryCount++;
          DioClient.refreshToken();
        });
      }
    }
  }

  DioClient() {
    _dio
      ..options.baseUrl = _baseUrl
      ..options.connectTimeout = _connectionTimeout
      ..options.receiveTimeout = _receiveTimeout
      ..options.responseType = _responseType
      ..options.followRedirects = true
      ..options.maxRedirects = 5
      // ..interceptors.add(CookieManager(_cookieJar)) // Add Cookie Manager
      // ..interceptors.add(_createAuthInterceptor())
      ..interceptors.addAll([
        LogInterceptor(requestBody: true),
        if (_interceptors != null) ..._interceptors!,
      ]);
  }

  // Helper method to merge options
  Options _mergeOptions(Options? options, String method) {
    final baseOptions = Options(method: method, headers: {}, extra: {});

    if (options != null) {
      baseOptions.headers?.addAll(options.headers ?? {});
      baseOptions.extra?.addAll(options.extra ?? {});
      // Copy other relevant options properties
      baseOptions.responseType = options.responseType;
      baseOptions.contentType = options.contentType;
      baseOptions.validateStatus = options.validateStatus;
      baseOptions.receiveTimeout = options.receiveTimeout;
      baseOptions.sendTimeout = options.sendTimeout;
    }

    return baseOptions;
  }

  // Generic Request Sender
  Future<ApiResponse<T>> _sendRequest<T>(
    String url, {
    required String method,
    dynamic data,
    String? savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic>)? convert,
  }) async {
    try {
      // Determine content type based on data type
      String? contentType;
      if (data != null) {
        if (data is FormData) {
          contentType = 'multipart/form-data';
        } else if (data is Map) {
          contentType = 'application/json';
        } else if (data is String) {
          contentType = 'text/plain';
        } else {
          contentType = 'application/json';
        }
      }

      final mergedOptions = _mergeOptions(
        options ??
            (contentType != null
                ? Options(headers: {'Content-Type': contentType})
                : null),
        method,
      );

      if (_onModifyHeader != null) {
        await _onModifyHeader!(mergedOptions.headers!);
        mergedOptions.headers!['Content-Type'] ??= 'application/json';
        mergedOptions.headers!['Accept'] ??= 'application/json';
        // if (url != AppEndpoints.refreshToken) {
        if (mergedOptions.headers!['Authorization'] == null) {
          var accessToken = await SecureStorage.get(_accessTokenKey);

          if (accessToken != null) {
            mergedOptions.headers!['Authorization'] = 'Bearer $accessToken';
          }
        }
      } else {
        mergedOptions.headers!['Content-Type'] = 'application/json';
        mergedOptions.headers!['Accept'] = 'application/json';
        // if (url != AppEndpoints.refreshToken) {
        var accessToken = await SecureStorage.get(_accessTokenKey);

        if (accessToken != null) {
          mergedOptions.headers!['Authorization'] = 'Bearer $accessToken';
        }
      }

      // }
      if (currentRequests.contains(url)) {
        return ApiResponse(skipped: true);
      }
      currentRequests.add(url);

      final request = Request(
        url: url,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
      _onGetRequest?.call(request);

      final response = savePath != null
          ? await _dio.download(
              url,
              savePath,
              data: data,
              queryParameters: queryParameters,
              options: mergedOptions,
              cancelToken: cancelToken,
              onReceiveProgress: onReceiveProgress,
            )
          : await _dio.request(
              url,
              data: data,
              queryParameters: queryParameters,
              options: mergedOptions,
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
              onReceiveProgress: onReceiveProgress,
            );
      _onGetResponse?.call(response);
      _onGetSuccessResponse?.call(response);

      currentRequests.remove(url);

      final pagination =
          response.data != null &&
              response.data is Map<String, dynamic> &&
              _paginationKeys.isNotEmpty
          ? (response.data as Map<String, dynamic>).findValuesByKey(
              _paginationKeys,
            )
          : null;

      if (response.data != null) {
        AuthSessionManager.init(
          response.data,
          refreshTokenEndpoint: _refreshTokenEndpoint,
          refreshTokenEndpointKey: _refreshTokenEndpointKey,
          accessTokenKey: _accessTokenKey,
          refreshTokenKey: _refreshTokenKey,
          biometricsTokenKey: _biometricsTokenKey,
          refreshTokenExpiryKey: _refreshTokenExpiryKey,
          accessTokenExpiryKey: _accessTokenExpiryKey,
          biometricsTokenExpiryKey: _biometricsTokenExpiryKey,
          refreshTokenExpiry: _refreshTokenExpiry,
          accessTokenExpiry: _accessTokenExpiry,
          biometricsTokenExpiry: _biometricsTokenExpiry,
          isMillisecsExpiry: _isMillisecsExpiry,
        );
      }
      var responseData =
          response.data != null &&
              response.data is Map<String, dynamic> &&
              _dataKeys.isNotEmpty
          ? (response.data as Map<String, dynamic>).findValuesByKey(_dataKeys)
          : response.data;

      if (response.data != null &&
          response.data is Map<String, dynamic> &&
          _otherSecureStorageKeys.isNotEmpty) {
        final storagesDatas = (response.data as Map<String, dynamic>)
            .findAllValuesByKey(_otherSecureStorageKeys);
        for (int i = 0; i < _otherSecureStorageKeys.length; i++) {
          final key = _otherSecureStorageKeys[i];
          final value = storagesDatas[i];
          if (value != null) {
            await SecureStorage.set(key, value);
          }
        }
      }

      final message =
          response.data != null &&
              response.data is Map<String, dynamic> &&
              _messageKeys.isNotEmpty
          ? (response.data as Map<String, dynamic>).findValuesByKey(
              _messageKeys,
            )
          : null;

      final error =
          response.data != null &&
              response.data is Map<String, dynamic> &&
              _errorKeys.isNotEmpty
          ? (response.data as Map<String, dynamic>).findValuesByKey(_errorKeys)
          : null;

      final success =
          response.data != null &&
              response.data is Map<String, dynamic> &&
              _successBooleanKeys.isNotEmpty
          ? (response.data as Map<String, dynamic>).findValuesByKey(
              _successBooleanKeys,
            )
          : null;

      if (responseData != null &&
          responseData is Map<String, dynamic> &&
          dataKey != null) {
        responseData = responseData[dataKey];
      }

      return ApiResponse(
        success: success ?? true,
        data: responseData != null && responseData is List
            ? null
            : convert != null
            ? convert(responseData)
            : responseData as T,
        datas: responseData != null && responseData is List
            ? convert != null
                  ? responseData.map((snapshot) => convert(data)!).toList()
                  : responseData as List<T>
            : null,
        message: message == null
            ? null
            : message is String
            ? message
            : message is List<dynamic>
            ? message.join("\n")
            : message.toString(),

        error: error == null
            ? null
            : error is String
            ? error
            : error is List<dynamic>
            ? error.join("\n")
            : error.toString(),

        statusCode: response.statusCode,
        pagination: pagination != null
            ? _onGetPagination != null
                  ? _onGetPagination!(pagination)
                  : Pagination.fromMap(pagination)
            : null,
        fullData: response.data,
      );
    } on DioException catch (e) {
      _onGetResponse?.call(e.response);
      _onGetErrorResponse?.call(e.response);
      _onGetException?.call(e);
      _onGetDioException?.call(e);

      final response = e.response;
      if (response?.statusCode == 401) {
        refreshToken();
      }

      if (response?.data != null) {
        if (response?.data is Map<String, dynamic>) {
          final message =
              response!.data != null &&
                  response.data is Map<String, dynamic> &&
                  _messageKeys.isNotEmpty
              ? (response.data as Map<String, dynamic>).findValuesByKey(
                  _messageKeys,
                )
              : null;

          final error =
              response.data != null &&
                  response.data is Map<String, dynamic> &&
                  _errorKeys.isNotEmpty
              ? (response.data as Map<String, dynamic>).findValuesByKey(
                  _errorKeys,
                )
              : null;

          return ApiResponse<T>(
            success: false,
            message: message == null
                ? null
                : message is String
                ? message
                : message is List<dynamic>
                ? message.join("\n")
                : message.toString(),

            // data:dataKey != null? response?.data[dataKey]:,
            data: response.data,
            error: error == null
                ? null
                : error is String
                ? error
                : error is List<dynamic>
                ? error.join("\n")
                : error.toString(),
            statusCode: response.statusCode,
            fullData: response.data,
          );
        } else {
          return ApiResponse<T>(
            success: false,
            message: response?.data,
            data: null,
            error: response?.data,
            statusCode: response?.statusCode,
            fullData: response?.data,
          );
        }
      }

      return ApiResponse<T>(
        success: false,
        message: e.message?.toString(),
        data: null,
      );
    } on SocketException catch (e) {
      _onGetException?.call(e);

      return ApiResponse<T>(success: false, message: e.toString(), data: null);
    } on Exception catch (e) {
      _onGetException?.call(e);
      return ApiResponse<T>(success: false, message: e.toString(), data: null);
    }
  }

  // GET Request
  Future<ApiResponse<T>> get<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      method: 'GET',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // POST Request
  Future<ApiResponse<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // PUT Request
  Future<ApiResponse<T>> put<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // PATCH Request
  Future<ApiResponse<T>> patch<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // Upload File
  Future<ApiResponse<T>> uploadFile<T>(
    String url, {
    String fileKey = "file",
    MediaType? contentType,
    String? fileName,
    String? filePath,
    List<String>? fileNames,
    List<String>? filePaths,
    Uint8List? bytes,
    List<Uint8List>? multiBytes,
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    FormData? formData;
    if (filePaths != null) {
      final timeNow = DateTime.now().millisecondsSinceEpoch.toString();
      final files = await Future.wait(
        List.generate(filePaths.length, (index) {
          final filePath = filePaths[index];
          final fileName = fileNames == null
              ? filePath.split('/').lastOrNull ?? timeNow
              : fileNames[index];
          return MultipartFile.fromFile(
            filePath,
            filename: fileName,
            contentType: _getMediaType(filePath),
          );
        }),
      );
      formData = FormData.fromMap({fileKey: files, if (data != null) ...data});
    } else if (filePath != null) {
      final timeNow = DateTime.now().millisecondsSinceEpoch.toString();
      fileName ??= filePath.split('/').lastOrNull ?? timeNow;
      final file = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: _getMediaType(filePath),
      );
      formData = FormData.fromMap({fileKey: file, if (data != null) ...data});
    } else if (multiBytes != null) {
      final timeNow = DateTime.now().millisecondsSinceEpoch.toString();
      final files = List.generate(multiBytes.length, (index) {
        final bytes = multiBytes[index];
        final fileName = fileNames?[index] ?? timeNow;
        return MultipartFile.fromBytes(bytes, filename: fileName);
      });
      formData = FormData.fromMap({fileKey: files, if (data != null) ...data});
    } else if (bytes != null) {
      final timeNow = DateTime.now().millisecondsSinceEpoch.toString();
      fileName ??= fileName ?? timeNow;
      final file = MultipartFile.fromBytes(bytes, filename: fileName);
      formData = FormData.fromMap({fileKey: file, if (data != null) ...data});
    }
    if (formData == null) {
      return ApiResponse(
        success: false,
        skipped: true,
        error: "No File to upload",
      );
    }

    final uploadOptions = _mergeOptions(
      options ?? Options(headers: {"Content-Type": "multipart/form-data"}),
      'POST',
    );

    return _sendRequest(
      url,
      method: 'POST',
      data: formData,
      options: uploadOptions,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }

  // Upload File
  Future<ApiResponse<T>> downloadFile<T>(
    String savePath,
    String url, {
    String fileKey = "file",
    String? fileName,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? dataKey,
    T? Function(Map<String, dynamic> data)? convert,
  }) async {
    return _sendRequest(
      url,
      savePath: savePath,
      method: '',
      data: data,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      dataKey: dataKey,
      convert: convert,
    );
  }
}

MediaType _getMediaType(String filePath) {
  String fileType = filePath.split('.').last.toLowerCase();

  switch (fileType) {
    case 'jpg':
    case 'jpeg':
      return MediaType('image', 'jpeg');
    case 'png':
      return MediaType('image', 'png');
    case 'gif':
      return MediaType('image', 'gif');
    case 'mp4':
      return MediaType('video', 'mp4');
    case 'mov':
      return MediaType('video', 'quicktime');
    case 'pdf':
      return MediaType('application', 'pdf');
    case 'doc':
    case 'docx':
      return MediaType('application', 'msword');
    case 'txt':
      return MediaType('text', 'plain');
    default:
      return MediaType('application', 'octet-stream');
  }
}

class Request {
  final String url;
  final Object? data;
  final Map<String, dynamic>? queryParameters;
  final CancelToken? cancelToken;
  final Options? options;

  const Request({
    required this.url,
    this.data,
    this.queryParameters,
    this.cancelToken,
    this.options,
  });
}
