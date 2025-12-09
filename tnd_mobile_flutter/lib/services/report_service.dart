import '../models/report_model.dart';
import 'api_service.dart';

/// Report Service
/// Handle all report-related API calls
class ReportService {
  final ApiService _apiService = ApiService();

  /// Get report overview statistics
  /// 
  /// [userId] - User ID
  /// [startDate] - Start date filter (YYYY-MM-DD)
  /// [endDate] - End date filter (YYYY-MM-DD)
  Future<ReportOverview> getOverview({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId.toString(),
      };

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse('/report-overview.php')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(uri.toString());

      if (response.success && response.data != null) {
        return ReportOverview.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to load report overview');
      }
    } catch (e) {
      throw Exception('Error loading report overview: $e');
    }
  }

  /// Get report by outlet
  /// 
  /// [userId] - User ID
  /// [startDate] - Start date filter (YYYY-MM-DD)
  /// [endDate] - End date filter (YYYY-MM-DD)
  /// [outletId] - Optional outlet ID to filter specific outlet
  Future<List<OutletReport>> getOutletReports({
    required int userId,
    String? startDate,
    String? endDate,
    int? outletId,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId.toString(),
      };

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (outletId != null && outletId > 0) {
        queryParams['outlet_id'] = outletId.toString();
      }

      final uri = Uri.parse('/report-by-outlet.php')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(uri.toString());

      if (response.success && response.data != null) {
        // response.data is already a List from API
        final List<dynamic> dataList = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        
        return dataList.map((json) => OutletReport.fromJson(json)).toList();
      } else {
        throw Exception(response.message ?? 'Failed to load outlet reports');
      }
    } catch (e) {
      throw Exception('Error loading outlet reports: $e');
    }
  }

  /// Get outlet report summary
  /// 
  /// [userId] - User ID
  /// [startDate] - Start date filter (YYYY-MM-DD)
  /// [endDate] - End date filter (YYYY-MM-DD)
  Future<OutletReportSummary> getOutletReportSummary({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId.toString(),
      };

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse('/report-by-outlet.php')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(uri.toString());

      if (response.success && response.data != null) {
        final summary = response.data['summary'];
        if (summary != null) {
          return OutletReportSummary.fromJson(summary);
        } else {
          // Calculate summary from data if not provided
          final List<dynamic> data = response.data['data'] ?? [];
          final outlets = data.map((json) => OutletReport.fromJson(json)).toList();
          
          return OutletReportSummary(
            totalOutlets: outlets.length,
            goodOutlets: outlets.where((o) => o.status == 'Good').length,
            warningOutlets: outlets.where((o) => o.status == 'Warning').length,
            criticalOutlets: outlets.where((o) => o.status == 'Critical').length,
          );
        }
      } else {
        throw Exception(response.message ?? 'Failed to load outlet summary');
      }
    } catch (e) {
      throw Exception('Error loading outlet summary: $e');
    }
  }

  /// Get data for PDF export
  /// 
  /// [userId] - User ID
  /// [reportType] - Type of report (overview, outlet, outlet_detail)
  /// [startDate] - Start date filter (YYYY-MM-DD)
  /// [endDate] - End date filter (YYYY-MM-DD)
  /// [outletId] - Optional outlet ID for outlet-specific reports
  Future<Map<String, dynamic>> getExportData({
    required int userId,
    required String reportType,
    String? startDate,
    String? endDate,
    int? outletId,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId.toString(),
        'report_type': reportType,
      };

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (outletId != null && outletId > 0) {
        queryParams['outlet_id'] = outletId.toString();
      }

      final uri = Uri.parse('/export-report-pdf.php')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(uri.toString());

      if (response.success && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to load export data');
      }
    } catch (e) {
      throw Exception('Error loading export data: $e');
    }
  }
}
