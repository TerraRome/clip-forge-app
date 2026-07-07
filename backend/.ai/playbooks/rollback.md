# Rollback Bad Deployment

## Context
Rollback a ClipForge deployment that broke clip generation. Either code defect (pipeline crash-loop, corrupt clips, API 500s) or JSON schema migration issue.

## Trigger Conditions
- All new projects immediately go to ERROR status
- `/health` returns non-200, or API returns 500
- FFmpeg renders corrupt clips (0-byte files, wrong resolution, no audio)
- Existing projects fail to load after schema migration

## Prerequisites
- Last known good commit SHA (`git log --oneline -10`)
- Backup of `downloads/` from before deployment (if schema migration ran)
- `clipforge.pid` file or find PID via `ps aux | grep uvicorn`

## Steps

### A. Stop server
```bash
kill $(cat clipforge.pid) 2>/dev/null
# Or find manually:
ps aux | grep uvicorn | grep -v grep | awk '{print $2}' | xargs kill
```

### B. Revert code
```bash
# Option 1: Revert single bad commit
git log --oneline -5
git revert HEAD --no-edit

# Option 2: Reset to known-good (if multiple bad commits)
git reset --hard <last-known-good-sha>
# Force push only if you're the only developer
# git push origin main --force  # USE WITH CAUTION
```

### C. Revert JSON storage schema (if applicable)
```bash
# Check if migration ran:
python3 -c "
import json
from pathlib import Path
meta = next(Path('./downloads').iterdir()) / 'project.json'
if meta.exists():
    p = json.loads(meta.read_text())
    print(f'Schema version: {p.get(\"schema_version\", 1)}')
"
# If schema was bumped during bad deploy and new code expects old schema:
# Restore from backup
rm -rf downloads
cp -r downloads.backup.YYYYMMDD_HHMMSS downloads
```

### D. Restart
```bash
source venv/bin/activate
nohup uvicorn app.main:app --host 0.0.0.0 --port 9999 --workers 1 > clipforge.log 2>&1 &
echo $! > clipforge.pid
sleep 2
curl -f http://localhost:9999/health
```

### E. Verify existing projects
```bash
python3 -c "
from app.state import storage
from pathlib import Path
for d in sorted(Path('./downloads').iterdir()):
    if (d / 'project.json').exists():
        p = storage.get(d.name)
        if p:
            print(f\"{d.name}: {p.status.value} (progress: {p.progress})\")
        else:
            print(f'{d.name}: FAILED TO LOAD')
"
```

### F. Verify new project
```bash
python3 -c "
import requests
r = requests.post('http://localhost:9999/api/projects',
    json={'youtube_url': 'https://youtu.be/dQw4w9WgXcQ', 'num_clips': 1})
print(f'Create: {r.status_code} {r.json().get(\"id\", r.json())}')
"
```

## Verification
- `/health` returns `{"status": "ok"}`
- All existing projects loadable with correct status
- New project can be created
- `clipforge.log` shows no pipeline ERROR

## Post-Rollback
1. Tag the broken commit: `git tag broken-$(date +%Y%m%d) <sha>`
2. Create GitHub issue documenting root cause
3. Add regression test before re-deploying
