Older remote branches are saved in release asset branch-recovery.tar.zst.
Its index.json records exact original heads and corrected branch prerequisites.

First clone the corresponding full-history porsche-aospa-shiva branch.
Extract branch-recovery.tar.zst into a separate directory, then run:

```bash
python3 scripts/restore-branch-history.py /path/to/clone /path/to/branch-recovery device/realme/porsche
```

The script verifies and imports each incremental bundle, then reconstructs all
original refs under refs/backup-precleanup/ShivaOPP/. Ancestor branches need no
additional objects; their commits are already in the corrected full history.
Existing recovery refs are never overwritten. The active build branch stays
unchanged. Original local a17-port branches are also in the source snapshot.
