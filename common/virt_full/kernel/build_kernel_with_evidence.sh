#!/usr/bin/env bash
# Only an executed, successful kernel build may create this certificate.
set -euo pipefail
[ "$#" -eq 7 ] || { echo "expected seven GN kernel arguments" >&2; exit 2; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
HELPER="${SCRIPT_DIR}/kernel_input_evidence.py"
EXPECTED="$(python3 "${HELPER}" check-inputs --source-root "${SOURCE_ROOT}")"
IMAGE_DIR="$(python3 -c 'from pathlib import Path; import sys; print((Path(sys.argv[1]) / sys.argv[2]).resolve())' "${SCRIPT_DIR}" "$3")"
MODULES_DIR="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$7")"
case "$6" in
  arm) IMAGE=zImage ;;
  arm64|riscv64) IMAGE=Image ;;
  x86_64) IMAGE=bzImage ;;
  *) echo "unsupported kernel architecture: $6" >&2; exit 2 ;;
esac
# The old file-existence shortcut has no source identity. Never certify it.
OHOS_SKIP_KERNEL_REBUILD_IF_COMPLETE=0 bash "${SCRIPT_DIR}/build_kernel.sh" "$@"
python3 "${HELPER}" record --source-root "${SOURCE_ROOT}" \
  --expected-inputs-sha256 "${EXPECTED}" --image "${IMAGE_DIR}/${IMAGE}" \
  --modules-dir "${MODULES_DIR}" --arch "$6" --certificate "${IMAGE_DIR}/kernel-inputs.json"
