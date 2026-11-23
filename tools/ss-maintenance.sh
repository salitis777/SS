#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

TARGET="/var/packages/SurveillanceStation/target"
PACKAGE_INFO="/var/packages/SurveillanceStation/INFO"
BACKUP_ROOT="/volume1/SurveillanceStation-backups"
ACTION="${1:-help}"

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: run this command as root on the Synology NAS." >&2
    exit 1
  fi
}
need_target() {
  [[ -d "$TARGET" ]] || { echo "ERROR: Surveillance Station target not found: $TARGET" >&2; exit 1; }
}

case "$ACTION" in
  diagnose)
    need_root
    echo "== Surveillance Station diagnostics =="
    if [[ -r "$PACKAGE_INFO" ]]; then
      echo "-- Package metadata --"
      grep -E '^(package|version|arch|model|displayname)=' "$PACKAGE_INFO" || true
    else
      echo "Package metadata not readable: $PACKAGE_INFO"
    fi
    echo "-- Package service --"
    if command -v synopkg >/dev/null 2>&1; then
      synopkg status SurveillanceStation 2>&1 || true
    else
      echo "synopkg command not found"
    fi
    echo "-- Target directory --"
    if [[ -d "$TARGET" ]]; then
      du -sh "$TARGET" 2>/dev/null || true
      find "$TARGET" -type f | wc -l | awk '{print "regular files: " $1}'
      find "$TARGET" -type l | wc -l | awk '{print "symbolic links: " $1}'
      find "$TARGET" -type f -perm /6000 -print 2>/dev/null | sed 's/^/setuid/setgid: /' || true
    else
      echo "MISSING: $TARGET"
      exit 2
    fi
    echo "-- Hosts overrides mentioning Synology --"
    if [[ -r /etc/hosts ]]; then
      grep -niE 'synology|surveillance' /etc/hosts || echo "No matching hosts entries found"
    fi
    ;;
  backup)
    need_root
    need_target
    mkdir -p "$BACKUP_ROOT"
    stamp="$(date +%Y%m%d-%H%M%S)"
    dest="$BACKUP_ROOT/SurveillanceStation-$stamp"
    [[ ! -e "$dest" ]] || { echo "ERROR: backup path already exists: $dest" >&2; exit 1; }
    mkdir -p "$dest"
    cp -a "$TARGET" "$dest/target"
    (
      cd "$dest"
      find target -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    )
    printf 'created=%s\nsource=%s\n' "$dest" "$TARGET" > "$dest/BACKUP-INFO.txt"
    echo "Backup created: $dest"
    echo "Verify it with: $0 verify '$dest'"
    ;;
  verify)
    need_root
    dir="${2:-}"
    [[ -n "$dir" && -d "$dir/target" && -f "$dir/SHA256SUMS" ]] || {
      echo "Usage: $0 verify /volume1/SurveillanceStation-backups/SurveillanceStation-TIMESTAMP" >&2
      exit 2
    }
    (cd "$dir" && sha256sum -c SHA256SUMS)
    ;;
  restore-guide)
    cat <<'GUIDE'
This safe tool does not overwrite DSM package files automatically.

To restore the vendor-original Surveillance Station files:
1. In DSM, open Package Center.
2. Download the matching Surveillance Station package from Synology's
   official package source for this NAS/model and DSM version.
3. Use Package Center's supported repair/reinstall procedure.
4. Do not mix files from different package versions or CPU architectures.
5. Run this tool's 'diagnose' command and create a fresh backup afterwards.

If you have a verified pre-change backup created by this tool, use the
matching DSM-supported package recovery procedure or Synology support.
Do not restore an unverified snapshot as an "original" baseline.
GUIDE
    ;;
  help|*)
    cat <<'HELP'
Usage (run on the Synology NAS as root):
  ss-maintenance.sh diagnose
  ss-maintenance.sh backup
  ss-maintenance.sh verify /volume1/SurveillanceStation-backups/SurveillanceStation-TIMESTAMP
  ss-maintenance.sh restore-guide

This tool is diagnostic/backup-only. It does not patch binaries, alter
licensing, edit hosts, download executables, or replace package files.
HELP
    ;;
esac
