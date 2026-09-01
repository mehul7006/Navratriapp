---
task_id: "5"
epic: cancel-prize-redraw
title: Create cancellation dialog component
status: pending
priority: high
dependencies: ["3"]
parallel: false
---

# Task 5: Create cancellation dialog component

## Description
Create a reusable dialog component for prize cancellation that requires organisers to enter a reason before confirming cancellation. This dialog will be used in both Lucky Draw and Ticket Management screens.

## Acceptance Criteria
- [ ] Dialog shows confirmation message
- [ ] Dialog has text input for cancellation reason
- [ ] Reason field is required (cannot be empty)
- [ ] Dialog has Confirm and Cancel buttons
- [ ] Confirm button is disabled when reason is empty
- [ ] Dialog returns reason on confirm, null on cancel
- [ ] Dialog follows existing UI patterns

## Technical Details
```dart
// Create reusable dialog function
Future<String?> showCancelPrizeDialog(BuildContext context) {
  final reasonController = TextEditingController();
  
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancel Prize'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Are you sure you want to cancel this prize?'),
          SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for cancellation *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: reasonController.text.isEmpty
            ? null
            : () => Navigator.pop(context, reasonController.text),
          child: Text('Confirm'),
        ),
      ],
    ),
  );
}
```

## Testing
- Test dialog displays correctly
- Test reason field is required
- Test confirm button disabled when empty
- Test returns reason on confirm
- Test returns null on cancel
- Test dialog can be reused in different screens

## Notes
- Place dialog in a shared widgets file or inline in lucky_draw_screen
- Follow existing dialog patterns in the app
- Consider adding validation for minimum reason length
