# TRAINING MODULE - API DOCUMENTATION

## Base URL
```
http://localhost/tnd_system/backend-web/api/training/
```

## Authentication
All endpoints require authentication. Include session cookie or Bearer token.

---

## API ENDPOINTS

### 1. Get Training Checklists
Get all active training checklists.

**Endpoint:** `GET /checklists.php`

**Response:**
```json
{
  "success": true,
  "data": {
    "checklists": [
      {
        "id": 1,
        "name": "InHouse Training Form - Hospitality & Service",
        "description": "Comprehensive training checklist",
        "is_active": 1,
        "total_categories": 4,
        "total_points": 22
      }
    ],
    "total": 1
  }
}
```

---

### 2. Get Checklist Detail
Get checklist with categories and training points.

**Endpoint:** `GET /checklist-detail.php?id={checklist_id}`

**Parameters:**
- `id` (required): Checklist ID

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "InHouse Training Form",
    "categories": [
      {
        "id": 1,
        "name": "NILAI HOSPITALITY",
        "order_index": 1,
        "points": [
          {
            "id": 1,
            "question": "Staff mengerti pentingnya hospitality",
            "order_index": 1
          }
        ]
      }
    ]
  }
}
```

---

### 3. Start Training Session
Create a new training session.

**Endpoint:** `POST /session-start.php`

**Request Body:**
```json
{
  "outlet_id": 1,
  "checklist_id": 1,
  "session_date": "2025-10-20",
  "start_time": "09:00:00",
  "notes": "Morning session"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Training session started successfully",
    "session": {
      "id": 1,
      "outlet_id": 1,
      "outlet_name": "Latte Story",
      "trainer_id": 5,
      "trainer_name": "John Trainer",
      "checklist_id": 1,
      "checklist_name": "InHouse Training Form",
      "session_date": "2025-10-20",
      "start_time": "09:00:00",
      "status": "ongoing"
    }
  }
}
```

---

### 4. Add Participants
Add staff participants to training session.

**Endpoint:** `POST /participants-add.php`

**Request Body:**
```json
{
  "session_id": 1,
  "participants": [
    {
      "staff_name": "Ahmad Barista",
      "position": "Barista",
      "phone": "081234567890",
      "notes": "Experienced staff"
    },
    {
      "staff_name": "Budi Santoso",
      "position": "Waiter"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Participants added successfully",
    "participants": [
      {
        "id": 1,
        "staff_name": "Ahmad Barista",
        "position": "Barista"
      }
    ],
    "total": 2
  }
}
```

---

### 5. Save Training Responses
Save evaluation scores for training points.

**Endpoint:** `POST /responses-save.php`

**Request Body:**
```json
{
  "session_id": 1,
  "responses": [
    {
      "training_point_id": 1,
      "participant_id": 1,
      "score": 5,
      "notes": "Excellent understanding"
    },
    {
      "training_point_id": 2,
      "participant_id": 1,
      "score": 4,
      "notes": "Good but can improve"
    }
  ]
}
```

---

### 6. Complete Training Session
Mark training session as completed.

**Endpoint:** `POST /session-complete.php`

**Request Body:**
```json
{
  "session_id": 1,
  "end_time": "11:30:00",
  "notes": "Training completed successfully"
}
```

---

### 7. Get Training Sessions List
Get list of training sessions with filters.

**Endpoint:** `GET /sessions-list.php`

**Query Parameters:**
- `trainer_id` (optional): Filter by trainer
- `outlet_id` (optional): Filter by outlet
- `status` (optional): Filter by status (ongoing, completed, etc.)
- `date_from` (optional): Start date (Y-m-d)
- `date_to` (optional): End date (Y-m-d)
- `limit` (optional): Results per page (default: 20)
- `offset` (optional): Offset for pagination (default: 0)

**Response:**
```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": 1,
        "outlet_name": "Latte Story",
        "trainer_name": "John Trainer",
        "checklist_name": "InHouse Training Form",
        "session_date": "2025-10-20",
        "start_time": "09:00:00",
        "end_time": "11:30:00",
        "total_staff": 5,
        "average_score": 4.5,
        "status": "completed"
      }
    ],
    "total": 1,
    "limit": 20,
    "offset": 0
  }
}
```

---

### 8. Get Training Session Detail
Get detailed information about a training session.

**Endpoint:** `GET /session-detail.php?id={session_id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "session": {
      "id": 1,
      "outlet_name": "Latte Story",
      "trainer_name": "John Trainer",
      "session_date": "2025-10-20",
      "total_staff": 5,
      "average_score": 4.5,
      "status": "completed"
    },
    "participants": [
      {
        "id": 1,
        "staff_name": "Ahmad Barista",
        "position": "Barista",
        "average_score": 4.7
      }
    ],
    "categories": [
      {
        "id": 1,
        "name": "NILAI HOSPITALITY",
        "average_score": 4.5,
        "points": [
          {
            "id": 1,
            "question": "Staff mengerti...",
            "responses": [
              {
                "participant_name": "Ahmad",
                "score": 5
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

### 9. Get Training Statistics
Get training statistics for dashboard.

**Endpoint:** `GET /stats.php`

**Query Parameters:**
- `trainer_id` (optional): Filter by trainer
- `period` (optional): today, week, month, year (default: month)

**Response:**
```json
{
  "success": true,
  "data": {
    "total_sessions": 24,
    "total_staff_trained": 120,
    "average_score": 4.3,
    "sessions_this_month": 8,
    "top_performing_category": "Hospitality",
    "trend": [
      {
        "week": "W1",
        "average_score": 4.2,
        "sessions": 5
      }
    ]
  }
}
```

---

### 10. Get Training PDF Data
Get data for PDF generation.

**Endpoint:** `GET /pdf-data.php?session_id={session_id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "session": {...},
    "participants": [...],
    "categories": [...],
    "responses": [...]
  }
}
```

---

## Error Responses

All endpoints return error in this format:

```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "code": 400
  }
}
```

**Common Error Codes:**
- `400` - Bad Request (missing parameters)
- `401` - Unauthorized (not logged in)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `405` - Method Not Allowed
- `500` - Internal Server Error

---

## Status: Phase 2 Complete ✅

**All 10 Backend APIs Completed:**
1. ✅ checklists.php - Get all training checklists
2. ✅ checklist-detail.php - Get checklist details with categories/points
3. ✅ session-start.php - Create new training session
4. ✅ participants-add.php - Add participants to session
5. ✅ responses-save.php - Save evaluation responses (scoring 1-5)
6. ✅ session-complete.php - Mark session as completed, calculate averages
7. ✅ sessions-list.php - Get filtered list of sessions with pagination
8. ✅ session-detail.php - Get full session details
9. ✅ stats.php - Get training statistics dashboard
10. ✅ pdf-data.php - Get data for PDF generation

**Database:**
- ✅ 7 tables created (training_checklists, training_categories, training_points, training_sessions, training_participants, training_responses, training_photos)
- ✅ Sample data seeded
- ✅ Users table updated with trainer role

**Next Phase (Phase 3):**
- Build Flutter models (TrainingSessionModel, TrainingParticipantModel, etc.)
- Create TrainingService for API calls
- Implement training screens UI

---

**Date:** 20 Oktober 2025  
**Version:** 2.0.0  
**Phase 2:** COMPLETE ✅
