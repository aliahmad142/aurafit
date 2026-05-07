# AuraFit Backend Deployment Guide (Railway.app)

Railway is the easiest way to host your FastAPI backend with a persistent database.

## 1. Prepare your Repository
Make sure your `backend` folder has these files:
- `main.py`
- `requirements.txt`
- `Procfile` (I will create this for you)
- `runtime.txt` (Specifies Python version)

## 2. Push to GitHub
1. Create a private repository on GitHub named `aurafit-backend`.
2. Push your backend code:
   ```bash
   git init
   git add .
   git commit -m "initial deployment"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

## 3. Deploy on Railway
1. Go to [Railway.app](https://railway.app/) and login with GitHub.
2. Click **New Project** > **Deploy from GitHub repo**.
3. Select your `aurafit-backend` repo.
4. **Variables**: Click the "Variables" tab and add everything from your `.env` file:
   - `REPLICATE_API_TOKEN`
   - `FASHN_API_KEY`
   - `JWT_SECRET_KEY`
   - `MAIL_USERNAME`
   - `MAIL_PASSWORD`
   - etc.

## 4. Setup Persistence (For SQLite)
1. In Railway, click **Settings** > **Volumes**.
2. Click **Add Volume**.
3. Name: `data_vol`
4. Mount Path: `/app/data` (This ensures your `app.db` is never deleted).

## 5. Update Flutter
Once Railway gives you a URL (e.g., `https://aurafit-production.up.railway.app`):
1. Open `frontend/lib/utils/constants.dart`.
2. Change `baseUrl` to your new Railway URL.
3. Rebuild your APK.

## 6. Update Google Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Update your **OAuth Consent Screen** and **Client IDs** with your new production URL so Google knows the requests are authorized.
