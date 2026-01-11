# Postman Test Structure for Create Task API

## Endpoint
```
POST https://sblport.site/api/eqp/operations/{scrum}/tasks
```
Replace `{scrum}` with your operation SCRUM ID (e.g., `DTGIP-01`)

## Headers
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
Accept: application/json
```

## Request Body (JSON)

### Minimal Request (without optional fields):
```json
{
  "task_start": "2026-01-11T06:00:00.000Z",
  "task_end": "2026-01-11T08:00:00.000Z",
  "activity_id": 1,
  "location_id": 1
}
```

### Full Request (with all optional fields):
```json
{
  "task_start": "2026-01-11T06:00:00.000Z",
  "task_end": "2026-01-11T08:00:00.000Z",
  "hm_start": 2500.0,
  "hm_end": 2502.5,
  "activity_id": 1,
  "location_id": 1,
  "code": "TEST-001",
  "result": "Completed successfully",
  "remarks": "Test remarks"
}
```

### With Order By field (when endpoint is ready):
```json
{
  "task_start": "2026-01-11T06:00:00.000Z",
  "task_end": "2026-01-11T08:00:00.000Z",
  "hm_start": 2500.0,
  "hm_end": 2502.5,
  "activity_id": 1,
  "location_id": 1,
  "code": "TEST-001",
  "result": "Completed successfully",
  "remarks": "Test remarks",
  "order_by": 1
}
```

## Field Descriptions

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `task_start` | string (ISO 8601) | ✅ Yes | Task start datetime in UTC | `"2026-01-11T06:00:00.000Z"` |
| `task_end` | string (ISO 8601) | ✅ Yes | Task end datetime in UTC | `"2026-01-11T08:00:00.000Z"` |
| `activity_id` | integer | ✅ Yes | Activity ID from `/api/eqp/activities` | `1` |
| `location_id` | integer | ✅ Yes | Location ID from `/api/eqp/locations` | `1` |
| `hm_start` | number/null | ❌ No | Hour meter start reading | `2500.0` |
| `hm_end` | number/null | ❌ No | Hour meter end reading | `2502.5` |
| `code` | string/null | ❌ No | Task code | `"TEST-001"` |
| `result` | string/null | ❌ No | Task result | `"Completed"` |
| `remarks` | string/null | ❌ No | Additional remarks | `"Notes here"` |
| `order_by` | integer/null | ❌ No | Organization ID (new field) | `1` |

## Expected Response (Success - 200/201)
```json
{
  "task": {
    "id": 123,
    "task_start": "2026-01-11T06:00:00.000Z",
    "task_end": "2026-01-11T08:00:00.000Z",
    "hm_start": 2500.0,
    "hm_end": 2502.5,
    "activity_id": 1,
    "location_id": 1,
    "code": "TEST-001",
    "result": "Completed successfully",
    "remarks": "Test remarks",
    "order_by": 1,
    "activities": {
      "id": 1,
      "name": "Activity Name"
    },
    "locations": {
      "id": 1,
      "name": "Location Name"
    }
  }
}
```

## Common Error Responses

### 401 Unauthorized
```json
{
  "message": "Unauthenticated."
}
```
**Solution:** Check your Bearer token

### 422 Validation Error
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "activity_id": ["The activity id field is required."],
    "task_start": ["The task start must be a valid date."]
  }
}
```
**Solution:** Check required fields and data types

### 500 Server Error
```json
{
  "message": "Server error - the server failed to fulfil an apparently valid request"
}
```
**Solution:** Check server logs for:
- Database column existence (especially `order_by`)
- Foreign key constraints
- Validation rules

## Testing Steps in Postman

1. **Get your auth token:**
   - First, login via `POST /api/login` with your credentials
   - Copy the token from the response

2. **Set up the request:**
   - Method: `POST`
   - URL: `https://sblport.site/api/eqp/operations/DTGIP-01/tasks`
   - Add Authorization header: `Bearer YOUR_TOKEN`
   - Set Content-Type: `application/json`

3. **Test without order_by first:**
   - Use the minimal request body
   - If this works, the issue is specifically with `order_by`

4. **Test with order_by:**
   - Add `"order_by": 1` to the request
   - If this fails with 500, the backend needs updating

## Debugging Tips

- Check if the `order_by` column exists in the database table
- Verify foreign key constraints (if `order_by` references organizations table)
- Check Laravel validation rules in `EqpOperationController@storeTask`
- Look at server error logs for detailed stack trace
