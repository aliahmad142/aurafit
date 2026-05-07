# Virtual Try-On Full-Stack Application

This project consists of a Flutter mobile application and a FastAPI backend that allows users to virtually try on clothes using AI (currently mocked).

## Folder Structure

```
/
├── backend/                # FastAPI Backend
│   ├── app/
│   │   ├── api/           # API Routes
│   │   └── services/      # Business logic & AI Integration
│   ├── static/            # Uploaded and Result images
│   └── main.py            # Entry point
└── frontend/               # Flutter Frontend
    ├── lib/
    │   ├── models/        # Data models
    │   ├── providers/     # State Management
    │   ├── screens/       # UI Screens
    │   ├── services/      # API Services
    │   ├── utils/         # Constants & Helpers
    │   └── widgets/       # Reusable Components
    └── pubspec.yaml        # Dependencies
```

## Setup Instructions

### 1. Backend (FastAPI)

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the server:
   ```bash
   python main.py
   ```
   The backend will start at `http://localhost:8000`.

### 2. Frontend (Flutter)

1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Update API Base URL (if needed):
   Edit `lib/utils/constants.dart` to match your local machine's IP if testing on a physical device or different emulator.
4. Run the app:
   ```bash
   flutter run
   ```

## Google Vertex AI Integration

To integrate the real Google Vertex AI Virtual Try-On:

1. Open `backend/app/services/vto_service.py`.
2. Locate the `PLACEHOLDER FOR GOOGLE VERTEX AI INTEGRATION` section.
3. Install the Vertex AI SDK: `pip install google-cloud-aiplatform`.
4. Use the `ImageGenerationModel` or the specific VTO model available in your region.
5. Replace the mock PIL logic with the API call to Vertex AI.

Example Integration:
```python
from vertexai.preview.vision_models import ImageGenerationModel

# ... inside process_try_on ...
model = ImageGenerationModel.from_pretrained("image-generation@006")
# Use the VTO specific parameters when available
# result = model.generate_images(...)
```

## API Sample

### Request
- **Endpoint:** `POST /api/try-on`
- **Body:** `multipart/form-data`
  - `person_image`: (File)
  - `cloth_image`: (File)

### Response
```json
{
  "success": true,
  "message": "Try-on generated successfully",
  "result_image_url": "/static/results/result_uuid.png",
  "result_image_base64": "..."
}
```
