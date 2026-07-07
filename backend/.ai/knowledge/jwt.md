# JWT Auth Reference

## Not Currently Used
ClipForge has no authentication. CORS allows all origins.
No user model, no login, no tokens.

## Future Implementation Pattern
```python
from jose import jwt, JWTError
from datetime import datetime, timedelta

SECRET_KEY = settings.jwt_secret_key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode.update({"exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

## Middleware Pattern
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path not in ["/health", "/docs", "/openapi.json"]:
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return JSONResponse(status_code=401, content={"detail": "Missing token"})
    return await call_next(request)
```
