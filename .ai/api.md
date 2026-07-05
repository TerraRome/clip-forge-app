# AI YouTube Clipper — API Documentation

## Base URL

```
Development: http://localhost:8000/api
Production:  https://api.klip.example.com/api
```

## Standard Response Envelope

### Success

```json
{
  "data": { ... },
  "meta": {
    "request_id": "req_abc123",
    "timestamp": "2026-07-04T12:00:00Z"
  }
}
```

### Error

```json
{
  "error": {
    "code": "INVALID_URL",
    "message": "The provided URL is not a valid YouTube video URL.",
    "details": { "url": "https://not-youtube.com/watch?v=123" },
    "request_id": "req_def456"
  }
}
```

---

## Endpoints

---

### POST /api/projects

Create a new project. Returns a project ID for subsequent operations.

#### Request

```
POST /api/projects
Content-Type: application/json
```

```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "clip_count": 3
}
```

| Field      | Type    | Required | Default | Constraints                      |
| ---------- | ------- | -------- | ------- | -------------------------------- |
| url        | string  | yes      | —       | Must be valid YouTube URL format |
| clip_count | integer | no       | 3       | One of: 1, 3, 5, 10              |

**URL Format Accepted:**

- `https://www.youtube.com/watch?v={id}`
- `https://youtu.be/{id}`
- `https://www.youtube.com/shorts/{id}`
- `https://m.youtube.com/watch?v={id}`

**URL parameters stripped (silently):**

- `list` (playlist param)
- `t` (timestamp)
- `si` (sharing identifier)

#### Response: 201 Created

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "clip_count": 3,
    "status": "pending",
    "progress": 0,
    "created_at": "2026-07-04T12:00:00Z"
  },
  "meta": {
    "request_id": "req_abc123",
    "timestamp": "2026-07-04T12:00:00Z"
  }
}
```

#### Errors

| Status | Code               | Message                                     |
| ------ | ------------------ | ------------------------------------------- |
| 400    | INVALID_URL        | The provided URL is not a valid YouTube URL |
| 400    | INVALID_CLIP_COUNT | clip_count must be one of: 1, 3, 5, 10      |
| 422    | VALIDATION_ERROR   | Request body does not match schema          |
| 500    | INTERNAL_ERROR     | An unexpected error occurred                |

#### Example: Validation Error (400)

```json
{
  "error": {
    "code": "INVALID_URL",
    "message": "The provided URL is not a valid YouTube URL.",
    "details": { "url": "not-a-url" },
    "request_id": "req_def456"
  }
}
```

---

### POST /api/projects/{project_id}/process

Start processing a project.

#### Request

```
POST /api/projects/{project_id}/process
```

**Path Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| project_id | string | yes | Project ID returned from POST /projects |

#### Response: 202 Accepted

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "status": "processing",
    "progress": 0,
    "stage": "queued",
    "message": "Processing started"
  },
  "meta": {
    "request_id": "req_ghi789",
    "timestamp": "2026-07-04T12:00:05Z"
  }
}
```

#### Errors

| Status | Code           | Message                                    |
| ------ | -------------- | ------------------------------------------ |
| 404    | NOT_FOUND      | Project with id 'proj_xyz' not found       |
| 409    | CONFLICT       | Project is already processing or completed |
| 500    | INTERNAL_ERROR | Failed to start processing                 |

#### Example: 404

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Project with id 'proj_xyz' not found",
    "details": { "project_id": "proj_xyz" },
    "request_id": "req_jkl012"
  }
}
```

---

### GET /api/projects/{project_id}

Get project status and processing progress. Poll this endpoint.

#### Request

```
GET /api/projects/{project_id}
```

#### Response: 200 OK

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "clip_count": 3,
    "status": "processing",
    "progress": 65,
    "stage": "detecting_highlights",
    "message": "Analyzing transcript for best moments...",
    "created_at": "2026-07-04T12:00:00Z",
    "updated_at": "2026-07-04T12:03:15Z",
    "clips": []
  },
  "meta": {
    "request_id": "req_mno345",
    "timestamp": "2026-07-04T12:03:15Z"
  }
}
```

#### Status Values

| Status               | Progress | Description                                  |
| -------------------- | -------- | -------------------------------------------- |
| pending              | 0        | Project created, not yet processing          |
| downloading          | 0-15     | Downloading video from YouTube               |
| extracting_audio     | 15-30    | Extracting audio track                       |
| transcribing         | 30-50    | Running Whisper transcription                |
| detecting_highlights | 50-70    | Analyzing transcript for highlights          |
| rendering            | 70-95    | Generating vertical clips with subtitles     |
| done                 | 100      | All clips ready for download                 |
| error                | -1       | Processing failed, see `error_message` field |
| cancelled            | -1       | Processing was cancelled by user             |

