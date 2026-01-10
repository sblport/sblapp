# Equipment Operations API - Backend Requirements

## 📋 Required API Endpoints

Your Flutter app needs these endpoints to be implemented in your Laravel backend (`d:\xampp\htdocs\sblport`):

### 1. List Operations (Paginated)
```
GET /api/eqp/operations?page={page}
Headers: Authorization: Bearer {token}

Response:
{
  "data": [
    {
      "id": 1,
      "scrum": "uuid-string",
      "equipment_id": 1,
      "date": "2026-01-10",
      "shift": "Day",
      "user_id": 1,
      "ops_hm_start": 1000.0,
      "ops_hm_end": 1007.0,
      "photo_id": 1,
      "photo2_id": 2,
      "photo_url": "https://s3-url/start-photo.jpg",
      "photo2_url": "https://s3-url/end-photo.jpg",
      "created_at": "2026-01-10T08:00:00",
      "equipment": {
        "id": 1,
        "code": "FL-001",
        "category": "Forklift",
        "brand": "Toyota"
      },
      "user": {
        "id": 1,
        "name": "John Doe"
      },
      "tasks": [
        {
          "id": 1,
          "task_start": "2026-01-10T08:00:00",
          "task_end": "2026-01-10T10:00:00",
          "hm_start": 1000.0,
          "hm_end": 1002.0,
          "activities": { "id": 1, "name": "Loading" },
          "locations": { "id": 1, "name": "Warehouse A" },
          "code": "TRK-001",
          "result": "Completed",
          "remarks": "No issues"
        }
      ]
    }
  ],
  "current_page": 1,
  "last_page": 5,
  "per_page": 20,
  "total": 100
}
```

### 2. Get Single Operation
```
GET /api/eqp/operations/{scrum}
Headers: Authorization: Bearer {token}

Response: Same as single operation object above
```

### 3. Create Operation
```
POST /api/eqp/operations
Headers: 
  Authorization: Bearer {token}
  Content-Type: multipart/form-data

FormData:
  equipment_id: int (required)
  date: string (YYYY-MM-DD, required)
  shift: string (Day|Night, required)
  ops_hm_start: double (required, min: 0)
  photo: File (required, image, max 5MB)

Response:
{
  "message": "Operation created successfully",
  "operation": { ... operation object ... }
}
```

### 4. Add Task to Operation
```
POST /api/eqp/operations/{scrum}/tasks
Headers: 
  Authorization: Bearer {token}
  Content-Type: application/json

JSON Body:
{
  "task_start": "2026-01-10T08:00:00",
  "task_end": "2026-01-10T10:00:00",
  "hm_start": 1000.0,
  "hm_end": 1002.0,
  "activity_id": 1,
  "location_id": 1,
  "code": "TRK-001",
  "result": "Task completed",
  "remarks": "Notes here"
}

Response:
{
  "message": "Task added successfully",
  "task": { ... task object ... }
}
```

### 5. Finish Operation
```
POST /api/eqp/operations/{scrum}/finish
Headers: 
  Authorization: Bearer {token}
  Content-Type: multipart/form-data

FormData:
  ops_hm_end: double (required, must be >= ops_hm_start)
  photo2: File (required, image, max 5MB)

Response:
{
  "message": "Operation finished successfully",
  "operation": { ... operation object ... }
}
```

### 6. Get Equipment List
```
GET /api/eqp/equipment
Headers: Authorization: Bearer {token}

Response:
[
  {
    "id": 1,
    "code": "FL-001",
    "category": "Forklift",
    "brand": "Toyota"
  },
  ...
]
```

### 7. Get Activities List
```
GET /api/eqp/activities
Headers: Authorization: Bearer {token}

Response:
[
  {
    "id": 1,
    "name": "Loading"
  },
  ...
]
```

### 8. Get Locations List
```
GET /api/eqp/locations
Headers: Authorization: Bearer {token}

Response:
[
  {
    "id": 1,
    "name": "Warehouse A"
  },
  ...
]
```

---

## 🗄️ Database Tables Needed

### eqp_operations
```sql
id - bigint, primary key
scrum - string (UUID), unique
equipment_id - foreign key to equipment table
date - date
shift - enum('Day', 'Night')
user_id - foreign key to users
ops_hm_start - decimal(10,2)
ops_hm_end - decimal(10,2), nullable
photo_id - foreign key to files/photos table, nullable
photo2_id - foreign key to files/photos table, nullable
created_at, updated_at - timestamps
```

### eqp_operation_tasks
```sql
id - bigint, primary key
operation_id - foreign key to eqp_operations
task_start - datetime
task_end - datetime
hm_start - decimal(10,2), nullable
hm_end - decimal(10,2), nullable
activity_id - foreign key to eqp_activities
location_id - foreign key to eqp_locations
code - string, nullable
result - text, nullable
remarks - text, nullable
created_at, updated_at - timestamps
```

### eqp_activities
```sql
id - bigint, primary key
name - string
created_at, updated_at - timestamps
```

### eqp_locations
```sql
id - bigint, primary key
name - string
created_at, updated_at - timestamps
```

---

## 🔑 Access Control

Operations should be restricted to users with `DeptId = 9` (Engineering Department).

Add middleware or policy check in your controller:
```php
public function __construct()
{
    $this->middleware('auth:sanctum');
    $this->middleware(function ($request, $next) {
        if (auth()->user()->DeptId !== 9) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        return $next($request);
    });
}
```

---

## ✅ Quick Test Checklist

Once you implement the backend:

1. [ ] `/api/eqp/equipment` returns equipment list
2. [ ] `/api/eqp/activities` returns activities list
3. [ ] `/api/eqp/locations` returns locations list
4. [ ] `/api/eqp/operations` returns empty array or operations list
5. [ ] POST `/api/eqp/operations` creates new operation with photo upload
6. [ ] POST `/api/eqp/operations/{scrum}/tasks` adds task
7. [ ] POST `/api/eqp/operations/{scrum}/finish` finishes operation
8. [ ] CORS is enabled for `localhost` origin
9. [ ] Bearer token authentication works
10. [ ] DeptId=9 access restriction works

---

## 📞 Need Help?

If you need:
- **Migration files** for the database tables
- **Full Laravel controller code** for EqpOperationController
- **Route definitions** for routes/api.php
- **Model relationships** setup

Just let me know and I'll provide the complete Laravel backend code!
