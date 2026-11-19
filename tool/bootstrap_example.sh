#!/usr/bin/env bash
set -euo pipefail

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
platform_list="${1:-ios,android,web}"

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter is required. Install Flutter and add it to PATH first.' >&2
  exit 1
fi

IFS=',' read -r -a selected_platforms <<< "$platform_list"
for platform in "${selected_platforms[@]}"; do
  case "$platform" in
    ios|android|web) ;;
    *) echo 'Supported example platforms: ios,android,web' >&2; exit 2 ;;
  esac
  if [[ -e "$package_dir/example/$platform" ]]; then
    echo "Runner already exists: example/$platform. No files were changed." >&2
    exit 3
  fi
done

temporary_project="$(mktemp -d "${TMPDIR:-/tmp}/glass-effect-example.XXXXXX")"
trap 'rm -rf -- "$temporary_project"' EXIT

flutter create \
  --empty \
  --project-name glass_liquid_effect_example \
  --org com.example \
  --platforms "$platform_list" \
  "$temporary_project/runner"

for platform in "${selected_platforms[@]}"; do
  cp -R "$temporary_project/runner/$platform" "$package_dir/example/$platform"
done

if [[ ! -e "$package_dir/example/.metadata" ]]; then
  cp "$temporary_project/runner/.metadata" "$package_dir/example/.metadata"
fi

cd "$package_dir/example"
flutter pub get
echo 'Example runners created. Demo source and pubspec were preserved.'
