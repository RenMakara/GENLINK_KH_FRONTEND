/// Generic backend ApiResponse wrapper.
///
/// Every endpoint returns:
/// ```json
/// {
///   "success": true,
///   "message": "...",
///   "data": { ... },
///   "errorCode": null,
///   "timestamp": "2024-01-01T00:00:00Z"
/// }
/// ```
class ApiResponseModel<T> {
  const ApiResponseModel({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.timestamp,
  });

  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final String? timestamp;

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataFromJson,
  ) {
    return ApiResponseModel<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && dataFromJson != null
          ? dataFromJson(json['data'])
          : json['data'] as T?,
      errorCode: json['errorCode'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}
