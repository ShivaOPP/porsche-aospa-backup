Older remote branches are saved in release asset branch-recovery.tar.zst.
Its index.json records exact original heads, their source paths and the
corrected branch used as a prerequisite for incremental Git bundles.

These are recovery records, not active build branches. To inspect an older
branch, first clone the corresponding full-history porsche-aospa-shiva branch,
then run `git bundle verify /path/to/repository.bundle` followed by
`git fetch /path/to/repository.bundle 'refs/backup-precleanup/ShivaOPP/*:refs/backup-precleanup/ShivaOPP/*'`.
If no bundle is listed, every old commit is already reachable from the corrected
full-history branch. Original local a17-port branches also remain in the source
snapshot. The old port attribution is retained only in this recovery history.
