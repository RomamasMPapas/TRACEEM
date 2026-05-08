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

class Complaint(BaseModel):
    user_id: str
    issue: str
    status: str = "pending"
    timestamp: Optional[datetime] = None

class Rating(BaseModel):
    user_id: str
    driver_id: str
    score: int
    comment: Optional[str] = None
    timestamp: Optional[datetime] = None

class Receipt(BaseModel):
    order_id: str
    amount: float
    user_id: str
    timestamp: Optional[datetime] = None

# Stubs for new features
complaints_db = []
ratings_db = []
receipts_db = []

@app.get("/")
async def root():
    return {"message": "Trace EM API is running", "version": "1.1.0"}

@app.post("/complaints", response_model=Complaint)
async def report_issue(data: Complaint):
    data.timestamp = data.timestamp or datetime.now()
    complaints_db.append(data.model_dump())
    return data

@app.post("/ratings", response_model=Rating)
async def submit_rating(data: Rating):
    data.timestamp = data.timestamp or datetime.now()
    ratings_db.append(data.model_dump())
    return data

@app.get("/admin/financials", response_model=List[Receipt])
async def get_financials():
    return receipts_db

import math

def calculate_distance(lat1, lon1, lat2, lon2):
    """Haversine formula to calculate distance between two points in meters"""
    R = 6371000  # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# Mock data for demonstration
MOCK_ORDER_LOCATION = {"lat": 14.5995, "lon": 120.9842}  # Manila Example

@app.get("/mock/setup-tracking")
async def setup_mock_tracking():
    """Returns a mock order and destination for testing without Firebase"""
    return {
        "order_id": "MOCK-123",
        "destination": MOCK_ORDER_LOCATION,
        "message": "Tracking initialized for Mock Order"
    }

@app.post("/track", response_model=LocationResponse)
async def update_location(data: LocationUpdate):
    if not data.timestamp:
        data.timestamp = datetime.now()
    
    # Geofencing Logic (Alternate Solution #4)
    dist = calculate_distance(data.latitude, data.longitude, MOCK_ORDER_LOCATION['lat'], MOCK_ORDER_LOCATION['lon'])
    proximity_alert = False
    if dist < 200: # Within 200 meters
        proximity_alert = True
        print(f"ALARM: User {data.user_id} is near destination! ({dist:.1f}m)")

    new_entry = {
        "id": len(db) + 1,
        "proximity_alert": proximity_alert,
        **data.model_dump()
    }
    db.append(new_entry)
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

