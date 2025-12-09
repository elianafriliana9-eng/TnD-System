# Delete Functionality - Quick Troubleshooting Checklist

## Pre-Test Checklist
- [ ] Laragon is running (Start All button clicked)
- [ ] MySQL is running and accessible
- [ ] PHP server is running
- [ ] Flutter app is compiled and running
- [ ] User is logged in to the app
- [ ] Training items exist in the database to delete

## Test Execution Checklist

### 1. UI Check
- [ ] Navigate to Training > Management Checklist screen
- [ ] Categories are displayed with expandable items
- [ ] Items display in the expanded categories
- [ ] 3-dot menu (⋮) is visible on each item

### 2. Delete Interaction
- [ ] Tap 3-dot menu on any item
- [ ] "Delete" option appears in popup menu
- [ ] Tap Delete → confirmation dialog appears
- [ ] Dialog shows item name or description
- [ ] "Hapus" and "Batal" buttons are visible

### 3. Delete Attempt
- [ ] Tap "Hapus" button
- [ ] Watch Flutter console for output
- [ ] Check for SnackBar message (top or bottom of screen)

### 4. Result Verification
- [ ] SnackBar appears with clear message
- [ ] Message is either success (green) or error (red)
- [ ] If successful: item disappears from list
- [ ] Console shows debug logs

## Console Output Checklist

### Expected Successful Flow
- [ ] `Deleting item: [ID]` appears
- [ ] `DELETE Request URL: ...` appears
- [ ] `DELETE Response Status Code: 200` appears
- [ ] `_handleResponse: success status code` appears
- [ ] `Delete response success: true` appears
- [ ] `Delete response message: Item deleted successfully` appears

### Signs of Network Issues
- [ ] `DELETE Error - Exception: SocketException`
- [ ] `Failed host lookup`
- [ ] `Connection timeout`
- [ ] `Request timeout`

### Signs of Response Parsing Issues
- [ ] `_handleResponse: Exception caught`
- [ ] `FormatException` in output
- [ ] `JSON decode error`
- [ ] Response body is HTML (not JSON)

## Backend Verification

### Check PHP Error Log
```powershell
Get-Content "C:\laragon\logs\php_error.log" -Tail 30
```

- [ ] Look for "DELETE endpoint:" lines
- [ ] Check if itemId is received correctly
- [ ] Verify "Delete executed, rowCount = 1"
- [ ] No PHP exceptions or warnings
- [ ] No fatal errors

### Check Database
```sql
-- Connect via Laragon MySQL admin
SELECT COUNT(*) as item_count FROM training_items;
SELECT * FROM training_items WHERE id = [deleted_id];
-- Second query should return empty
```

- [ ] Item count decreased after delete
- [ ] Deleted item is gone from database
- [ ] Other items remain intact

### Check Network Request
- [ ] HTTP method is DELETE (not GET/POST)
- [ ] URL includes `?id=123` parameter
- [ ] Status code is 200 or 2xx range
- [ ] Response JSON has `"success": true`

## If Delete Fails

### Step 1: Identify Error Type
- [ ] Is SnackBar red (error) or silent (no SnackBar)?
- [ ] What's the error message text?
- [ ] What's in Flutter console?
- [ ] What's in PHP error log?

### Step 2: Check Most Common Issues
- [ ] Laragon actually running? (Check services)
- [ ] Database connection working? (Try other API calls)
- [ ] User logged in? (Check if other screens work)
- [ ] Item ID valid? (Verify in database)
- [ ] Item exists before delete? (Query database)

### Step 3: Test API Directly
```powershell
# Run test script (requires valid itemId)
.\test-delete-api.ps1
```

- [ ] Script runs without hanging
- [ ] Status code is shown
- [ ] Response JSON is valid
- [ ] Can delete successfully via script?

### Step 4: Enable Debug Mode
- [ ] Build Flutter in debug mode
- [ ] Watch DevTools console
- [ ] Enable detailed logging in Flutter
- [ ] Check network inspector in DevTools

## Success Criteria

Delete functionality is working when:

✅ **All of these are true:**
1. Green SnackBar appears: "Item berhasil dihapus"
2. Item disappears from list after delete
3. Database query shows item is gone
4. PHP error log shows no errors
5. Console logs show `success: true`
6. Status code is 200

❌ **Delete fails if:**
1. Red SnackBar shows error message
2. Item remains in list after clicking delete
3. Database still contains item
4. PHP error log shows errors or warnings
5. Console shows exception or timeout
6. Status code is not 200

## Rollback Steps (if needed)

If changes cause issues:

```powershell
# Revert API Service changes
git checkout tnd_mobile_flutter/lib/services/api_service.dart

# Revert Management Screen changes
git checkout tnd_mobile_flutter/lib/screens/training/training_checklist_management_screen.dart

# Revert Backend changes
git checkout backend-web/api/training/item-delete.php
```

## Contact Information

If delete still doesn't work after these steps:
1. Collect console output
2. Collect PHP error log lines
3. Screenshot of SnackBar message
4. Screenshot of database query result
5. Copy of entire test output

Provide all above information for faster debugging.

---

**Last Updated**: When delete functionality logging was enhanced
**Status**: Ready for testing
**Tested On**: Production server (tndsystem.online) and Local Laragon setup
