#!/bin/sh
# CloudBrowser CLI installer for macOS and Linux. No root privileges required.
set -eu

main() (
  version=${CLOUDBROWSER_VERSION:-0.2.0}
  version=${version#v}
  case "$version" in ''|*[!0-9.]*|.*|*..*) echo 'Invalid CLOUDBROWSER_VERSION (expected e.g. 0.2.0)' >&2; exit 1 ;; esac
  install_dir=${CLOUDBROWSER_INSTALL_DIR:-"$HOME/.local/bin"}
  case "$(uname -s)" in Darwin) os=darwin ;; Linux) os=linux ;; *) echo 'Unsupported OS. Windows users: https://cloudbrowser.tv/install.ps1' >&2; exit 1 ;; esac
  case "$(uname -m)" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) echo 'Unsupported CPU architecture' >&2; exit 1 ;; esac
  command -v tar >/dev/null 2>&1 || { echo 'tar is required' >&2; exit 1; }
  if command -v sha256sum >/dev/null 2>&1; then checksum=sha256sum
  elif command -v shasum >/dev/null 2>&1; then checksum=shasum
  else echo 'sha256sum or shasum is required' >&2; exit 1; fi
  fetch() {
    if command -v curl >/dev/null 2>&1; then
      curl --fail --silent --show-error --location --retry 3 --connect-timeout 15 --max-time 180 --proto '=https' --proto-redir '=https' "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
      wget --https-only --timeout=180 -q -O "$2" "$1"
    else echo 'curl or wget is required' >&2; return 1; fi
  }
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT
  trap 'exit 1' HUP INT TERM
  asset="cloudbrowser_${version}_${os}_${arch}.tar.gz"
  base="https://github.com/langyishipit/cloudbrowser-cli/releases/download/v${version}"
  echo "Downloading CloudBrowser CLI v${version} (${os}/${arch})…" >&2
  fetch "$base/$asset" "$temp_dir/$asset"
  fetch "$base/checksums.txt" "$temp_dir/checksums.txt"
  expected=$(awk -v file="$asset" '$2 == file { print $1 }' "$temp_dir/checksums.txt")
  [ "${#expected}" -eq 64 ] || { echo 'Missing or invalid release checksum' >&2; exit 1; }
  if [ "$checksum" = sha256sum ]; then actual=$(sha256sum "$temp_dir/$asset" | awk '{print $1}')
  else actual=$(shasum -a 256 "$temp_dir/$asset" | awk '{print $1}'); fi
  [ "$expected" = "$actual" ] || { echo 'Checksum mismatch; installation aborted' >&2; exit 1; }
  tar -xzf "$temp_dir/$asset" -C "$temp_dir" cloudbrowser
  mkdir -p "$install_dir"
  # Prepare the new binary on the same filesystem before replacing an old install.
  staging=$(mktemp "$install_dir/.cloudbrowser.XXXXXX")
  trap 'rm -rf "$temp_dir"; if [ -n "${staging:-}" ]; then rm -f "$staging"; fi' EXIT
  cp "$temp_dir/cloudbrowser" "$staging"
  chmod 755 "$staging"
  mv -f "$staging" "$install_dir/cloudbrowser"
  staging=''
  echo "Installed CloudBrowser CLI v${version} at $install_dir/cloudbrowser"
  case ":${PATH:-}:" in *":$install_dir:"*) ;; *) printf 'Add this directory to PATH in your shell: %s\n' "$install_dir" ;; esac
  printf 'Next: "%s/cloudbrowser" auth login\n' "$install_dir"
)
main "$@"
