import '../../models/training/training_models.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingService {
  final ApiService _apiService = ApiService();

  // Trainer Authentication - using main system login since trainer should be a user with trainer role
  Future<ApiResponse<TrainerModel>> loginTrainer(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiService.post(
        '/login.php', // Use main login endpoint
        body: {'email': email, 'password': password},
        fromJson: (data) => TrainerModel.fromJson(data),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  Future<ApiResponse<void>> logoutTrainer() async {
    try {
      final response = await _apiService.post(
        '/logout.php',
      ); // Use main logout endpoint
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Training Checklists Management (using existing training endpoints)
  Future<ApiResponse<List<TrainingChecklistCategory>>> getChecklists() async {
    try {
      final response = await _apiService.get(
        '/training/checklists.php', // Use actual existing endpoint
        fromJson: (data) {
          if (data is Map &&
              data['data'] is Map &&
              data['data']['checklists'] is List) {
            return (data['data']['checklists'] as List)
                .map((item) => _convertChecklistToCategory(item))
                .toList();
          } else if (data is Map && data['data'] is List) {
            // Alternative response structure
            return (data['data'] as List)
                .map((item) => _convertChecklistToCategory(item))
                .toList();
          } else if (data is List) {
            // Direct list response
            return data
                .map((item) => _convertChecklistToCategory(item))
                .toList();
          }
          return <TrainingChecklistCategory>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Helper to convert checklist to category structure
  TrainingChecklistCategory _convertChecklistToCategory(
    Map<String, dynamic> item,
  ) {
    return TrainingChecklistCategory(
      id: item['id'] ?? 0,
      name: item['name'] ?? 'Untitled',
      description: item['description'],
      isActive: true,
      sequenceOrder: item['order_index'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Get detailed checklist with categories and items
  Future<ApiResponse<Map<String, dynamic>>> getChecklistDetail(
    int checklistId,
  ) async {
    try {
      final response = await _apiService.get(
        '/training/checklist-detail.php?id=$checklistId', // Use actual existing endpoint
        fromJson: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          } else if (data is Map) {
            // Safe cast to avoid the type error
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get checklist categories
  Future<ApiResponse<List<TrainingChecklistCategory>>>
  getChecklistCategories() async {
    try {
      final response = await _apiService.get(
        '/training/categories-list.php', // Get actual categories (not checklists)
        fromJson: (data) {
          if (data is Map && data['data'] is List) {
            return (data['data'] as List)
                .map(
                  (item) => TrainingChecklistCategory.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
          } else if (data is List) {
            // Direct list response
            return data
                .map(
                  (item) => TrainingChecklistCategory.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
          }
          return <TrainingChecklistCategory>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get checklist items for a category
  Future<ApiResponse<List<TrainingChecklistItem>>> getChecklistItems({
    required int categoryId,
  }) async {
    try {
      final response = await _apiService.get(
        '/training/checklist-items.php?category_id=$categoryId',
        fromJson: (data) {
          if (data is Map && data['data'] is List) {
            return (data['data'] as List)
                .map(
                  (item) => TrainingChecklistItem.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
          } else if (data is List) {
            return data
                .map(
                  (item) => TrainingChecklistItem.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
          }
          return <TrainingChecklistItem>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get training responses for a session (not used in new implementation, but keeping for compatibility)
  Future<ApiResponse<List<TrainingResponse>>> getResponses(
    int sessionId,
  ) async {
    try {
      final response = await _apiService.get(
        '/training/session-detail.php?id=$sessionId', // Use actual existing endpoint
        fromJson: (data) {
          if (data is Map &&
              data['data'] is Map &&
              data['data']['evaluation_summary'] is List) {
            final categories = data['data']['evaluation_summary'] as List;
            final responses = <TrainingResponse>[];

            for (final category in categories) {
              if (category['points'] is List) {
                for (final point in category['points']) {
                  if (point['rating'] != null) {
                    // Only include points that have been evaluated
                    responses.add(
                      TrainingResponse(
                        id: 0, // Will be set by server if needed
                        sessionId: sessionId,
                        itemId: point['id'] ?? 0,
                        responseType: point['rating'] ?? 'n/a',
                        trainerComment: point['notes'],
                        leaderComment: null,
                        photoPaths: [],
                        createdAt: DateTime.now(),
                        isRevised: false,
                      ),
                    );
                  }
                }
              }
            }
            return responses;
          }
          return <TrainingResponse>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Save individual training response (for checklist item) - deprecated in favor of bulk save
  Future<ApiResponse<void>> saveResponse({
    required int sessionId,
    required int itemId,
    required String responseType,
    String? trainerComment,
    String? leaderComment,
    List<String>? photoPaths,
  }) async {
    try {
      final response = await _apiService.post(
        '/training/responses-save.php', // Use actual existing endpoint
        body: {
          'session_id': sessionId,
          'responses': [
            {
              'participant_id':
                  0, // Using 0 as placeholder in checklist context
              'point_id': itemId,
              'score': _responseToScore(
                responseType,
              ), // Convert response type to numeric score
              'notes': trainerComment,
            },
          ],
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Helper to convert response type to score
  int _responseToScore(String responseType) {
    switch (responseType.toLowerCase()) {
      case 'check':
      case 'ok':
        return 5; // Excellent/Good
      case 'x':
      case 'ng':
        return 2; // Needs improvement
      case 'n/a':
      default:
        return 0; // Not applicable
    }
  }

  // Create a new training category
  Future<ApiResponse<TrainingChecklistCategory>> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        '/training/category-save.php', // Use dedicated category endpoint
        body: {'name': name, 'description': description ?? ''},
        fromJson: (dynamic data) {
          if (data is Map<String, dynamic>) {
            return TrainingChecklistCategory.fromJson(data);
          } else if (data is Map) {
            return TrainingChecklistCategory.fromJson(
              Map<String, dynamic>.from(data),
            );
          } else {
            return TrainingChecklistCategory(
              id: 0,
              name: name,
              description: description,
              isActive: true,
              sequenceOrder: null,
              createdAt: DateTime.now(),
            );
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Update an existing training category
  Future<ApiResponse<TrainingChecklistCategory>> updateCategory(
    TrainingChecklistCategory category,
  ) async {
    try {
      final response = await _apiService.post(
        '/training/category-save.php', // Use dedicated category endpoint
        body: {
          'id': category.id,
          'name': category.name,
          'description': category.description ?? '',
          'is_active': category.isActive ? 1 : 0,
          'order_index': category.sequenceOrder,
        },
        fromJson: (dynamic data) {
          if (data is Map<String, dynamic>) {
            return TrainingChecklistCategory.fromJson(data);
          } else if (data is Map) {
            return TrainingChecklistCategory.fromJson(
              Map<String, dynamic>.from(data),
            );
          } else {
            return category;
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Create a new checklist item
  Future<ApiResponse<TrainingChecklistItem>> createChecklistItem({
    required int categoryId,
    required String itemText,
    String? description,
    int? sequenceOrder,
  }) async {
    try {
      final response = await _apiService.post(
        '/training/item-save.php', // Use dedicated item endpoint
        body: {
          'category_id': categoryId,
          'item_text': itemText,
          'description': description ?? '',
          'sequence_order': sequenceOrder,
        },
        fromJson: (data) {
          if (data is Map && data['data'] is Map) {
            return TrainingChecklistItem.fromJson(
              Map<String, dynamic>.from(data['data']),
            );
          } else if (data is Map) {
            return TrainingChecklistItem.fromJson(
              Map<String, dynamic>.from(data),
            );
          }
          throw Exception('Invalid data format for TrainingChecklistItem');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Update an existing checklist item
  Future<ApiResponse<TrainingChecklistItem>> updateChecklistItem(
    TrainingChecklistItem item,
  ) async {
    try {
      final response = await _apiService.post(
        '/training/item-save.php', // Use dedicated item endpoint
        body: {
          'id': item.id,
          'category_id': item.categoryId,
          'item_text': item.itemText,
          'description': item.description ?? '',
          'sequence_order': item.sequenceOrder ?? 0,
        },
        fromJson: (data) {
          if (data is Map) {
            return TrainingChecklistItem.fromJson(
              Map<String, dynamic>.from(data),
            );
          } else {
            return item;
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Training Schedule Management (using existing training endpoints)
  Future<ApiResponse<List<TrainingScheduleModel>>> getSchedules({
    String? status,
  }) async {
    try {
      String endpoint =
          '/training/sessions-list.php'; // Use actual existing endpoint for sessions list
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await _apiService.get(
        endpoint,
        fromJson: (data) {
          if (data is Map) {
            if (data['data'] is Map && data['data']['sessions'] is List) {
              return (data['data']['sessions'] as List)
                  .map((item) => _convertSessionToListModel(item))
                  .toList();
            } else if (data['data'] is List) {
              return (data['data'] as List)
                  .map((item) => _convertSessionToListModel(item))
                  .toList();
            }
          } else if (data is List) {
            return data
                .map((item) => _convertSessionToListModel(item))
                .toList();
          }
          return <TrainingScheduleModel>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Helper to convert session data to TrainingScheduleModel for list view
  TrainingScheduleModel _convertSessionToListModel(Map<String, dynamic> item) {
    // Helper function for safe date parsing
    DateTime parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    // Extract nested outlet data
    String outletName = 'Unknown';
    int outletId = 0;
    if (item['outlet'] is Map) {
      outletName = (item['outlet']['name'] as String?) ?? 'Unknown';
      outletId = (item['outlet']['id'] as int?) ?? 0;
    } else {
      // Fallback to flat structure if available
      outletName = (item['outlet_name'] as String?) ?? 'Unknown';
      outletId = (item['outlet_id'] as int?) ?? 0;
    }

    // Extract nested trainer data
    String trainerName = 'TBD';
    int? trainerId;
    if (item['trainer'] is Map) {
      trainerName = (item['trainer']['name'] as String?) ?? 'TBD';
      trainerId = (item['trainer']['id'] as int?);
    } else {
      // Fallback to flat structure if available
      trainerName = (item['trainer_name'] as String?) ?? 'TBD';
      trainerId = (item['trainer_id'] as int?);
    }

    return TrainingScheduleModel(
      id: (item['id'] as int?) ?? 0,
      outletId: outletId,
      outletName: outletName,
      scheduledDate: parseDate(item['session_date']),
      scheduledTime: (item['start_time'] as String?) ?? '00:00',
      crewLeader: item['crew_leader'] as String?,
      crewName: item['crew_name'] as String?, // Add crew_name mapping
      status: (item['status'] as String?) ?? 'scheduled',
      trainerId: trainerId,
      trainerName: trainerName,
      createdAt: parseDate(item['created_at']),
      updatedAt: parseDate(item['updated_at']),
      categories: item['categories'] != null
          ? (item['categories'] as List)
                .map(
                  (categoryJson) =>
                      TrainingChecklistCategory.fromJson(categoryJson),
                )
                .toList()
          : null,
    );
  }

  // Helper to convert session response to TrainingScheduleModel
  TrainingScheduleModel _convertSessionToScheduleModel(
    Map<String, dynamic> item,
  ) {
    // Safely parse dates with fallback
    DateTime parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return TrainingScheduleModel(
      id: item['id'] as int? ?? 0,
      outletId: item['outlet_id'] as int? ?? 0,
      outletName: item['outlet_name'] as String? ?? 'Unknown',
      scheduledDate: parseDate(item['session_date']),
      scheduledTime: item['start_time'] as String? ?? '00:00',
      crewLeader: item['crew_leader'] as String? ?? item['notes'] as String?,
      crewName: item['crew_name'] as String?, // Add crew_name mapping
      status: item['status'] as String? ?? 'scheduled',
      trainerId: item['trainer_id'] as int?,
      trainerName: item['trainer_name'] as String?,
      createdAt: parseDate(item['created_at']),
      updatedAt: parseDate(item['updated_at']),
      categories: item['categories'] != null
          ? (item['categories'] as List)
                .map(
                  (categoryJson) =>
                      TrainingChecklistCategory.fromJson(categoryJson),
                )
                .toList()
          : null,
    );
  }

  // Create training schedule (uses the same endpoint as starting session but with scheduled status)
  Future<ApiResponse<TrainingScheduleModel>> createSchedule({
    required int outletId,
    required String scheduledDate,
    required String scheduledTime,
    required String crewLeader,
    String? crewName,
    required List<int> categoryIds,
    String? status,
  }) async {
    try {
      // Get trainer_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final trainerId = prefs.getInt('user_id');

      if (trainerId == null) {
        return ApiResponse.error(
          message: 'Trainer ID not found. Please login again.',
        );
      }

      print(
        'Creating schedule with crew leader: $crewLeader and status: ${status ?? 'scheduled'}',
      );

      final response = await _apiService.post(
        '/training/session-start.php',
        body: {
          'outlet_id': outletId,
          'trainer_id': trainerId,
          'category_ids': categoryIds,
          'session_date': scheduledDate,
          'start_time': scheduledTime,
          'crew_leader': crewLeader, // Use dedicated field
          'crew_name': crewName, // Nama crew yang ditraining
          'status': status ?? 'scheduled', // Always create as scheduled
        },
        fromJson: (data) {
          try {
            print('=== CreateSchedule Response Debug ===');
            print('Data received in fromJson: $data');
            print('Data type: ${data.runtimeType}');

            if (data is! Map) {
              throw Exception('Data is not a Map, got ${data.runtimeType}');
            }

            final dataMap = data as Map<String, dynamic>;

            if (dataMap['session'] == null) {
              throw Exception('session field is null in response');
            }

            if (dataMap['session'] is! Map) {
              throw Exception('session is not a Map');
            }

            final sessionData = dataMap['session'] as Map<String, dynamic>;

            print('Session data extracted successfully');
            print('Session ID: ${sessionData['id']}');
            print('Outlet name: ${sessionData['outlet_name']}');

            return _convertSessionToScheduleModel(sessionData);
          } catch (e) {
            print('ERROR in createSchedule fromJson: $e');
            rethrow;
          }
        },
      );
      return response;
    } catch (e) {
      print('CreateSchedule error: $e');
      return ApiResponse.error(message: 'Failed to save training schedule: $e');
    }
  }

  Future<ApiResponse<TrainingSessionModel>> startSession({
    required int outletId,
    required int checklistId,
    required String sessionDate,
    required String startTime,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        '/training/session-start.php', // Use actual existing endpoint
        body: {
          'outlet_id': outletId,
          'checklist_id': checklistId,
          'session_date': sessionDate,
          'start_time': startTime,
          'notes': notes,
        },
        fromJson: (data) {
          if (data is Map &&
              data['data'] is Map &&
              data['data']['session'] is Map) {
            return _convertSessionToModel(data['data']['session']);
          } else if (data is Map && data['data'] is Map) {
            return _convertSessionToModel(data['data']);
          }
          throw Exception('Invalid session data format');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Start training session from daily training view (changes status to ongoing)
  Future<ApiResponse<TrainingScheduleModel>> startTrainingSession({
    required int sessionId,
  }) async {
    try {
      final response = await _apiService.post(
        'https://tndsystem.online/backend-web/api/training/session-actual-start.php',
        isFullUrl: true,
        body: {'session_id': sessionId},
        fromJson: (data) {
          // ApiResponse.fromJson extracts json['data'] and passes it here
          // So we receive: { message, session: {...} } or just the session object
          print('startTrainingSession.fromJson received: $data');
          print('startTrainingSession.fromJson data type: ${data.runtimeType}');

          if (data is Map) {
            print(
              'startTrainingSession: data is Map, checking for session key',
            );
            // Check if session is directly in data
            if (data['session'] is Map) {
              print('startTrainingSession: Found session in data[session]');
              return _convertSessionToScheduleModel(
                Map<String, dynamic>.from(data['session'] as Map),
              );
            }
            // If data itself is the session (no session key wrapper)
            if (data['id'] is int) {
              print('startTrainingSession: Data is the session object itself');
              return _convertSessionToScheduleModel(
                Map<String, dynamic>.from(data),
              );
            }
          }

          print(
            'startTrainingSession: Unable to parse session from data: $data',
          );
          throw Exception(
            'Invalid session data format. Expected Map with session or id field. Got: $data',
          );
        },
      );
      return response;
    } catch (e) {
      print('startTrainingSession error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Save training session to report history
  // NOTE: This is an optional operation - errors are silently ignored
  Future<ApiResponse<void>> saveTrainingToReport({
    required int sessionId,
    required String outletName,
    required DateTime sessionDate,
    required String trainerName,
    required String notes,
  }) async {
    try {
      print(
        'DEBUG: saveTrainingToReport - Sending session_id=$sessionId to /training/save-to-report.php',
      );
      final response = await _apiService.post(
        '/training/save-to-report.php',
        body: {
          'session_id': sessionId,
          'outlet_name': outletName,
          'session_date': sessionDate.toIso8601String().split('T')[0],
          'trainer_name': trainerName,
          'notes': notes,
        },
        fromJson: (_) => null,
      );
      print(
        'DEBUG: saveTrainingToReport - Response: ${response.success}, StatusCode: ${response.statusCode}',
      );

      // Always return success for this optional operation
      // Even if backend returns error, we treat it as success since data is already saved
      if (response.success) {
        return response;
      } else {
        // Backend returned error, but we treat it as success since this is optional
        print(
          'DEBUG: saveTrainingToReport - Backend error ignored (optional operation): ${response.message}',
        );
        return ApiResponse.success(
          data: null,
          message: 'Report save skipped (optional operation)',
        );
      }
    } catch (e) {
      // Silently ignore all errors for this optional operation
      print(
        'DEBUG: saveTrainingToReport - Exception ignored (optional operation): $e',
      );
      return ApiResponse.success(
        data: null,
        message: 'Report save skipped (optional operation)',
      );
    }
  }

  // Get training history/completed sessions
  Future<ApiResponse<List<Map<String, dynamic>>>> getTrainingHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      String endpoint = '/training/history.php';
      if (limit != null || offset != null) {
        endpoint +=
            '?${limit != null ? 'limit=$limit' : ''}${offset != null ? '&offset=$offset' : ''}';
      }

      final response = await _apiService.get(
        endpoint,
        fromJson: (data) {
          if (data is List) {
            return data.cast<Map<String, dynamic>>();
          } else if (data is Map && data['history'] is List) {
            return List<Map<String, dynamic>>.from(data['history']);
          }
          return <Map<String, dynamic>>[];
        },
      );
      return response;
    } catch (e) {
      print('Error loading training history: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get training session PDF data
  Future<ApiResponse<Map<String, dynamic>>> getSessionPdfData(
    int sessionId,
  ) async {
    try {
      final response = await _apiService.get(
        '/training/pdf-data.php?session_id=$sessionId',
        fromJson: (data) {
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      return response;
    } catch (e) {
      print('Error loading PDF data: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Helper to convert session response to TrainingSessionModel
  TrainingSessionModel _convertSessionToModel(Map<String, dynamic> item) {
    return TrainingSessionModel(
      id: item['id'] ?? 0,
      scheduleId: item['id'] ?? 0,
      outletId: item['outlet_id'] ?? 0,
      outletName: item['outlet_name'] ?? 'Unknown Outlet',
      sessionDate: DateTime.parse(
        item['session_date'] ?? DateTime.now().toIso8601String(),
      ),
      trainerId: item['trainer_id'],
      trainerName: item['trainer_name'],
      crewLeaderId:
          item['trainer_id'], // Using trainer_id as crewLeaderId temporarily
      crewLeaderName:
          item['trainer_name'], // Using trainer name as crewLeader name temporarily
      status: item['status'] ?? 'ongoing',
      startedAt: item['start_time'] != null
          ? DateTime.parse('${item['session_date']}T${item['start_time']}')
          : DateTime.now(),
      completedAt: item['end_time'] != null
          ? DateTime.parse('${item['session_date']}T${item['end_time']}')
          : null,
      revisionNotes: item['notes'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Add participants to session
  Future<ApiResponse<void>> addParticipants({
    required int sessionId,
    required List<Map<String, dynamic>> participants,
  }) async {
    try {
      final response = await _apiService.post(
        '/training/participants-add.php', // Use actual existing endpoint
        body: {'session_id': sessionId, 'participants': participants},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Save training responses (evaluations)
  Future<ApiResponse<void>> saveResponses({
    required int sessionId,
    required List<Map<String, dynamic>> responses,
  }) async {
    try {
      print(
        'DEBUG: saveResponses - Sending session_id=$sessionId with ${responses.length} responses',
      );
      final response = await _apiService.post(
        '/training/responses-save.php', // Use actual existing endpoint
        body: {'session_id': sessionId, 'responses': responses},
      );
      print('DEBUG: saveResponses - Response: ${response.success}');
      return response;
    } catch (e) {
      print('DEBUG: saveResponses - ERROR: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Complete training session
  Future<ApiResponse<void>> completeSession({
    required int sessionId,
    required String endTime,
    String? notes,
  }) async {
    try {
      print(
        'DEBUG: completeSession - Sending session_id=$sessionId with endTime=$endTime',
      );
      final response = await _apiService.post(
        '/training/session-complete.php', // Use actual existing endpoint
        body: {'session_id': sessionId, 'end_time': endTime, 'notes': notes},
      );
      print('DEBUG: completeSession - Response: ${response.success}');
      return response;
    } catch (e) {
      print('DEBUG: completeSession - ERROR: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get training sessions (list view)
  Future<ApiResponse<List<TrainingSessionModel>>> getSessions({
    int? trainerId,
    int? outletId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      String endpoint =
          '/training/sessions-list.php'; // Use actual existing endpoint
      List<String> queryParams = [];

      if (trainerId != null) queryParams.add('trainer_id=$trainerId');
      if (outletId != null) queryParams.add('outlet_id=$outletId');
      if (status != null) queryParams.add('status=$status');
      if (dateFrom != null)
        queryParams.add(
          'date_from=${dateFrom.toIso8601String().split('T')[0]}',
        );
      if (dateTo != null)
        queryParams.add('date_to=${dateTo.toIso8601String().split('T')[0]}');

      if (queryParams.isNotEmpty) {
        endpoint += '?' + queryParams.join('&');
      }

      final response = await _apiService.get(
        endpoint,
        fromJson: (data) {
          if (data is Map &&
              data['data'] is Map &&
              data['data']['sessions'] is List) {
            return (data['data']['sessions'] as List)
                .map((session) => _convertSessionListModel(session))
                .toList();
          } else if (data is Map && data['data'] is List) {
            // Alternative format
            return (data['data'] as List)
                .map((session) => _convertSessionListModel(session))
                .toList();
          } else if (data is List) {
            // Direct list format
            return data
                .map((session) => _convertSessionListModel(session))
                .toList();
          }
          return <TrainingSessionModel>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Helper to convert session list data to TrainingSessionModel
  TrainingSessionModel _convertSessionListModel(
    Map<String, dynamic> sessionData,
  ) {
    return TrainingSessionModel(
      id: sessionData['id'] ?? 0,
      scheduleId: sessionData['id'] ?? 0,
      outletId: 0, // Not provided in list response
      outletName: sessionData['outlet_name'] ?? 'Unknown Outlet',
      sessionDate: DateTime.parse(
        sessionData['session_date'] ?? DateTime.now().toIso8601String(),
      ),
      trainerId: null, // Not in list response
      trainerName: sessionData['trainer_name'],
      crewLeaderId: null, // Not in list response
      crewLeaderName:
          sessionData['trainer_name'], // Using trainer as crew leader temporarily
      status: sessionData['status'] ?? 'ongoing',
      startedAt: sessionData['start_time'] != null
          ? DateTime.parse(
              '${sessionData['session_date']}T${sessionData['start_time']}',
            )
          : DateTime.now(),
      completedAt: sessionData['end_time'] != null
          ? DateTime.parse(
              '${sessionData['session_date']}T${sessionData['end_time']}',
            )
          : null,
      revisionNotes: sessionData['notes'] ?? sessionData['session_notes'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Get training session detail
  Future<ApiResponse<Map<String, dynamic>>> getSessionDetail(
    int sessionId,
  ) async {
    try {
      // Try session-detail first, fallback to pdf-data if not available
      final response = await _apiService.get(
        '/training/session-detail.php?id=$sessionId',
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );

      // If session-detail fails, try pdf-data endpoint as fallback
      if (!response.success) {
        print('DEBUG: session-detail failed, trying pdf-data endpoint');
        final pdfDataResponse = await _apiService.get(
          '/training/pdf-data.php?session_id=$sessionId',
          fromJson: (data) => data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{},
        );
        return pdfDataResponse;
      }

      return response;
    } catch (e) {
      // Fallback to pdf-data if session-detail throws error
      try {
        print('DEBUG: session-detail error, trying pdf-data endpoint');
        final pdfDataResponse = await _apiService.get(
          '/training/pdf-data.php?session_id=$sessionId',
          fromJson: (data) => data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{},
        );
        return pdfDataResponse;
      } catch (e2) {
        return ApiResponse.error(message: e.toString());
      }
    }
  }

  // Save signatures
  Future<ApiResponse<void>> saveSignatures({
    required int sessionId,
    String? trainerSignature,
    String? leaderSignature,
    String? crewLeader,
    String? crewLeaderPosition,
  }) async {
    try {
      print('DEBUG: saveSignatures - Sending session_id=$sessionId');
      final response = await _apiService.post(
        '/training/signatures-save.php', // Use actual existing endpoint
        body: {
          'session_id': sessionId,
          'trainer_signature': trainerSignature,
          'leader_signature': leaderSignature,
          'crew_name': crewLeader, // Save crew leader input as crew_name
          'crew_leader': crewLeader, // Keep for backward compatibility
        },
      );
      print('DEBUG: saveSignatures - Response: ${response.success}');
      return response;
    } catch (e) {
      print('DEBUG: saveSignatures - ERROR: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get training statistics/dashboard data
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats({
    String? dateFrom,
    String? dateTo,
    int? divisionId,
  }) async {
    try {
      // Default to last 30 days and next 30 days to include pending/scheduled sessions
      final from =
          dateFrom ??
          DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0];
      final to =
          dateTo ??
          DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0];

      // Build query parameters
      String url = '/training/stats.php?date_from=$from&date_to=$to';
      if (divisionId != null) {
        url += '&division_id=$divisionId';
      }

      final response = await _apiService.get(
        url,
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get PDF data for export
  Future<ApiResponse<Map<String, dynamic>>> getPdfData(int sessionId) async {
    try {
      final response = await _apiService.get(
        '/training/pdf-data.php?session_id=$sessionId', // Use actual existing endpoint
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Upload photos
  Future<ApiResponse<Map<String, dynamic>>> uploadPhoto(
    String filePath,
    int sessionId, {
    int? participantId,
    String? caption,
  }) async {
    try {
      // Note: In a real implementation, this would need to be a multipart request
      // For now, we'll pass the file path as a parameter to simulate
      final response = await _apiService.post(
        '/training/photo-upload.php', // Use actual existing endpoint
        body: {
          'session_id': sessionId,
          'participant_id': participantId,
          'caption': caption ?? '',
          'photo_path':
              filePath, // In real implementation, this would be the file upload
        },
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get training materials
  Future<ApiResponse<List<Map<String, dynamic>>>> getMaterials() async {
    try {
      final response = await _apiService.get(
        '/training/materials.php', // Use actual existing endpoint
        fromJson: (data) {
          if (data is List) {
            return data.cast<Map<String, dynamic>>();
          } else if (data is Map && data['data'] is List) {
            return (data['data'] as List).cast<Map<String, dynamic>>();
          }
          return <Map<String, dynamic>>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Upload training materials (PDF, PPTX, etc.)
  Future<ApiResponse<Map<String, dynamic>>> uploadMaterial(
    String filePath,
    String fileName,
    int sessionId,
  ) async {
    try {
      // Note: In a real implementation, this would need to be a multipart request
      final response = await _apiService.post(
        '/training/materials-upload.php', // Use actual existing endpoint
        body: {
          'session_id': sessionId,
          'file_path': filePath,
          'file_name': fileName,
          // In real implementation, this would be actual file upload
        },
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Generate PDF for training session
  Future<ApiResponse<Map<String, dynamic>>> generatePdf(int sessionId) async {
    try {
      final response = await _apiService.get(
        '/training/pdf-generate.php?session_id=$sessionId', // Use actual existing endpoint
        fromJson: (data) =>
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Delete training checklist
  Future<ApiResponse<void>> deleteChecklist(int checklistId) async {
    try {
      final response = await _apiService.delete(
        '/training/checklist-delete.php?id=$checklistId', // Use actual existing endpoint with DELETE method
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Delete training session (schedule)
  Future<ApiResponse<void>> deleteSession(int sessionId) async {
    try {
      final response = await _apiService.delete(
        '/training/session-delete.php?id=$sessionId', // Use actual existing endpoint with DELETE method
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Delete training category
  Future<ApiResponse<void>> deleteCategory(int categoryId) async {
    try {
      final response = await _apiService.delete(
        '/training/category-delete.php?id=$categoryId',
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  // Delete training checklist item
  Future<ApiResponse<void>> deleteChecklistItem(int itemId) async {
    try {
      print('Deleting item: $itemId');
      // Use direct file path since .htaccess routes through index.php which doesn't have training routes
      final response = await _apiService.delete(
        'https://tndsystem.online/backend-web/api/training/item-delete.php?id=$itemId',
        isFullUrl: true,
      );
      print('Delete response success: ${response.success}');
      print('Delete response message: ${response.message}');
      print('Delete response statusCode: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Delete error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  // Get list of outlets
  Future<ApiResponse<List<Map<String, dynamic>>>> getOutlets() async {
    try {
      final response = await _apiService.get(
        'https://tndsystem.online/backend-web/api/outlets.php?limit=9999',
        isFullUrl: true,
        fromJson: (data) {
          if (data is Map && data['data'] is List) {
            return (data['data'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else if (data is List) {
            return data.map((item) => item as Map<String, dynamic>).toList();
          }
          return <Map<String, dynamic>>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
