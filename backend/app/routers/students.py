from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Class, Enrollment
from pydantic import BaseModel

router = APIRouter()

class JoinClassRequest(BaseModel):
    code: str

@router.post("/join")
def join_class(request: JoinClassRequest, db: Session = Depends(get_db)):
    class_obj = db.query(Class).filter(Class.code == request.code).first()
    if not class_obj:
        raise HTTPException(status_code=404, detail="Class not found")
    
    student_id = 2  # TODO: get from auth token
    existing = db.query(Enrollment).filter(
        Enrollment.student_id == student_id,
        Enrollment.class_id == class_obj.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already enrolled")
    
    enrollment = Enrollment(student_id=student_id, class_id=class_obj.id)
    db.add(enrollment)
    db.commit()
    
    return {"message": "Joined class successfully"}

@router.get("/classes")
def get_student_classes(db: Session = Depends(get_db)):
    student_id = 2  # TODO: get from auth token
    enrollments = db.query(Enrollment).filter(Enrollment.student_id == student_id).all()
    classes = [db.query(Class).filter(Class.id == e.class_id).first() for e in enrollments]
    
    return [
        {
            "id": c.id,
            "name": c.name,
            "code": c.code,
            "category": c.category,
            "is_archived": c.is_archived,
            "enrolled_students": []
        }
        for c in classes if c
    ]
