"""Content fingerprint of the human-reviewed verification package."""
import hashlib
import re


def fingerprint(ip):
    files = [ip / 'doc' / '07_dv_plan.md']
    files += sorted(p for p in (ip / 'dv').rglob('*') if p.is_file()
                    and not {'build', '__pycache__'}.intersection(p.relative_to(ip / 'dv').parts))
    digest = hashlib.sha256()
    for path in files:
        if not path.exists():
            continue
        content = path.read_bytes()
        if path == files[0]:
            text = content.decode('utf-8').replace('\r\n', '\n')
            text = re.sub(r'^(reviewer|approved|approved_dv_digest|status):[^\n]*\n', '', text, flags=re.M)
            content = text.encode('utf-8')
        digest.update(path.relative_to(ip).as_posix().encode('utf-8') + b'\0' + content + b'\0')
    return digest.hexdigest()
