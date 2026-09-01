---
task_id: "3"
epic: cancel-prize-redraw
title: Add DatabaseHelper.cancelDraw method
status: pending
priority: high
dependencies: ["1"]
parallel: false
---

# Task 3: Add DatabaseHelper.cancelDraw method

## Description
Create a new method `cancelDraw` in `DatabaseHelper` class that calls the cancel API endpoint. This method will be used by the UI to cancel prize draws.

## Acceptance Criteria
- [ ] `cancelDraw` method added to DatabaseHelper
- [ ] Method accepts `drawId` and `reason` parameters
- [ ] Method calls `POST /api/daily-draws/cancel`
- [ ] Method returns updated draw record as Map
- [ ] Method handles errors appropriately
- [ ] Method follows existing coding patterns

## Technical Details
```dart
// In database_helper.dart
Future<Map<String, dynamic>> cancelDraw({
  required int drawId,
  required String reason,
}) async {
  final url = Uri.parse('$_baseUrl/api/daily-draws/cancel');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'draw_id': drawId,
      'reason': reason,
    }),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to cancel draw');
  }
}
```

## Testing
- Test method returns updated draw record
- Test method throws exception on API error
- Test method handles network errors
- Verify method follows existing patterns in DatabaseHelper

## Notes
- Follow existing method patterns in DatabaseHelper
- Use same error handling as other API methods
- Return type should be Map<String, dynamic> for consistency
