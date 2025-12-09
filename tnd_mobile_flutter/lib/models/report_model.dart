/// Report Models
/// Data models for reports feature

class ReportOverview {
  final int totalVisits;
  final int totalOutlets;
  final int okCount;
  final int nokCount;
  final int naCount;
  final int totalResponses;
  final double okPercentage;
  final double nokPercentage;
  final List<RecentVisit> recentVisits;
  final String? divisionName;
  final ReportFilters? filters;

  ReportOverview({
    required this.totalVisits,
    required this.totalOutlets,
    required this.okCount,
    required this.nokCount,
    required this.naCount,
    required this.totalResponses,
    required this.okPercentage,
    required this.nokPercentage,
    required this.recentVisits,
    this.divisionName,
    this.filters,
  });

  factory ReportOverview.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return ReportOverview(
      totalVisits: data['total_visits'] ?? 0,
      totalOutlets: data['total_outlets'] ?? 0,
      okCount: data['ok_count'] ?? 0,
      nokCount: data['nok_count'] ?? 0,
      naCount: data['na_count'] ?? 0,
      totalResponses: data['total_responses'] ?? 0,
      okPercentage: (data['ok_percentage'] ?? 0).toDouble(),
      nokPercentage: (data['nok_percentage'] ?? 0).toDouble(),
      recentVisits: (data['recent_visits'] as List<dynamic>?)
              ?.map((v) => RecentVisit.fromJson(v))
              .toList() ??
          [],
      divisionName: data['division_name'],
      filters: data['filters'] != null 
          ? ReportFilters.fromJson(data['filters']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_visits': totalVisits,
      'total_outlets': totalOutlets,
      'ok_count': okCount,
      'nok_count': nokCount,
      'na_count': naCount,
      'total_responses': totalResponses,
      'ok_percentage': okPercentage,
      'nok_percentage': nokPercentage,
      'recent_visits': recentVisits.map((v) => v.toJson()).toList(),
      'division_name': divisionName,
      'filters': filters?.toJson(),
    };
  }
}

class RecentVisit {
  final int visitId;
  final int outletId;
  final String outletName;
  final String visitDate;
  final String visitStatus;
  final int totalItems;
  final int okItems;
  final int nokItems;
  final double okPercentage;
  final String status; // Good, Warning, Critical
  final String statusColor;

  RecentVisit({
    required this.visitId,
    required this.outletId,
    required this.outletName,
    required this.visitDate,
    required this.visitStatus,
    required this.totalItems,
    required this.okItems,
    required this.nokItems,
    required this.okPercentage,
    required this.status,
    required this.statusColor,
  });

  factory RecentVisit.fromJson(Map<String, dynamic> json) {
    return RecentVisit(
      visitId: json['visit_id'] ?? 0,
      outletId: json['outlet_id'] ?? 0,
      outletName: json['outlet_name'] ?? '',
      visitDate: json['visit_date'] ?? '',
      visitStatus: json['visit_status'] ?? '',
      totalItems: json['total_items'] ?? 0,
      okItems: json['ok_items'] ?? 0,
      nokItems: json['nok_items'] ?? 0,
      okPercentage: (json['ok_percentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      statusColor: json['status_color'] ?? '#9E9E9E',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visit_id': visitId,
      'outlet_id': outletId,
      'outlet_name': outletName,
      'visit_date': visitDate,
      'visit_status': visitStatus,
      'total_items': totalItems,
      'ok_items': okItems,
      'nok_items': nokItems,
      'ok_percentage': okPercentage,
      'status': status,
      'status_color': statusColor,
    };
  }
}

class OutletReport {
  final int outletId;
  final String outletName;
  final String? address;
  final String? city;
  final int totalVisits;
  final String? lastVisitDate;
  final int totalItems;
  final int okCount;
  final int nokCount;
  final int naCount;
  final double okPercentage;
  final double nokPercentage;
  final String status; // Good, Warning, Critical
  final String statusColor;
  final List<NokIssue> topNokIssues;

  OutletReport({
    required this.outletId,
    required this.outletName,
    this.address,
    this.city,
    required this.totalVisits,
    this.lastVisitDate,
    required this.totalItems,
    required this.okCount,
    required this.nokCount,
    required this.naCount,
    required this.okPercentage,
    required this.nokPercentage,
    required this.status,
    required this.statusColor,
    required this.topNokIssues,
  });

  factory OutletReport.fromJson(Map<String, dynamic> json) {
    return OutletReport(
      outletId: json['outlet_id'] ?? 0,
      outletName: json['outlet_name'] ?? '',
      address: json['address'],
      city: json['city'],
      totalVisits: json['total_visits'] ?? 0,
      lastVisitDate: json['last_visit_date'],
      totalItems: json['total_items'] ?? 0,
      okCount: json['ok_count'] ?? 0,
      nokCount: json['nok_count'] ?? 0,
      naCount: json['na_count'] ?? 0,
      okPercentage: (json['ok_percentage'] ?? 0).toDouble(),
      nokPercentage: (json['nok_percentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      statusColor: json['status_color'] ?? '#9E9E9E',
      topNokIssues: (json['top_nok_issues'] as List<dynamic>?)
              ?.map((i) => NokIssue.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outlet_id': outletId,
      'outlet_name': outletName,
      'address': address,
      'city': city,
      'total_visits': totalVisits,
      'last_visit_date': lastVisitDate,
      'total_items': totalItems,
      'ok_count': okCount,
      'nok_count': nokCount,
      'na_count': naCount,
      'ok_percentage': okPercentage,
      'nok_percentage': nokPercentage,
      'status': status,
      'status_color': statusColor,
      'top_nok_issues': topNokIssues.map((i) => i.toJson()).toList(),
    };
  }
}

class NokIssue {
  final String point;
  final String category;
  final int frequency;

  NokIssue({
    required this.point,
    required this.category,
    required this.frequency,
  });

  factory NokIssue.fromJson(Map<String, dynamic> json) {
    return NokIssue(
      point: json['point'] ?? '',
      category: json['category'] ?? '',
      frequency: json['frequency'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point': point,
      'category': category,
      'frequency': frequency,
    };
  }
}

class OutletReportSummary {
  final int totalOutlets;
  final int goodOutlets;
  final int warningOutlets;
  final int criticalOutlets;

  OutletReportSummary({
    required this.totalOutlets,
    required this.goodOutlets,
    required this.warningOutlets,
    required this.criticalOutlets,
  });

  factory OutletReportSummary.fromJson(Map<String, dynamic> json) {
    return OutletReportSummary(
      totalOutlets: json['total_outlets'] ?? 0,
      goodOutlets: json['good_outlets'] ?? 0,
      warningOutlets: json['warning_outlets'] ?? 0,
      criticalOutlets: json['critical_outlets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_outlets': totalOutlets,
      'good_outlets': goodOutlets,
      'warning_outlets': warningOutlets,
      'critical_outlets': criticalOutlets,
    };
  }
}

class ReportFilters {
  final String? startDate;
  final String? endDate;
  final int? outletId;

  ReportFilters({
    this.startDate,
    this.endDate,
    this.outletId,
  });

  factory ReportFilters.fromJson(Map<String, dynamic> json) {
    return ReportFilters(
      startDate: json['start_date'],
      endDate: json['end_date'],
      outletId: json['outlet_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate,
      'end_date': endDate,
      'outlet_id': outletId,
    };
  }
}
