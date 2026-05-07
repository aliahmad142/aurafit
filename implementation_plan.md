# Data Privacy & Local Encryption for User Images

## Goal

1. **Zero images on server** — Backend processes images entirely in-memory, then discards them. No files saved to disk.
2. **Encrypted local storage** — All history images on the user's phone are AES-256 encrypted at rest.
3. **Data lost on uninstall** — Accepted. No cloud backup needed.

## Architecture

```mermaid
sequenceDiagram
    participant Phone as 📱 Flutter App
    participant Server as 🖥️ Backend (In-Memory Only)
    participant Fashn as ☁️ Fashn.ai

    Phone->>Server: Upload person + cloth (multipart)
    Server->>Server: Read bytes into memory (NO disk write)
    Server->>Fashn: Send compressed base64 to API
    Fashn-->>Server: Return result URL
    Server->>Server: Download result into memory
    Server-->>Phone: Return result_image_base64
    Server->>Server: Discard all image data

    Phone->>Phone: Encrypt images with AES-256
    Phone->>Phone: Save .enc files to local storage
    Phone->>Phone: Decrypt on-the-fly for display
```

---

## Proposed Changes

### Component 1: Backend — In-Memory Processing

#### [MODIFY] [routes.py](file:///d:/Virtual%20Try%20on%20me/backend/app/api/routes.py)
- Read `UploadFile` bytes directly in memory, pass raw `bytes` to VTO service.
- Remove `UPLOAD_DIR`, file paths, and all `open(..., "wb")` disk writes.
- Remove the `finally` block (nothing to clean up).

#### [MODIFY] [vto_service.py](file:///d:/Virtual%20Try%20on%20me/backend/app/services/vto_service.py)
- Change `process_try_on(person_image_path, cloth_image_path)` → `process_try_on(person_bytes, cloth_bytes)`.
- Change `_compress_image(file_path)` → `_compress_image(image_bytes)` (work from bytes, not file).
- Change `_file_to_data_uri(file_path)` → `_bytes_to_data_uri(image_bytes)`.
- **Stop saving result** to `static/results/`. Download Fashn result into memory, base64-encode, return.
- Remove `upload_dir` / `result_dir`, `os.makedirs`, and `result_image_url` from response.

#### [MODIFY] [main.py](file:///d:/Virtual%20Try%20on%20me/backend/main.py)
- Remove `os.makedirs("static/uploads")` and `os.makedirs("static/results")`.
- Remove `StaticFiles` mount.
- Remove `from fastapi.staticfiles import StaticFiles`.

---

### Component 2: Frontend — AES-256 Encryption Service

#### Add `encrypt: ^5.0.3` to [pubspec.yaml](file:///d:/Virtual%20Try%20on%20me/frontend/pubspec.yaml)

#### [NEW] [encryption_service.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/services/encryption_service.dart)
Singleton service:
- **`init()`** — On first launch, generates a random 32-byte AES key + stores it in `flutter_secure_storage`. On subsequent launches, retrieves the stored key.
- **`encryptBytes(Uint8List)`** → `Uint8List` — Generates a random 16-byte IV, encrypts with AES-256-CBC, prepends IV to ciphertext.
- **`decryptBytes(Uint8List)`** → `Uint8List` — Extracts IV from first 16 bytes, decrypts the rest.

> [!NOTE]
> The key is a random device-unique key stored in `flutter_secure_storage` (Android Keystore / iOS Keychain). It is NOT derived from the password since we don't need cross-device sync. This is simpler and more secure.

---

### Component 3: Frontend — Encrypted File Storage

#### [MODIFY] [database_helper.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/services/database_helper.dart)
- `saveImageToFile(base64Str, prefix)` → decode base64 → **encrypt** → write `.enc` file.
- **[NEW]** `readImageFile(String path)` → read `.enc` file → **decrypt** → return `Uint8List` for display.
- **[NEW]** `decryptToTempFile(String encPath)` → decrypt → write to temp dir as `.png` → return temp path (for Gallery save / Share).

---

### Component 4: Frontend — UI Updates

#### [MODIFY] [history_screen.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/screens/history_screen.dart)
- Replace `Image.file(File(path))` with a `FutureBuilder` that calls `DatabaseHelper.readImageFile(path)` and displays `Image.memory(decryptedBytes)`.

#### [MODIFY] [history_detail_screen.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/screens/history_detail_screen.dart)
- Same decrypt-before-display pattern for result + source thumbnails.
- `_saveToGallery()`: decrypt to temp file → `Gal.putImage(tempPath)`.
- `_shareImage()`: decrypt to temp file → `Share.shareXFiles()`.

#### [MODIFY] [result_screen.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/screens/result_screen.dart)
- Remove the `Image.network` fallback that uses `resultImageUrl` (no longer returned by backend).

#### [MODIFY] [try_on_response.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/models/try_on_response.dart)
- Remove `resultImageUrl` field.

---

### Component 5: Frontend — Initialization

#### [MODIFY] [main.dart](file:///d:/Virtual%20Try%20on%20me/frontend/lib/main.dart)
- Initialize `EncryptionService` at app startup (before any history is accessed).

---

## Summary of File Changes

| File | Action | What Changes |
|---|---|---|
| `backend/app/api/routes.py` | MODIFY | In-memory bytes, no disk I/O |
| `backend/app/services/vto_service.py` | MODIFY | Bytes-based processing, no file save |
| `backend/main.py` | MODIFY | Remove static file serving |
| `frontend/pubspec.yaml` | MODIFY | Add `encrypt` package |
| `frontend/lib/main.dart` | MODIFY | Init encryption service |
| `frontend/lib/services/encryption_service.dart` | NEW | AES-256-CBC encrypt/decrypt |
| `frontend/lib/services/database_helper.dart` | MODIFY | Encrypt on save, decrypt on read |
| `frontend/lib/models/try_on_response.dart` | MODIFY | Remove `resultImageUrl` |
| `frontend/lib/screens/history_screen.dart` | MODIFY | Decrypt before display |
| `frontend/lib/screens/history_detail_screen.dart` | MODIFY | Decrypt before display/share/save |
| `frontend/lib/screens/result_screen.dart` | MODIFY | Remove network image fallback |

## Verification Plan

### Automated
- `flutter pub get` — dependencies resolve
- `flutter analyze` — no static errors
- Start backend → confirm `static/uploads/` and `static/results/` are NOT created

### Manual
1. Do a try-on → result displays correctly
2. Check `static/` on server → **empty** (no images)
3. Open history → images display correctly (decrypted in-memory)
4. Browse device files → `history_images/` contains only `.enc` files (unreadable)
5. "Save to Gallery" from history → works (decrypted to temp → saved)
6. "Share" from history → works
