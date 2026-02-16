import 'dart:convert';

enum DataChangeType { added, removed, changed, moved }

class ApiResponse<T> {
  final bool success;
  final bool skipped;
  final String? message;
  final String? error;
  final int? statusCode;
  final dynamic fullData;
  final T? data;
  final List<T>? datas;
  final Pagination? pagination;
  final List<DataChangeType>? dataChangeTypes;

  ApiResponse({
    this.success = false,
    this.skipped = false,
    this.message,
    this.error,
    this.statusCode,
    this.data,
    this.pagination,
    this.fullData,
    this.datas,
    this.dataChangeTypes,
  });

  ApiResponse<T> copyWith({
    bool? success,
    bool? skipped,
    String? message,
    String? error,
    int? statusCode,
    dynamic fullData,
    T? data,
    List<T>? datas,
    Pagination? pagination,
    List<DataChangeType>? dataChangeTypes,
  }) {
    return ApiResponse(
      data: data ?? this.data,
      success: success ?? this.success,
      message: message ?? this.message,
      error: error ?? this.error,
      statusCode: statusCode ?? this.statusCode,
      pagination: pagination ?? this.pagination,
      fullData: fullData ?? this.fullData,
      skipped: skipped ?? this.skipped,
      datas: datas ?? this.datas,
      dataChangeTypes: dataChangeTypes ?? this.dataChangeTypes,
    );
  }

  ApiResponse<R> to<R>(R Function(T? data)? convert) {
    return ApiResponse<R>(
      data: convert == null || data == null
          ? null
          : data is List
          ? null
          : convert(data),
      datas: convert == null || datas == null
          ? null
          : datas?.map((data) => convert(data)).toList(),
      success: success,
      message: message,
      error: error,
      statusCode: statusCode,
      pagination: pagination,
      fullData: fullData,
      skipped: skipped,
      dataChangeTypes: dataChangeTypes,
    );
  }
}

class Pagination {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final Object? first;
  final Object? last;
  final Object? start;
  final Object? end;

  const Pagination({
    this.total,
    this.page,
    this.limit,
    this.totalPage,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.first,
    this.last,
    this.start,
    this.end,
  });

  factory Pagination.fromJson(String source) {
    return Pagination.fromMap(json.decode(source));
  }

  String toJson() {
    return json.encode(toMap());
  }

  Map<String, dynamic> get asMap => toMap();

  @override
  String toString() {
    return '''Pagination(total: $total, page: $page, limit: $limit, totalPage: $totalPage, hasNextPage: $hasNextPage, hasPreviousPage: $hasPreviousPage, first: $first, last: $last, start: $start, end: $end)''';
  }

  Pagination copyWith({
    int? total,
    int? page,
    int? limit,
    int? totalPage,
    bool? hasNextPage,
    bool? hasPreviousPage,
    Object? first,
    Object? last,
    Object? start,
    Object? end,
  }) {
    return Pagination(
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPage: totalPage ?? this.totalPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      first: first ?? this.first,
      last: last ?? this.last,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Pagination &&
        other.total == total &&
        other.page == page &&
        other.limit == limit &&
        other.totalPage == totalPage &&
        other.hasNextPage == hasNextPage &&
        other.hasPreviousPage == hasPreviousPage &&
        other.first == first &&
        other.last == last &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode {
    return total.hashCode ^
        page.hashCode ^
        limit.hashCode ^
        totalPage.hashCode ^
        hasNextPage.hashCode ^
        hasPreviousPage.hashCode ^
        first.hashCode ^
        last.hashCode ^
        start.hashCode ^
        end.hashCode;
  }

  factory Pagination.fromMap(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      totalPage: json['total_page'],
      hasNextPage: json['has_next_page'],
      hasPreviousPage: json['has_previous_page'],
      first: json['first'],
      last: json['last'],
      start: json['start'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'total_page': totalPage,
      'has_next_page': hasNextPage,
      'has_previous_page': hasPreviousPage,
      'first': first,
      'last': last,
      'start': start,
      'end': end,
    };
  }
}

extension ApiResponseExtentions on ApiResponse {
  ApiResponse<T> fromMap<T>(T Function(Map<String, dynamic> map)? convert) {
    return ApiResponse<T>(
      data: data == null
          ? null
          : convert == null
          ? data as T
          : data is List
          ? null
          : data is Map<String, dynamic>
          ? convert(data)
          : null,
      datas: datas == null
          ? null
          : convert == null
          ? datas as List<T>
          : datas?.firstOrNull is! Map<String, dynamic>
          ? null
          : datas?.map((data) => convert(data)).toList(),
      success: success,
      message: message,
      error: error,
      statusCode: statusCode,
      pagination: pagination,
      fullData: fullData,
      skipped: skipped,
    );
  }
}
