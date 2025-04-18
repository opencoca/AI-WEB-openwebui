from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from pydantic import BaseModel
import os
import shutil
from typing import Optional
from pathlib import Path

from open_webui.utils.auth import get_admin_user
from open_webui.config import get_config, save_config

router = APIRouter()

# Define paths for theme files
THEME_DIR = Path("backend/open_webui/static/theme")
LOGO_PATH = THEME_DIR / "logo.png"
CSS_PATH = THEME_DIR / "custom.css"

# Ensure theme directory exists
THEME_DIR.mkdir(parents=True, exist_ok=True)

class ThemeSettings(BaseModel):
    css: Optional[str] = None

@router.get("/theme", response_model=ThemeSettings)
async def get_theme_settings(user=Depends(get_admin_user)):
    """Get current theme settings"""
    try:
        css_content = ""
        if CSS_PATH.exists():
            with open(CSS_PATH, "r") as f:
                css_content = f.read()
        
        return ThemeSettings(css=css_content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/theme", response_model=ThemeSettings)
async def update_theme_settings(
    settings: ThemeSettings,
    user=Depends(get_admin_user)
):
    """Update theme settings"""
    try:
        # Save CSS content
        with open(CSS_PATH, "w") as f:
            f.write(settings.css or "")
        
        return ThemeSettings(css=settings.css)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/theme/logo")
async def upload_logo(
    file: UploadFile = File(...),
    user=Depends(get_admin_user)
):
    """Upload logo"""
    try:
        # Validate file type
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Save file
        with open(LOGO_PATH, "wb") as f:
            shutil.copyfileobj(file.file, f)
        
        return {"message": "Logo uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/theme/logo")
async def get_logo(user=Depends(get_admin_user)):
    """Get current logo"""
    try:
        if not LOGO_PATH.exists():
            raise HTTPException(status_code=404, detail="Logo not found")
        
        return FileResponse(LOGO_PATH)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/theme/logo")
async def delete_logo(user=Depends(get_admin_user)):
    """Delete current logo"""
    try:
        if LOGO_PATH.exists():
            LOGO_PATH.unlink()
        
        return {"message": "Logo deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 