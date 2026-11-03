#!/usr/bin/env bash
set -euxo pipefail

BUILD_DIR="${PWD}/_conda_build_ukca"
rm -rf "${BUILD_DIR}"

cmake -S "${SRC_DIR}" \
      -B "${BUILD_DIR}" \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DBUILD_UKCA_LIBRARY=ON \
      -DBUILD_BOX_MODEL=OFF

cmake --build "${BUILD_DIR}" --target ukca_standalone
cmake --install "${BUILD_DIR}"
