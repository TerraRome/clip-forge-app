import structlog
import cv2
import numpy as np
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from mediapipe.tasks.python.vision import FaceDetector, FaceDetectorOptions, RunningMode
from mediapipe.tasks.python.core.base_options import BaseOptions
from mediapipe import Image as MpImage, ImageFormat

logger = structlog.get_logger()

_MODEL_PATH = str(Path(__file__).parent.parent.parent / "blaze_face_short_range.tflite")

_detector: Optional[FaceDetector] = None


def _get_detector() -> FaceDetector:
    global _detector
    if _detector is None:
        opts = FaceDetectorOptions(
            base_options=BaseOptions(model_asset_path=_MODEL_PATH),
            running_mode=RunningMode.IMAGE,
            min_detection_confidence=0.5,
        )
        _detector = FaceDetector.create_from_options(opts)
    return _detector


@dataclass
class FaceBox:
    x: float
    y: float
    w: float
    h: float
    score: float


class FaceService:
    """
    Detects faces in video keyframes using MediaPipe BlazeFace.

    Samples up to 30 frames per highlight window, returns largest face (= closest to camera).
    Falls back to None (center-crop) if no face found.
    """

    def detect_dominant_face(
        self,
        video_path: str,
        highlight_start: float,
        highlight_end: float,
        video_width: int,
        video_height: int,
        max_frames: int = 30,
    ) -> Optional[FaceBox]:
        duration = highlight_end - highlight_start
        if duration <= 0:
            return None

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            logger.warning("cannot_open_video_for_face_detection")
            return None

        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0:
            fps = 30.0

        detector = _get_detector()
        all_faces: list = []

        sample_count = max(5, min(int(duration), max_frames))

        for i in range(sample_count):
            ts = highlight_start + (duration * i / max(sample_count - 1, 1))
            cap.set(cv2.CAP_PROP_POS_FRAMES, int(ts * fps))
            ret, frame = cap.read()
            if not ret or frame is None:
                continue

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = detector.detect(MpImage(ImageFormat.SRGB, rgb))

            if result.detections:
                for d in result.detections:
                    b = d.bounding_box
                    all_faces.append(FaceBox(
                        x=(b.origin_x + b.width / 2) / video_width,
                        y=(b.origin_y + b.height / 2) / video_height,
                        w=b.width / video_width,
                        h=b.height / video_height,
                        score=d.categories[0].score if d.categories else 0.0,
                    ))

        cap.release()

        if not all_faces:
            logger.info("no_faces_detected_in_highlight")
            return None

        best = max(all_faces, key=lambda f: f.w * f.h)
        logger.info(
            "dominant_face_selected",
            x=round(best.x, 3), y=round(best.y, 3),
            w=round(best.w, 3), h=round(best.h, 3),
            score=round(best.score, 3),
            frames_sampled=sample_count,
            total_detections=len(all_faces),
        )
        return best
