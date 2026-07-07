from celery import Celery

from app.config import settings

celery_app = Celery(
    "klip_mobile",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    task_track_started=True,
    result_expires=3600,
    worker_prefetch_multiplier=1,
)

# Force import of all task modules so Celery registers them
import app.worker.pipeline  # noqa: F811, E402
import app.worker.audio_worker  # noqa: F811, E402
import app.worker.video_worker  # noqa: F811, E402
import app.worker.llm_worker  # noqa: F811, E402
import app.worker.render_worker  # noqa: F811, E402
import app.worker.export_worker  # noqa: F811, E402
