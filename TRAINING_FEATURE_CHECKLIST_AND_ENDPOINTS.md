# Training Feature Checklist and Endpoints

## Overview
This document provides a comprehensive list of training features, checklists, and backend endpoints in the TND System.

## Training Feature Checklist

### 1. Training Checklists Management
- [ ] Create new training checklist
- [x] View all training checklists
- [ ] Edit existing training checklist
- [x] Delete training checklist
- [x] Add categories to a checklist
- [x] Add checklist items/points to categories
- [x] Reorder checklist items
- [ ] Activate/deactivate checklists

### 2. Training Schedule Management
- [ ] Create new training schedule
- [x] View scheduled training sessions
- [ ] Filter schedules by date/status
- [ ] Update schedule details
- [x] Cancel scheduled sessions
- [ ] Assign trainers to sessions
- [ ] Assign outlets to sessions

### 3. Training Session Management
- [x] Start a training session
- [x] Add participants to session
- [x] Complete a training session
- [x] View session details
- [ ] Manage session participants
- [x] Update session status (scheduled → ongoing → completed)

### 4. Training Evaluation & Scoring
- [x] Evaluate training participants
- [x] Save evaluation scores
- [x] Add comments to evaluations
- [x] Capture training responses
- [ ] Calculate average scores
- [ ] Generate evaluation reports

### 5. Training Documentation
- [x] Upload training photos
- [x] Add signatures (trainer and crew leader)
- [ ] Add session notes
- [x] Generate training certificates
- [x] Export training reports (PDF)

### 6. Training Materials
- [x] Get training materials
- [x] Upload training materials (PDF, PPTX, etc.)

### 7. Training Analytics & Statistics
- [x] View training statistics
- [ ] Filter by time period
- [ ] View completion rates
- [ ] View average scores
- [ ] Export analytics data

## Backend Endpoints

### Training Checklists Endpoints

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/checklists.php` | GET | Get all active training checklists | None | List of checklists with categories and points |
| `/api/training/checklist-detail.php?id={id}` | GET | Get detailed checklist with categories and items | id (integer) | Single checklist with all categories and items |
| `/api/training/checklist-save.php` | POST | Create or update training checklist | name, description, categories[], points[] | Success/error message |

### Training Sessions Endpoints

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/session-start.php` | POST | Create or start training session | outlet_id, checklist_id, session_date, start_time, notes | Created session details |
| `/api/training/sessions-list.php` | GET | Get list of training sessions | status, outlet_id, trainer_id, date_from, date_to | List of sessions with pagination |
| `/api/training/session-detail.php?id={id}` | GET | Get detailed session information | id (integer) | Complete session details with participants and responses |
| `/api/training/session-complete.php` | POST | Complete training session | session_id, end_time, notes | Success/error message |

### Training Participants & Responses

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/participants-add.php` | POST | Add participants to session | session_id, participants[] | Success/error message |
| `/api/training/responses-save.php` | POST | Save evaluation scores | session_id, responses[] | Statistics and saved count |
| `/api/training/photo-upload.php` | POST (multipart) | Upload training photos | session_id, photo_file | Photo URL/path |

### Training Signatures & Reports

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/signatures-save.php` | POST | Save trainer/leader signatures | session_id, trainer_signature, leader_signature | Success/error message |
| `/api/training/pdf-data.php?session_id={id}` | GET | Get data for PDF generation | session_id (integer) | All session data in a structured format |
| `/api/training/pdf-generate.php` | POST | Generate training certificate PDF | session_id, data | PDF file |

### Training Analytics

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/stats.php?period={period}` | GET | Get training statistics | period (day/week/month) | Training metrics and KPIs |

### Training Materials

| Endpoint | Method | Description | Parameters | Response |
|----------|--------|-------------|------------|----------|
| `/api/training/materials.php` | GET | Get training materials | None | List of available materials |
| `/api/training/materials-upload.php` | POST (multipart) | Upload training materials | material_file | Upload success and file info |

## Frontend Components

### Flutter Mobile Components

#### Training Schedules
- `training_schedule_form_screen.dart` - Create new training schedules
- `training_schedule_list_screen.dart` - View and manage scheduled sessions
- `training_session_checklist_screen.dart` - Complete training evaluations

#### Training Services
- `training_service.dart` - API service for all training operations
- `training_models.dart` - All training-related data models

#### Training Models
- `trainer_model.dart` - Trainer user information
- `training_schedule_model.dart` - Scheduled session data
- `training_checklist_category_model.dart` - Checklist category information
- `training_checklist_item_model.dart` - Individual checklist items
- `training_session_model.dart` - Active training session data
- `training_response_model.dart` - Training evaluation responses
- `training_signature_model.dart` - Signature information

## Data Models

### Training Session Status Flow
```
scheduled → ongoing → completed
```

### Core Database Tables
- `training_checklists` - Main training checklists
- `training_categories` - Categories within checklists
- `training_points` - Individual items within categories
- `training_sessions` - Scheduled/ongoing/completed training sessions
- `training_participants` - Participants in each session
- `training_responses` - Evaluation scores for each participant
- `training_photos` - Training session photos
- `training_signatures` - Trainer and leader signatures

## Authentication Requirements
- Most training endpoints require authentication
- Some endpoints have role-based access (admin/supervisor/trainer)
- Session-based authentication is typically used
- Web and mobile apps share the same user system

## Error Handling
- All endpoints return consistent JSON responses
- Success responses include `success: true`
- Error responses include `success: false` and error message
- HTTP status codes follow standard conventions

## Testing Considerations
- Test each endpoint with valid and invalid parameters
- Verify authentication requirements
- Test role-based access controls
- Verify data validation for all inputs
- Test error handling for edge cases