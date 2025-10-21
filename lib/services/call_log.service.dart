import 'dart:convert';
import 'package:fuodz/services/local_storage.service.dart';

enum CallLogType {
  incoming,
  outgoing,
  missed,
}

enum CallLogStatus {
  completed,
  rejected,
  timeout,
  failed,
  cancelled,
}

class CallLogEntry {
  final String sessionId;
  final String orderId;
  final String contactName;
  final String contactType; // 'customer' or 'driver'
  final CallLogType type;
  final CallLogStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  CallLogEntry({
    required this.sessionId,
    required this.orderId,
    required this.contactName,
    required this.contactType,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    this.failureReason,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'orderId': orderId,
      'contactName': contactName,
      'contactType': contactType,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      sessionId: json['sessionId'],
      orderId: json['orderId'],
      contactName: json['contactName'],
      contactType: json['contactType'],
      type: CallLogType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      status: CallLogStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'],
      failureReason: json['failureReason'],
      metadata: json['metadata'],
    );
  }

  String get formattedDuration {
    if (duration == null) return 'N/A';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get statusDisplayText {
    switch (status) {
      case CallLogStatus.completed:
        return 'Completed';
      case CallLogStatus.rejected:
        return 'Rejected';
      case CallLogStatus.timeout:
        return 'No Answer';
      case CallLogStatus.failed:
        return 'Failed';
      case CallLogStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case CallLogType.incoming:
        return 'Incoming';
      case CallLogType.outgoing:
        return 'Outgoing';
      case CallLogType.missed:
        return 'Missed';
    }
  }
}

class CallLogService {
  static const String _callLogKey = 'video_call_logs';
  static const int _maxLogEntries = 100; // Keep last 100 calls

  /// Log a video call
  static Future<void> logCall(CallLogEntry entry) async {
    try {
      final logs = await getCallLogs();
      logs.insert(0, entry); // Add to beginning (most recent first)

      // Keep only the last _maxLogEntries
      if (logs.length > _maxLogEntries) {
        logs.removeRange(_maxLogEntries, logs.length);
      }

      await _saveCallLogs(logs);
      print('CallLog: Logged call - ${entry.sessionId} (${entry.status})');
    } catch (e) {
      print('CallLog: Error logging call: $e');
    }
  }

  /// Get all call logs
  static Future<List<CallLogEntry>> getCallLogs() async {
    try {
      final logsJson = LocalStorageService.prefs!.getString(_callLogKey);
      if (logsJson == null) return [];

      final List<dynamic> logsList = jsonDecode(logsJson);
      return logsList.map((json) => CallLogEntry.fromJson(json)).toList();
    } catch (e) {
      print('CallLog: Error getting call logs: $e');
      return [];
    }
  }

  /// Get call logs for a specific order
  static Future<List<CallLogEntry>> getCallLogsForOrder(String orderId) async {
    final allLogs = await getCallLogs();
    return allLogs.where((log) => log.orderId == orderId).toList();
  }

  /// Get call logs by status
  static Future<List<CallLogEntry>> getCallLogsByStatus(CallLogStatus status) async {
    final allLogs = await getCallLogs();
    return allLogs.where((log) => log.status == status).toList();
  }

  /// Get call logs by type
  static Future<List<CallLogEntry>> getCallLogsByType(CallLogType type) async {
    final allLogs = await getCallLogs();
    return allLogs.where((log) => log.type == type).toList();
  }

  /// Get missed calls count
  static Future<int> getMissedCallsCount() async {
    final missedCalls = await getCallLogsByStatus(CallLogStatus.timeout);
    return missedCalls.length;
  }

  /// Clear all call logs
  static Future<void> clearCallLogs() async {
    try {
      await LocalStorageService.prefs!.remove(_callLogKey);
      print('CallLog: All call logs cleared');
    } catch (e) {
      print('CallLog: Error clearing call logs: $e');
    }
  }

