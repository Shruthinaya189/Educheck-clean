from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Class, Enrollment
from pydantic import BaseModel

router = APIRouter()

class ClassCreate(BaseModel):
    name: str
    code: str
    category: str

class ClassUpdate(BaseModel):
    is_archived: bool | None = None

@router.post("/classes")
def create_class(class_data: ClassCreate, db: Session = Depends(get_db)):
    # Check if code already exists
    existing = db.query(Class).filter(Class.code == class_data.code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Class code already exists")
    
    new_class = Class(
        name=class_data.name,
        code=class_data.code,
        category=class_data.category,
        teacher_id=1  # TODO: get from auth token
    )
    db.add(new_class)
    db.commit()
    db.refresh(new_class)
    
    return {
        "id": new_class.id,
        "name": new_class.name,
        "code": new_class.code,
        "category": new_class.category,
        "is_archived": new_class.is_archived,
        "enrolled_students": []
    }

@router.get("/classes")
def get_teacher_classes(db: Session = Depends(get_db)):
    classes = db.query(Class).filter(Class.teacher_id == 1).all()  # TODO: filter by auth user
    return [
        {
            "id": c.id,
            "name": c.name,
            "code": c.code,
            "category": c.category,
            "is_archived": c.is_archived,
            "enrolled_students": [
                e.student_id for e in db.query(Enrollment).filter(Enrollment.class_id == c.id).all()
            ]
        }
        for c in classes
    ]

@router.put("/classes/{class_id}")
def update_class(class_id: int, updates: ClassUpdate, db: Session = Depends(get_db)):
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj:
        raise HTTPException(status_code=404, detail="Class not found")
    
    if updates.is_archived is not None:
        class_obj.is_archived = updates.is_archived
    
    db.commit()
    return {"message": "Class updated"}

@router.delete("/classes/{class_id}")
def delete_class(class_id: int, db: Session = Depends(get_db)):
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj:
        raise HTTPException(status_code=404, detail="Class not found")
    
    db.delete(class_obj)
    db.commit()
    return {"message": "Class deleted"}
