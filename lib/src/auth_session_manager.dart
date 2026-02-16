import 'dart:async';

import 'package:easy_dio_client/src/dio_client.dart';
import 'package:easy_dio_client/src/map_extensions.dart';
import 'package:easy_dio_client/src/secure_storage.dart';
import 'package:flutter/material.dart';

class AuthSessionManager {
  AuthSessionManager._();
  static final AuthSessionManager instance = AuthSessionManager._();

  static Timer? _refreshTokenTimer, _biometricsTimer;

  static void init(
    Map<String, dynamic> data, {
    required String refreshTokenEndpoint,
    required String refreshTokenEndpointKey,
    String accessTokenKey = "access_token",
    String refreshTokenKey = "refresh_token",
    String? biometricsTokenKey,
    String? refreshTokenExpiryKey,
    String? accessTokenExpiryKey,
    String? biometricsTokenExpiryKey,
    int? refreshTokenExpiry,
    int? accessTokenExpiry,
    int? biometricsTokenExpiry,
    bool isMillisecsExpiry = false,
  }) async {
    String? accessToken = data.findValueByKey(accessTokenKey);
    String? refreshToken = data.findValueByKey(refreshTokenKey);
    String? biometricsToken = biometricsTokenKey == null
        ? null
        : data.findValueByKey(biometricsTokenKey);

    num? accessTokenExpiryValue = accessTokenExpiryKey == null
        ? null
        : data.findValueByKey(accessTokenExpiryKey);
    num? refreshTokenExpiryValue = refreshTokenExpiryKey == null
        ? null
        : data.findValueByKey(refreshTokenExpiryKey);
    num? biometricsTokenExpiryValue = biometricsTokenExpiryKey == null
        ? null
        : data.findValueByKey(biometricsTokenExpiryKey);

    if (accessTokenExpiryValue != null) {
      accessTokenExpiry = isMillisecsExpiry
          ? accessTokenExpiryValue.toInt()
          : accessTokenExpiryValue.toInt() * 1000;
      accessTokenExpiry = accessTokenExpiry - (60000 * 3);
    }

    if (refreshTokenExpiryValue != null) {
      refreshTokenExpiry = isMillisecsExpiry
          ? refreshTokenExpiryValue.toInt()
          : refreshTokenExpiryValue.toInt() * 1000;
      refreshTokenExpiry = refreshTokenExpiry - (60000 * 3);
    }

    if (biometricsTokenExpiryValue != null) {
      biometricsTokenExpiry = isMillisecsExpiry
          ? biometricsTokenExpiryValue.toInt()
          : biometricsTokenExpiryValue.toInt() * 1000;
      biometricsTokenExpiry = biometricsTokenExpiry - (60000 * 3);
    }

    if (accessToken != null) {
      await SecureStorage.set(accessTokenKey, accessToken);
    }
    if (refreshToken != null) {
      await SecureStorage.set(refreshTokenKey, refreshToken);
    }

    if (biometricsToken != null && biometricsTokenKey != null) {
      await SecureStorage.set(biometricsTokenKey, biometricsToken);
    }

    if (accessToken != null && accessTokenExpiry != null) {
      final accessTokenExpiryTime =
          DateTime.now().millisecondsSinceEpoch + accessTokenExpiry;
      if (accessTokenExpiryKey != null) {
        await SecureStorage.set(accessTokenExpiryKey, accessTokenExpiryTime);
      }

      _refreshTokenTimer?.cancel();
      _refreshTokenTimer = Timer(
        Duration(milliseconds: accessTokenExpiry - 300000),
        () async {
          debugPrint("Refreshing token...");
          DioClient.refreshToken();
        },
      );
    }

    if (refreshToken != null && refreshTokenExpiry != null) {
      final refreshTokenExpiryTime =
          DateTime.now().millisecondsSinceEpoch + refreshTokenExpiry;
      if (refreshTokenExpiryKey != null) {
        await SecureStorage.set(refreshTokenExpiryKey, refreshTokenExpiryTime);
      }
    }

    if (biometricsToken != null && biometricsTokenExpiry != null) {
      final biometricsExpiryTime =
          DateTime.now().millisecondsSinceEpoch + biometricsTokenExpiry;
      if (biometricsTokenExpiryKey != null) {
        await SecureStorage.set(biometricsTokenExpiryKey, biometricsExpiryTime);
      }
      _biometricsTimer?.cancel();
      _biometricsTimer = Timer(
        Duration(milliseconds: biometricsTokenExpiry - (60000 * 3)),
        () async {
          if (biometricsTokenKey != null) {
            SecureStorage.remove(biometricsTokenKey);
          }
        },
      );
    }
  }

  static void dispose() {
    _biometricsTimer?.cancel();
    _refreshTokenTimer?.cancel();
    _biometricsTimer = null;
    _refreshTokenTimer = null;
  }
}
