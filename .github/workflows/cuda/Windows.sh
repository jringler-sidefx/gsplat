#!/bin/bash
set -euo pipefail

# Took from https://github.com/pyg-team/pyg-lib/

# Install NVIDIA drivers, see:
# https://github.com/pytorch/vision/blob/master/packaging/windows/internal/cuda_install.bat#L99-L102
curl -k -fSL "https://drive.google.com/u/0/uc?id=1injUyo3lnarMgWyRcXqKg4UGnN0ysmuq&export=download" --output "/tmp/gpu_driver_dlls.zip"
7z x "/tmp/gpu_driver_dlls.zip" -o"/c/Windows/System32"

resolve_cuda_windows_installer() {
  local cuda_dir
  local cuda_dir_regex
  local base_url
  local index
  local file

  for cuda_dir in "${CUDA_DIR_CANDIDATES[@]}"; do
    base_url="https://developer.download.nvidia.com/compute/cuda/${cuda_dir}/local_installers"
    if ! index=$(curl -fsSL "${base_url}/"); then
      continue
    fi
    cuda_dir_regex=${cuda_dir//./\\.}
    file=$(printf "%s" "${index}" | grep -oE "cuda_${cuda_dir_regex}_[0-9.]+_(windows|win10)\\.exe" | head -n1 || true)
    if [ -n "${file}" ]; then
      CUDA_URL="${base_url}"
      CUDA_FILE="${file}"
      return 0
    fi
  done

  echo "Failed to locate CUDA ${CUDA_SHORT} Windows installer. Tried: ${CUDA_DIR_CANDIDATES[*]}" >&2
  exit 1
}

case ${1} in
  cu128)
    CUDA_SHORT=12.8
    CUDA_DIR_CANDIDATES=("12.8.1" "12.8.0")
    resolve_cuda_windows_installer
    ;;
  cu124)
    CUDA_SHORT=12.4
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.1/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.1_551.78_windows.exe
    ;;
  cu121)
    CUDA_SHORT=12.1
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.1/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.1_531.14_windows.exe
    ;;
  cu118)
    CUDA_SHORT=11.8
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.0/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.0_522.06_windows.exe
    ;;
  cu117)
    CUDA_SHORT=11.7
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.1/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.1_516.94_windows.exe
    ;;
  cu116)
    CUDA_SHORT=11.3
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.0/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.0_465.89_win10.exe
    ;;
  cu115)
    CUDA_SHORT=11.3
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.0/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.0_465.89_win10.exe
    ;;
  cu113)
    CUDA_SHORT=11.3
    CUDA_URL=https://developer.download.nvidia.com/compute/cuda/${CUDA_SHORT}.0/local_installers
    CUDA_FILE=cuda_${CUDA_SHORT}.0_465.89_win10.exe
    ;;
  *)
    echo "Unrecognized CUDA_VERSION=${1}"
    exit 1
    ;;
esac

curl -k -fSL "${CUDA_URL}/${CUDA_FILE}" --output "${CUDA_FILE}"
echo ""
echo "Installing from ${CUDA_FILE}..."
PowerShell -Command "Start-Process -FilePath \"${CUDA_FILE}\" -ArgumentList \"-s nvcc_${CUDA_SHORT} cuobjdump_${CUDA_SHORT} nvprune_${CUDA_SHORT} cupti_${CUDA_SHORT} cublas_dev_${CUDA_SHORT} cudart_${CUDA_SHORT} cufft_dev_${CUDA_SHORT} curand_dev_${CUDA_SHORT} cusolver_dev_${CUDA_SHORT} cusparse_dev_${CUDA_SHORT} thrust_${CUDA_SHORT} npp_dev_${CUDA_SHORT} nvrtc_dev_${CUDA_SHORT} nvml_dev_${CUDA_SHORT}\" -Wait -NoNewWindow"
echo "Done!"
rm -f "${CUDA_FILE}"

echo Installing NvToolsExt...
curl -k -fSL https://ossci-windows.s3.us-east-1.amazonaws.com/builder/NvToolsExt.7z --output /tmp/NvToolsExt.7z
7z x /tmp/NvToolsExt.7z -o"/tmp/NvToolsExt"
mkdir -p "/c/Program Files/NVIDIA Corporation/NvToolsExt/bin/x64"
mkdir -p "/c/Program Files/NVIDIA Corporation/NvToolsExt/include"
mkdir -p "/c/Program Files/NVIDIA Corporation/NvToolsExt/lib/x64"
cp -r /tmp/NvToolsExt/bin/x64/* "/c/Program Files/NVIDIA Corporation/NvToolsExt/bin/x64"
cp -r /tmp/NvToolsExt/include/* "/c/Program Files/NVIDIA Corporation/NvToolsExt/include"
cp -r /tmp/NvToolsExt/lib/x64/* "/c/Program Files/NVIDIA Corporation/NvToolsExt/lib/x64"
