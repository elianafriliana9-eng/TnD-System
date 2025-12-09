import '../models/category_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

/// Category Service
/// Handles category and category items operations
class CategoryService {
  final ApiService _apiService = ApiService();

  /// Get all categories for current user's division
  Future<ApiResponse<List<ChecklistCategoryModel>>> getCategories() async {
    try {
      final response = await _apiService.get(
        '/visit-categories.php',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => ChecklistCategoryModel.fromJson(item)).toList();
          }
          return <ChecklistCategoryModel>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get items for a specific category
  Future<ApiResponse<List<CategoryItemModel>>> getCategoryItems(int categoryId) async {
    try {
      final response = await _apiService.get(
        '/category-items.php?category_id=$categoryId',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => CategoryItemModel.fromJson(item)).toList();
          }
          return <CategoryItemModel>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
