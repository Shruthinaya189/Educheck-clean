from fastapi import APIRouter

router = APIRouter()

@router.get("/me")
def get_profile():
    return {"message": "Profile endpoint (TODO: implement auth)"}
