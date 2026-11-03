#!/usr/bin/env bash
set -euxo pipefail

BUILD_DIR="${PWD}/_conda_build_ukca_box_model"
rm -rf "${BUILD_DIR}"

cmake -S "${SRC_DIR}" \
      -B "${BUILD_DIR}" \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_PREFIX_PATH="${PREFIX}" \
      -DCMAKE_LIBRARY_PATH="${PREFIX}/lib" \
      -DBUILD_UKCA_LIBRARY=OFF \
      -DBUILD_BOX_MODEL=ON \
      -DUKCA_USE_EXTERNAL_LIBRARY=ON \
      -DUKCA_EXTERNAL_MODULE_DIR="${PREFIX}/include/ukca/mod"

cmake --build "${BUILD_DIR}" --target ukca_box_model
cmake --install "${BUILD_DIR}"
