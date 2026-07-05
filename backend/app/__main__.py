import sys
import uvicorn
from app.config import settings

if __name__ == "__main__":
    reload_ = "--no-reload" not in sys.argv
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=reload_,
    )
