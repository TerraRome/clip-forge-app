# MinIO/S3 Reference (Future)

## Not Currently Used
FileStorage uses local filesystem. No object storage.

## Future Migration Pattern
```python
from minio import Minio
from typing import BinaryIO

client = Minio(
    "play.min.io:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False,
)

class S3Storage:
    def __init__(self, bucket: str = "clips"):
        self.bucket = bucket
        if not client.bucket_exists(bucket):
            client.make_bucket(bucket)

    def upload(self, object_name: str, file_path: str) -> str:
        client.fput_object(self.bucket, object_name, file_path)
        return object_name

    def presigned_download(self, object_name: str, expiry: int = 3600) -> str:
        return client.presigned_get_object(self.bucket, object_name, expires=timedelta(seconds=expiry))
```

## When Needed
- Multi-server deployment (shared filesystem not available)
- User uploads (project images, custom fonts)
- Long-term clip archival
- CDN distribution for high-traffic downloads
