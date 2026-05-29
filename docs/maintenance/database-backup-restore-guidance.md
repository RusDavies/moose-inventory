# Database backup and restore guidance

Status: operational guidance for users; not an approval for destructive restore features.

Moose Inventory supports SQLite, MySQL/MariaDB, and PostgreSQL database adapters. The CLI provides a direct `db backup` helper for SQLite only. Server-backed database engines should be backed up and restored with their native database tools and the user's normal operational controls.

## Scope boundary

Moose Inventory can:

- report the configured adapter through `moose-inventory db status`;
- run explicit ordered schema migrations through `moose-inventory db migrate`;
- check expected schema/table state through `moose-inventory db doctor`;
- copy the configured SQLite database file through `moose-inventory db backup FILE`;
- export portable inventory snapshots for review, migration, and automation workflows.

Moose Inventory does not currently:

- run `mysqldump`, `mariadb-dump`, `pg_dump`, `pg_restore`, or server-specific restore commands;
- manage database users, grants, TLS, server encryption, replication, point-in-time recovery, or retention policies;
- guarantee transaction-consistent backups for server-backed databases;
- implement destructive snapshot sync/restore semantics;
- overwrite or drop user databases as a restore mechanism.

Those operations belong to the database administrator, hosting platform, or user's backup system.

## General backup principles

For all adapters:

1. Treat inventory databases, exported snapshots, audit output, and backups as sensitive infrastructure metadata.
2. Back up before migrations, version upgrades, bulk imports, and manual database maintenance.
3. Store backups outside the working directory if the repository may be shared.
4. Protect backup files with filesystem, database, or object-storage access controls matching the source data sensitivity.
5. Test restore procedures on a disposable database before trusting them for production recovery.
6. Record the Moose Inventory version, database adapter, schema version, and source environment alongside backup evidence.

Suggested pre-change evidence:

```bash
moose-inventory db status
moose-inventory db doctor
moose-inventory export snapshot ./backup/pre-change-inventory.yml
```

The snapshot is not a physical database backup. It is useful for review, migration, and reconstruction workflows, but it does not replace native database backups for server-backed engines.

## SQLite

SQLite is file-backed, so the CLI can provide a direct backup helper:

```bash
moose-inventory db backup ./backup/moose-inventory.sqlite3
```

Recommended SQLite restore pattern:

1. Stop jobs or shells that may write to the SQLite database.
2. Move the current database file aside rather than deleting it.
3. Copy the backup into the configured database path.
4. Run `moose-inventory db status` and `moose-inventory db doctor`.
5. Inspect expected hosts/groups before resuming automation.

Example manual restore outline:

```bash
cp ~/.moose/db/dev.db ~/.moose/db/dev.db.before-restore
cp ./backup/moose-inventory.sqlite3 ~/.moose/db/dev.db
moose-inventory db status
moose-inventory db doctor
```

Do not restore over an active writer. If using SQLite in automation, pause the automation first.

## MySQL and MariaDB

Use native MySQL/MariaDB backup tooling such as `mysqldump` or `mariadb-dump`. Moose Inventory should not be the process that chooses dump options, credentials, locks, replication state, compression, encryption, or restore targets.

Typical logical backup shape:

```bash
mysqldump \
  --single-transaction \
  --routines \
  --triggers \
  --databases moose_inventory \
  > moose-inventory-mysql.sql
```

Notes:

- Prefer credentials from a protected option file, environment-specific secret manager, or interactive prompt rather than committed config.
- `--single-transaction` is appropriate for transactional tables such as InnoDB; confirm table engines before relying on it.
- Capture grants/users separately if the restore target also needs database accounts and permissions.
- For large deployments, consider physical backup, snapshots, or managed-service backup features instead of a logical dump.

Recommended restore boundary:

1. Restore into a new or disposable database first.
2. Point a temporary Moose Inventory config at the restored database.
3. Run `moose-inventory db status` and `moose-inventory db doctor`.
4. Export and inspect a snapshot from the restored database.
5. Cut over application configuration only after human review.

Avoid restoring directly over the active database unless there is a separate incident/recovery plan and approval.

## PostgreSQL

Use native PostgreSQL backup tooling such as `pg_dump`, `pg_dumpall`, `pg_restore`, managed-service snapshots, or WAL/PITR tooling depending on the deployment.

Typical custom-format logical backup shape:

```bash
pg_dump \
  --format=custom \
  --file=moose-inventory-postgres.dump \
  moose_inventory
```

Typical inspection/restore shape for a disposable database:

```bash
createdb moose_inventory_restore_check
pg_restore \
  --dbname=moose_inventory_restore_check \
  --clean \
  --if-exists \
  moose-inventory-postgres.dump
```

Notes:

- Capture roles, ownership, and grants separately when needed; `pg_dump` of one database does not fully replace cluster-level role backup.
- Use managed-service snapshot/PITR features when recovery-point objectives matter.
- Keep connection strings, passwords, and dump files out of the repository.
- Verify restore compatibility before upgrading PostgreSQL major versions or Moose Inventory schema versions.

Recommended restore boundary is the same as MySQL/MariaDB: restore to a disposable database, verify with Moose Inventory read/status commands, then cut over only after human review.

## Snapshot export/import and restore expectations

`moose-inventory export snapshot` is a portable application-level export. It is useful for:

- inventory review;
- CI checks;
- migration rehearsal;
- emergency reconstruction when native DB backups are unavailable.

Snapshot import remains additive/update-oriented. It is not a destructive restore or exact database rollback. A future destructive sync/restore mode would require separate requirements, UX design, recovery controls, tests, and explicit approval.

## Release and maintenance checklist

Before migrations, bulk import work, or release-adjacent database testing:

- identify the adapter and environment;
- run `moose-inventory db status` and `moose-inventory db doctor`;
- create a SQLite backup or native server-backed database backup;
- export a snapshot as review evidence;
- test restore on a disposable target when risk warrants it;
- document any destructive or externally managed restore action separately.

If a backup or restore requires production credentials, cloud-console actions, database-account changes, or destructive replacement of an active database, stop and get explicit human approval.
