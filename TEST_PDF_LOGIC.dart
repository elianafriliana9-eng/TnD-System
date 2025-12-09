// Test script to check if categories loaded correctly

void main() {
  // Sample response from backend (expected structure)
  final Map<String, dynamic> sampleSessionDetail = {
    'evaluation_summary': [
      {
        'id': 1,
        'category_name': 'NILAI HOSPITALITY',
        'points': [
          {'id': 1, 'point_text': 'Staff mengerti pentingnya hospitality', 'order': 1},
          {'id': 2, 'point_text': 'Selalu tubuh tegap dan ramah', 'order': 2},
        ]
      },
      {
        'id': 2,
        'category_name': 'NILAI ETOS KERJA',
        'points': [
          {'id': 3, 'point_text': 'Attitude', 'order': 1},
          {'id': 4, 'point_text': 'Disiplin', 'order': 2},
        ]
      },
    ]
  };

  // Simulated responses mapping
  final Map<int, String> responses = {
    1: 'check',
    2: 'check',
    3: 'cross',
    4: 'check',
  };

  // What PDF service receives
  final List<Map<String, dynamic>> categories = 
    sampleSessionDetail['evaluation_summary'] as List<Map<String, dynamic>>;

  print('✓ Categories received: ${categories.length}');
  for (int i = 0; i < categories.length; i++) {
    final cat = categories[i];
    final points = (cat['points'] as List?)?.length ?? 0;
    print('  Category $i: ${cat['category_name']} - $points points');
  }

  print('\n✓ Responses: ${responses.length}');
  print('  OK: ${responses.values.where((r) => r == 'check').length}');
  print('  NOK: ${responses.values.where((r) => r == 'cross').length}');
  print('  N/A: ${responses.values.where((r) => r == 'na').length}');

  // Now check if _buildCategoryCard logic works
  print('\n✓ Building category cards:');
  for (final cat in categories) {
    final points = (cat['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final okItems = points.where((p) => responses[p['id']] == 'check').toList();
    final nokCount = points.where((p) => responses[p['id']] == 'cross').length;
    
    print('  ${cat['category_name']}: OK=${okItems.length}, NOK=$nokCount');
    for (final item in okItems) {
      print('    ✓ ${item['point_text']}');
    }
  }
}
