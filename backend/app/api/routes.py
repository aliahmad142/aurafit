from fastapi import APIRouter, UploadFile, File, HTTPException, Form, Depends
import os
import aiosqlite
from app.database import get_db
from app.services.vto_service import vto_service
from app.dependencies import get_current_user

router = APIRouter()

@router.post("/try-on")
async def try_on(
    person_image: UploadFile = File(...),
    cloth_image: UploadFile = File(...),
    category: str = Form("auto"),
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    # Check credits
    if current_user["credits"] <= 0:
        raise HTTPException(
            status_code=403, 
            detail="You have exhausted your credits. Please upgrade your plan."
        )

    # Validate file types
    allowed_extensions = [".jpg", ".jpeg", ".png"]
    
    person_ext = os.path.splitext(person_image.filename)[1].lower()
    cloth_ext = os.path.splitext(cloth_image.filename)[1].lower()
    
    if person_ext not in allowed_extensions or cloth_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail="Invalid file type. Only JPG, JPEG, and PNG are allowed."
        )

    try:
        # Read files into memory
        person_bytes = await person_image.read()
        cloth_bytes = await cloth_image.read()

        # Process VTO
        result = await vto_service.process_try_on(person_bytes, cloth_bytes, category=category)
        
        if result.get("success"):
            # Decrement credits
            await db.execute(
                "UPDATE users SET credits = credits - 1 WHERE id = ?",
                (current_user["id"],)
            )
            await db.commit()
            
            # Add updated credits to result
            result["new_credits"] = current_user["credits"] - 1
        
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

