#!/usr/bin/env bash
set -euo pipefail

export PATH="${FLUTTER_HOME:-/home/ubuntu/flutter}/bin:${PATH}"

flutter pub get
flutter analyze
flutter test --coverage --reporter compact

if [[ ! -f coverage/lcov.info ]]; then
  echo 'coverage/lcov.info was not generated' >&2
  exit 1
fi

coverage_stats=$(awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "%d %d %.2f\n", lf, lh, lf ? 100*lh/lf : 0}' coverage/lcov.info)
read -r lines hit percent <<< "$coverage_stats"
printf 'Coverage: %s/%s lines (%s%%)\n' "$hit" "$lines" "$percent"

# Keep a non-trivial regression floor while the remaining native/UI surfaces are
# expanded. Raise this floor as feature-level suites land.
awk -v value="$percent" 'BEGIN { exit !(value >= 20.0) }' || {
  echo "Coverage regression: ${percent}% is below the 20% floor" >&2
  exit 1
}
