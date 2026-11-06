class SkipOccurrenceResponse {
  final bool success;
  final String message;
  final String? occurrenceId;
  final String status;
  final Map<String, dynamic>? rawData;

  const SkipOccurrenceResponse({
    required this.success,
    required this.message,
    this.occurrenceId,
    this.status = 'SKIPPED',
    this.rawData,
  });

  factory SkipOccurrenceResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? true;
    final String message = json['message'] as String? ?? 'Occurrence skipped successfully';

    final data = json['data'] ?? json;
    String? occId;
    String stat = 'SKIPPED';

    if (data is Map<String, dynamic>) {
      occId = data['occurrenceId'] as String? ??
          data['_id'] as String? ??
          data['id'] as String?;
      stat = data['status'] as String? ?? 'SKIPPED';
    }

    return SkipOccurrenceResponse(
      success: success,
      message: message,
      occurrenceId: occId,
      status: stat,
      rawData: data is Map<String, dynamic> ? data : null,
    );
  }
}
