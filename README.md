# Surveillance Station — safe maintenance fork

This branch is a clean, maintenance-only branch of
[`salitis777/SS`](https://github.com/salitis777/SS). It intentionally does
not contain the activation script, binary patches, modified package payloads,
or bundled Surveillance Station executable files.

## Scope

- Read-only diagnostics for the installed Surveillance Station package.
- Local backup of the installed package target directory.
- SHA-256 verification of a backup.
- A conservative recovery guide that directs restoration through DSM Package
  Center using the matching official Synology package.

This project does **not** provide Surveillance Station licenses, bypass
license checks, modify licensing behavior, or replace vendor binaries.

## Requirements

- Synology DSM with Surveillance Station installed.
- Root shell access on the NAS.
- Enough free space on the volume for a complete copy of
  `/var/packages/SurveillanceStation/target`.

## Use

Copy `tools/ss-maintenance.sh` to the NAS and run it as root:

```sh
chmod 700 ss-maintenance.sh
./ss-maintenance.sh diagnose
./ss-maintenance.sh backup
```

The default backup location is
`/volume1/SurveillanceStation-backups`. Verify a backup using the exact
directory printed by the backup command:

```sh
./ss-maintenance.sh verify /volume1/SurveillanceStation-backups/SurveillanceStation-TIMESTAMP
```

To view the supported recovery procedure:

```sh
./ss-maintenance.sh restore-guide
```

## Important recovery notes

A backup is only as trustworthy as the state of the NAS at the moment it was
created. If package files may already have been modified, do not describe that
snapshot as vendor-original. For a known-good vendor baseline, use the
matching official Synology package and DSM Package Center's supported
repair/reinstall flow. Never mix package versions or CPU architectures.

The script does not stop services, overwrite installed files, change
permissions on package files, edit `/etc/hosts`, or fetch remote code.

## Upstream and licensing

This repository originated as a fork of
[`ohyeah521/Surveillance-Station`](https://github.com/ohyeah521/Surveillance-Station).
Retain upstream copyright notices and comply with the applicable license for
any upstream material reused. The `LICENSE` file is retained from the
upstream repository; it does not grant rights to Synology trademarks,
Surveillance Station binaries, or other third-party materials.

Official package source:
https://archive.synology.com/download/Package/SurveillanceStation
