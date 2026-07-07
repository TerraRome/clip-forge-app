from app.celery_app import celery_app

# Import task modules so Celery discovers them
from app.worker import pipeline  # noqa: F401
from app.worker import audio_worker  # noqa: F401
from app.worker import video_worker  # noqa: F401
from app.worker import llm_worker  # noqa: F401
from app.worker import render_worker  # noqa: F401
from app.worker import export_worker  # noqa: F401

celery_app.conf.include = [
    "app.worker.pipeline",
    "app.worker.audio_worker",
    "app.worker.video_worker",
    "app.worker.llm_worker",
    "app.worker.render_worker",
    "app.worker.export_worker",
]
