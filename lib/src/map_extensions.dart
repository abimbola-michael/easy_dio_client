import 'package:dio/dio.dart';

extension MapExtensions on Map<String, dynamic> {
  FormData get toFormData => FormData.fromMap(this);

  List<dynamic> findAllValuesByKey(List<String> targetKeys) {
    List output = [];
    for (int i = 0; i < targetKeys.length; i++) {
      final targetKey = targetKeys[i];
      final value = findValueByKey(targetKey);
      output.add(value);
    }
    return output;
  }

  dynamic findValuesByKey(List<String> targetKeys) {
    for (int i = 0; i < targetKeys.length; i++) {
      final targetKey = targetKeys[i];
      final value = findValueByKey(targetKey);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  dynamic findValueByKey(String targetKey) {
    Map<String, dynamic> map = this;
    if (map.containsKey(targetKey)) {
      return map[targetKey];
    }

    for (final entry in map.entries) {
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        final result = value.findValueByKey(targetKey);
        if (result != null) return result;
      }

      if (value is List<Object>) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final result = item.findValueByKey(targetKey);
            if (result != null) return result;
          }
        }
      }
    }

    return null;
  }
}
