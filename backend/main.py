from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

app = FastAPI(title="Trace EM Tracking API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple in-memory storage for demonstration
# In production, you would use a database like PostgreSQL
db = []

class LocationUpdate(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    region: Optional[str] = 'Region 7'  # Default to Region 7
    timestamp: Optional[datetime] = None

class LocationResponse(LocationUpdate):
    id: int

@app.get("/")
async def root():
    return {"message": "Trace EM API is running"}

@app.post("/track", response_model=LocationResponse)
async def update_location(data: LocationUpdate):
    if not data.timestamp:
        data.timestamp = datetime.now()
    
    new_entry = {
        "id": len(db) + 1,
        **data.model_dump()
    }
    db.append(new_entry)
    print(f"Update received from {data.user_id}: {data.latitude}, {data.longitude}")
    return new_entry

@app.get("/history/{user_id}", response_model=List[LocationResponse])
async def get_history(user_id: str):
    history = [item for item in db if item["user_id"] == user_id]
    return history

@app.get("/history/{region}/{user_id}", response_model=List[LocationResponse])
async def get_regional_history(region: str, user_id: str):
    """Get location history filtered by region and user"""
    history = [
        item for item in db 
        if item["user_id"] == user_id and item.get("region") == region
    ]
    return history

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
