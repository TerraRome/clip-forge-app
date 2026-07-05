from __future__ import annotations

import json
import os
import threading
from pathlib import Path

from app.config import settings
from app.models.project import Project


class FileStorage:
    """Thread-safe JSON file-based project storage."""

    def __init__(self):
        self._projects_dir = Path(settings.downloads_dir) / "_projects"
        self._projects_dir.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()

    def _project_path(self, project_id: str) -> Path:
        return self._projects_dir / f"{project_id}.json"

    def save(self, project: Project) -> None:
        with self._lock:
            path = self._project_path(project.id)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(project.to_dict(), indent=2))

    def get(self, project_id: str) -> Project | None:
        path = self._project_path(project_id)
        if not path.exists():
            return None
        with self._lock:
            data = json.loads(path.read_text())
            return Project.from_dict(data)

    def update(self, project_id: str, **kwargs) -> Project | None:
        project = self.get(project_id)
        if project is None:
            return None
        for key, value in kwargs.items():
            if hasattr(project, key):
                setattr(project, key, value)
        self.save(project)
        return project

    def delete(self, project_id: str) -> None:
        path = self._project_path(project_id)
        if path.exists():
            path.unlink()