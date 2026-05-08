from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api.routes import router as api_router
from app.api.auth_routes import auth_router
from app.api.payment_routes import payment_router
from app.database import init_db
import os


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown (nothing to clean up)


app = FastAPI(title="Virtual Try-On API", lifespan=lifespan)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Enable CORS for Flutter mobile/web development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(auth_router, prefix="/api/auth", tags=["Authentication"])
app.include_router(payment_router, prefix="/api/payment", tags=["Payments"])
app.include_router(api_router, prefix="/api", tags=["Virtual Try-On"])


@app.get("/")
async def root():
    return {"message": "Virtual Try-On API is running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, timeout_keep_alive=300)