#### Response (done)

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "clip_count": 3,
    "status": "done",
    "progress": 100,
    "stage": null,
    "message": "All clips generated successfully",
    "created_at": "2026-07-04T12:00:00Z",
    "updated_at": "2026-07-04T12:04:30Z",
    "clips": [
      {
        "index": 0,
        "filename": "proj_a1b2c3d4_clip_0.mp4",
        "start": 12.5,
        "end": 52.3,
        "size_bytes": 18472931
      },
      {
        "index": 1,
        "filename": "proj_a1b2c3d4_clip_1.mp4",
        "start": 124.1,
        "end": 168.7,
        "size_bytes": 21900321
      },
      {
        "index": 2,
        "filename": "proj_a1b2c3d4_clip_2.mp4",
        "start": 312.0,
        "end": 356.8,
        "size_bytes": 20184932
      }
    ]
  },
  "meta": {
    "request_id": "req_pqr678",
    "timestamp": "2026-07-04T12:04:30Z"
  }
}
```

#### Response (error)

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "clip_count": 3,
    "status": "error",
    "progress": -1,
    "stage": null,
    "message": "Processing failed",
    "error_message": "Video download failed: video is private or deleted",
    "created_at": "2026-07-04T12:00:00Z",
    "updated_at": "2026-07-04T12:01:30Z",
    "clips": []
  },
  "meta": {
    "request_id": "req_stu901",
    "timestamp": "2026-07-04T12:01:30Z"
  }
}
```

#### Errors

| Status | Code      | Message           |
| ------ | --------- | ----------------- |
| 404    | NOT_FOUND | Project not found |

---

### POST /api/projects/{project_id}/cancel

Cancel an in-progress processing job.

#### Request

```
POST /api/projects/{project_id}/cancel
```

#### Response: 200 OK

```json
{
  "data": {
    "id": "proj_a1b2c3d4",
    "status": "cancelled",
    "message": "Processing cancelled"
  },
  "meta": {
    "request_id": "req_vwx234",
    "timestamp": "2026-07-04T12:02:00Z"
  }
}
```

#### Errors

| Status | Code           | Message                               |
| ------ | -------------- | ------------------------------------- |
| 404    | NOT_FOUND      | Project not found                     |
| 409    | CONFLICT       | Project is not in a cancellable state |
| 500    | INTERNAL_ERROR | Failed to cancel project              |

---

### GET /api/download/{project_id}

Download all generated clips as a ZIP file. Available when status is `done`.

#### Request

```
GET /api/download/{project_id}
```

#### Response: 200 OK

**Headers:**

```
Content-Type: application/zip
Content-Disposition: attachment; filename="klips_proj_a1b2c3d4.zip"
Content-Length: 58382930
```

**Body:** Binary ZIP stream

#### ZIP Contents

```
klips_proj_a1b2c3d4/
├── clip_0.mp4
├── clip_1.mp4
├── clip_2.mp4
└── manifest.json
```

**manifest.json**

```json
{
  "project_id": "proj_a1b2c3d4",
  "source_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "created_at": "2026-07-04T12:04:30Z",
  "clips": [
    { "index": 0, "filename": "clip_0.mp4", "start": 12.5, "end": 52.3 },
    { "index": 1, "filename": "clip_1.mp4", "start": 124.1, "end": 168.7 },
    { "index": 2, "filename": "clip_2.mp4", "start": 312.0, "end": 356.8 }
  ],
  "format": {
    "width": 1080,
    "height": 1920,
    "codec": "H.264",
    "fps": 30,
    "subtitle": "burned-in"
  }
}
```

#### Errors

| Status | Code           | Message                                        |
| ------ | -------------- | ---------------------------------------------- |
| 404    | NOT_FOUND      | Project not found                              |
| 409    | CONFLICT       | Project not yet completed (status: processing) |
| 409    | CONFLICT       | Project has no completed clips                 |
| 500    | INTERNAL_ERROR | Failed to generate ZIP archive                 |

#### Example: 409

```json
{
  "error": {
    "code": "CONFLICT",
    "message": "Project has no completed clips",
    "details": {
      "project_id": "proj_a1b2c3d4",
      "status": "processing",
      "progress": 45
    },
    "request_id": "req_yz5678"
  }
}
```

---

### GET /api/health

Health check for load balancers and monitoring.

#### Request

```
GET /api/health
```

#### Response: 200 OK

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "active_jobs": 2,
  "max_jobs": 10
}
```

---

## HTTP Status Codes Summary

| Code | Description                         |
| ---- | ----------------------------------- |
| 200  | Success                             |
| 201  | Created                             |
| 202  | Accepted (processing started)       |
| 400  | Bad Request (validation error)      |
| 404  | Not Found                           |
| 409  | Conflict (invalid state transition) |
| 422  | Unprocessable Entity (schema error) |
| 429  | Too Many Requests (rate limit)      |
| 500  | Internal Server Error               |
| 503  | Service Unavailable                 |

## Rate Limiting

**Note:** Rate limiting is not implemented for MVP. It will be added before production deployment.

## Client Polling Recommendation

```dart
// Flutter client pseudocode
Future<void> pollUntilDone(String projectId) async {
  const maxAttempts = 120;  // 120 * 3s = 6 min timeout
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await Future.delayed(const Duration(seconds: 3));
    final response = await api.getProject(projectId);
    if (response.status == 'done' || response.status == 'error') {
      return;
    }
  }
  throw TimeoutException('Processing took too long');
}
```
