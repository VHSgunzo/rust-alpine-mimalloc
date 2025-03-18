#!/bin/sh

set -eu

MIMALLOC_VERSION=2.1.7

cd /tmp

apk upgrade --no-cache

apk add --no-cache \
  git \
  alpine-sdk \
  rustup \
  clang \
  cmake \
  curl \
  mold \
  ninja-is-really-ninja

rustup-init -y --default-toolchain nightly --target $(uname -m)-unknown-linux-musl --component rust-src

find /usr /root -type f -executable -name "ld" -exec sh -c 'ln -sf /usr/bin/ld.mold {}' \;

curl -f -L --retry 5 https://github.com/microsoft/mimalloc/archive/refs/tags/v$MIMALLOC_VERSION.tar.gz | tar xz

cd mimalloc-$MIMALLOC_VERSION

patch -p1 < /tmp/mimalloc.diff

export CFLAGS="-Os -g0 -ffunction-sections -fdata-sections -fvisibility=hidden -fmerge-all-constants -D__USE_ISOC11"
export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"

cmake \
  -Bout \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DMI_BUILD_OBJECT=OFF \
  -DMI_BUILD_TESTS=OFF \
  -DMI_LIBC_MUSL=ON \
  -DMI_SECURE=OFF \
  -DMI_SKIP_COLLECT_ON_EXIT=ON \
  -G Ninja \
  .

cmake --build out --target install -- -v

for libc_path in $(find /usr /root -name libc.a); do
  {
    echo "CREATE libc.a"
    echo "ADDLIB $libc_path"
    echo "DELETE aligned_alloc.lo calloc.lo donate.lo free.lo libc_calloc.lo lite_malloc.lo malloc.lo malloc_usable_size.lo memalign.lo posix_memalign.lo realloc.lo reallocarray.lo valloc.lo"
    echo "ADDLIB out/libmimalloc.a"
    echo "SAVE"
  } | ar -M
  mv libc.a $libc_path
done

rm -rf \
  /tmp/build.sh \
  /tmp/mimalloc.diff \
  /tmp/mimalloc-$MIMALLOC_VERSION