  /// Update an existing call log entry
  static Future<void> updateCallLog(String sessionId, {
    CallLogStatus? status,
    DateTime? endTime,
    int? duration,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logs = await getCallLogs();
      final index = logs.indexWhere((log) => log.sessionId == sessionId);
      
      if (index != -1) {
        final existingLog = logs[index];
        final updatedLog = CallLogEntry(
          sessionId: existingLog.sessionId,
          orderId: existingLog.orderId,
          contactName: existingLog.contactName,
          contactType: existingLog.contactType,
          type: existingLog.type,
          status: status ?? existingLog.status,
          startTime: existingLog.startTime,
          endTime: endTime ?? existingLog.endTime,
          duration: duration ?? existingLog.duration,
          failureReason: failureReason ?? existingLog.failureReason,
          metadata: metadata ?? existingLog.metadata,
        );

        logs[index] = updatedLog;
        await _saveCallLogs(logs);
        print('CallLog: Updated call log - $sessionId');
      }
    } catch (e) {
      print('CallLog: Error updating call log: $e');
    }
  }

  /// Get call statistics
  static Future<Map<String, dynamic>> getCallStatistics() async {
    final logs = await getCallLogs();
    
    final totalCalls = logs.length;
    final completedCalls = logs.where((log) => log.status == CallLogStatus.completed).length;
    final missedCalls = logs.where((log) => log.status == CallLogStatus.timeout).length;
    final rejectedCalls = logs.where((log) => log.status == CallLogStatus.rejected).length;
    final failedCalls = logs.where((log) => log.status == CallLogStatus.failed).length;
    
    final totalDuration = logs
        .where((log) => log.duration != null)
        .fold<int>(0, (sum, log) => sum + log.duration!);
    
    final averageDuration = completedCalls > 0 ? totalDuration / completedCalls : 0.0;

    return {
      'totalCalls': totalCalls,
      'completedCalls': completedCalls,
      'missedCalls': missedCalls,
      'rejectedCalls': rejectedCalls,
      'failedCalls': failedCalls,
      'totalDuration': totalDuration,
      'averageDuration': averageDuration,
      'successRate': totalCalls > 0 ? (completedCalls / totalCalls * 100) : 0.0,
    };
  }

  /// Save call logs to local storage
  static Future<void> _saveCallLogs(List<CallLogEntry> logs) async {
    try {
      final logsJson = jsonEncode(logs.map((log) => log.toJson()).toList());
      await LocalStorageService.prefs!.setString(_callLogKey, logsJson);
    } catch (e) {
      print('CallLog: Error saving call logs: $e');
    }
  }

  /// Log call initiation
  static Future<void> logCallInitiated({
    required String sessionId,
    required String orderId,
    required String contactName,
    required String contactType,
    required bool isOutgoing,
  }) async {
    final entry = CallLogEntry(
      sessionId: sessionId,
      orderId: orderId,
      contactName: contactName,
      contactType: contactType,
      type: isOutgoing ? CallLogType.outgoing : CallLogType.incoming,
      status: CallLogStatus.failed, // Will be updated when call completes
      startTime: DateTime.now(),
    );
    
    await logCall(entry);
  }

  /// Log call completion
  static Future<void> logCallCompleted({
    required String sessionId,
    required DateTime endTime,
    required int duration,
  }) async {
    await updateCallLog(
      sessionId,
      status: CallLogStatus.completed,
      endTime: endTime,
      duration: duration,
    );
  }

  /// Log call rejection
  static Future<void> logCallRejected(String sessionId) async {
    await updateCallLog(
      sessionId,
      status: CallLogStatus.rejected,
      endTime: DateTime.now(),
    );
  }

  /// Log call timeout
  static Future<void> logCallTimeout(String sessionId) async {
    await updateCallLog(
      sessionId,
      status: CallLogStatus.timeout,
      endTime: DateTime.now(),
    );
  }

  /// Log call failure
  static Future<void> logCallFailed(String sessionId, String reason) async {
    await updateCallLog(
      sessionId,
      status: CallLogStatus.failed,
      endTime: DateTime.now(),
      failureReason: reason,
    );
  }

  /// Log call cancellation
  static Future<void> logCallCancelled(String sessionId) async {
    await updateCallLog(
      sessionId,
      status: CallLogStatus.cancelled,
      endTime: DateTime.now(),
    );
  }
}
