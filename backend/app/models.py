from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String)
    role = Column(String)  # 'teacher' or 'student'
    created_at = Column(DateTime, default=datetime.utcnow)

class Class(Base):
    __tablename__ = "classes"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    code = Column(String, unique=True, index=True, nullable=False)
    category = Column(String)  # '1st Year', '2nd Year', etc.
    teacher_id = Column(Integer, ForeignKey("users.id"))
    is_archived = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    enrollments = relationship("Enrollment", back_populates="class_obj")
    tests = relationship("Test", back_populates="class_obj")

class Enrollment(Base):
    __tablename__ = "enrollments"
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"))
    class_id = Column(Integer, ForeignKey("classes.id"))
    enrolled_at = Column(DateTime, default=datetime.utcnow)
    
    class_obj = relationship("Class", back_populates="enrollments")

class Test(Base):
    __tablename__ = "tests"
    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"))
    title = Column(String, nullable=False)
    total_marks = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    class_obj = relationship("Class", back_populates="tests")
    submissions = relationship("Submission", back_populates="test")

class Submission(Base):
    __tablename__ = "submissions"
    id = Column(Integer, primary_key=True, index=True)
    test_id = Column(Integer, ForeignKey("tests.id"))
    student_id = Column(Integer, ForeignKey("users.id"))
    answer_sheet_url = Column(String)
    marks_obtained = Column(Integer)
    submitted_at = Column(DateTime, default=datetime.utcnow)
    
    test = relationship("Test", back_populates="submissions")
