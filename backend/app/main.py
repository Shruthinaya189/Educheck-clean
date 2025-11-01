from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import teachers, students, profile

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="EduCheck API", version="1.0.0")

# CORS middleware (allow Flutter app to call backend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(teachers.router, prefix="/api/teacher", tags=["teacher"])
app.include_router(students.router, prefix="/api/student", tags=["student"])
app.include_router(profile.router, prefix="/api/profile", tags=["profile"])

@app.get("/")
def read_root():
    return {"message": "EduCheck API is running", "docs": "/docs"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
