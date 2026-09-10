from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class ComplaintCreate(BaseModel):
    title: str
    description: str
    ride_id: Optional[int] = None


class ComplaintStatusUpdate(BaseModel):
    status: str
    admin_notes: Optional[str] = None


class ComplaintResponse(BaseModel):
    id: int
    user_id: int
    ride_id: Optional[int] = None
    title: str
    description: str
    status: str
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
