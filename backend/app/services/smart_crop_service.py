import structlog
from typing import Optional

from app.services.face_service import FaceBox

logger = structlog.get_logger()

OUTPUT_WIDTH = 1080
OUTPUT_HEIGHT = 1920


class SmartCropService:
    """
    Computes FFmpeg filter chain for vertical shorts (9:16).

    Strategy:
    1. Scale source to fill OUTPUT_HEIGHT (landscape) or OUTPUT_WIDTH (portrait)
       preserving aspect ratio → intermediate frame is ≥ output resolution.
    2. Crop 9:16 region centred on the detected face (or centre if no face).
    """

    def compute_filter(
        self,
        face: Optional[FaceBox],
        video_width: int,
        video_height: int,
    ) -> str:
        if face is None:
            return self._center_fill()

        # Scale so the video fills the 1080×1920 canvas
        src_ratio = video_width / video_height
        target_ratio = OUTPUT_WIDTH / OUTPUT_HEIGHT  # 0.5625

        if src_ratio > target_ratio:
            # Landscape: scale height to 1920, width overflows
            scale_w = int(video_width * (OUTPUT_HEIGHT / video_height))
            scale_h = OUTPUT_HEIGHT
            # Face X in scaled coords → crop x
            face_x = int(face.x * scale_w)
            crop_x = face_x - OUTPUT_WIDTH // 2
            crop_x = max(0, min(crop_x, scale_w - OUTPUT_WIDTH))
            crop_y = 0
        else:
            # Portrait: scale width to 1080, height overflows
            scale_w = OUTPUT_WIDTH
            scale_h = int(video_height * (OUTPUT_WIDTH / video_width))
            face_y = int(face.y * scale_h)
            crop_y = face_y - OUTPUT_HEIGHT // 2
            crop_y = max(0, min(crop_y, scale_h - OUTPUT_HEIGHT))
            crop_x = 0

        logger.info(
            "smart_crop",
            face_center=(face and (round(face.x, 3), round(face.y, 3))),
            scale=(scale_w, scale_h),
            crop=(crop_x, crop_y),
        )
        return f"scale={scale_w}:{scale_h},crop={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}:{crop_x}:{crop_y}"

    def _center_fill(self) -> str:
        """Fill 1080×1920 with centred content (same logic, centre of frame)."""
        return f"scale={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}:force_original_aspect_ratio=increase,crop={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}"
