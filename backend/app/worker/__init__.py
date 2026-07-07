"""Worker base class."""

from abc import ABC, abstractmethod
from typing import Any

import structlog

from app.state import storage

logger = structlog.get_logger()


class BaseWorker(ABC):
    """Interface for pipeline workers.

    Subclasses implement execute(); base wiring handles state tracking + retries.
    """

    max_retries: int = 3
    default_retry_delay: int = 10  # seconds

    @abstractmethod
    def execute(self, project_id: str) -> Any:
        """Run the worker logic. Return result data or None."""
        ...

    def run(self, project_id: str) -> Any:
        log = logger.bind(project_id=project_id, worker=self.__class__.__name__)
        log.info("worker_started")
        try:
            result = self.execute(project_id)
            log.info("worker_completed")
            return result
        except Exception as e:
            log.error("worker_failed", error=str(e))
            storage.update(project_id, error_message=f"{self.__class__.__name__}: {e}")
            raise
