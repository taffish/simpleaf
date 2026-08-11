ARG PYTHON_VERSION=3.10
ARG RUST_VERSION=1.96.0

FROM rust:${RUST_VERSION}-slim-bookworm AS alevin-fry-builder

ARG RUST_VERSION
ARG ALEVIN_FRY_VERSION=0.17.1
ARG ALEVIN_FRY_TAG=v0.17.1
ARG ALEVIN_FRY_COMMIT=9c82c0ba8432ceea18d25089833d82cc5950fb59
ARG ALEVIN_FRY_SOURCE_SHA256=c88ec6cf65a601fc75a2842780fe25cb6116a5e024bcf1d92d89f3aec4043828
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    CARGO_NET_RETRY=5 \
    CARGO_HTTP_TIMEOUT=120

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        binutils \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        pkg-config; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/alevin-fry-build

RUN set -eux; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "https://github.com/COMBINE-lab/alevin-fry/releases/download/${ALEVIN_FRY_TAG}/source.tar.gz" \
        -o source.tar.gz; \
    echo "${ALEVIN_FRY_SOURCE_SHA256}  source.tar.gz" | sha256sum -c -; \
    mkdir source; \
    tar -xzf source.tar.gz -C source --strip-components=1; \
    case "${TARGETARCH}" in \
      amd64) rustflags='-C target-cpu=x86-64' ;; \
      arm64) rustflags='-C target-cpu=generic' ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    cd source; \
    RUSTFLAGS="${rustflags}" cargo build --release --locked; \
    install -Dm0755 target/release/alevin-fry /opt/alevin-fry/bin/alevin-fry; \
    strip --strip-unneeded /opt/alevin-fry/bin/alevin-fry; \
    install -Dm0644 LICENSE /opt/alevin-fry/share/licenses/alevin-fry/LICENSE; \
    install -Dm0644 README.md /opt/alevin-fry/share/doc/alevin-fry/README.md; \
    install -Dm0644 CHANGELOG.md /opt/alevin-fry/share/doc/alevin-fry/CHANGELOG.md; \
    { \
      printf 'upstream_name=alevin-fry\n'; \
      printf 'upstream_version=%s\n' "${ALEVIN_FRY_VERSION}"; \
      printf 'upstream_tag=%s\n' "${ALEVIN_FRY_TAG}"; \
      printf 'upstream_commit=%s\n' "${ALEVIN_FRY_COMMIT}"; \
      printf 'runtime_source=official source archive build\n'; \
      printf 'source_archive_sha256=%s\n' "${ALEVIN_FRY_SOURCE_SHA256}"; \
      printf 'cargo_locked=yes\n'; \
      printf 'rust=%s\n' "${RUST_VERSION}"; \
      printf 'target_arch=%s\n' "${TARGETARCH}"; \
      printf 'rustflags=%s\n' "${rustflags}"; \
      printf 'upstream_license=BSD-3-Clause\n'; \
    } > /opt/alevin-fry/share/doc/alevin-fry/source.txt; \
    rm -rf /tmp/alevin-fry-build /usr/local/cargo/registry /usr/local/cargo/git

FROM rust:${RUST_VERSION}-slim-bookworm AS piscem-builder

ARG RUST_VERSION
ARG PISCEM_VERSION=0.22.0
ARG PISCEM_TAG=v0.22.0
ARG PISCEM_COMMIT=7a0228a3758ef8faf92a2d3847740cd59953a56c
ARG PISCEM_SOURCE_SHA256=dfb1016fbffd98076c5e0515ed2306144f08e22ed062f117d60cf4933d99a4a2
ARG PACKED_SEQ_VERSION=5.0.0
ARG PACKED_SEQ_SHA256=5a3a89b413dff56614047583dad3cc5c4a61ad16a436a578dfaf8c214e98734a
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    CARGO_NET_RETRY=5 \
    CARGO_HTTP_TIMEOUT=120

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        binutils \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        pkg-config; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/piscem-build

RUN set -eux; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "https://github.com/COMBINE-lab/piscem/releases/download/${PISCEM_TAG}/source.tar.gz" \
        -o source.tar.gz; \
    echo "${PISCEM_SOURCE_SHA256}  source.tar.gz" | sha256sum -c -; \
    mkdir source; \
    tar -xzf source.tar.gz -C source --strip-components=1; \
    cd source; \
    case "${TARGETARCH}" in \
      amd64) \
        rustflags='-C target-cpu=x86-64'; \
        cpu_mode='scalar'; \
        grep -Fx 'mimalloc = "0.1"' Cargo.toml >/dev/null; \
        if grep -F 'packed-seq = ' Cargo.toml >/dev/null; then exit 1; fi; \
        sed -i '/^mimalloc = "0.1"$/a packed-seq = { version = "=5.0.0", features = ["scalar"] }' \
            Cargo.toml; \
        grep -Fx 'packed-seq = { version = "=5.0.0", features = ["scalar"] }' \
            Cargo.toml >/dev/null; \
        if sed -n '/^name = "piscem"$/,/^]$/p' Cargo.lock | \
            grep -Fx ' "packed-seq",' >/dev/null; then exit 1; fi; \
        sed -i '/^name = "piscem"$/,/^]$/s/^ "mimalloc",$/ "mimalloc",\n "packed-seq",/' \
            Cargo.lock; \
        sed -n '/^name = "piscem"$/,/^]$/p' Cargo.lock | \
            grep -Fx ' "packed-seq",' >/dev/null \
        ;; \
      arm64) \
        rustflags='-C target-cpu=generic'; \
        cpu_mode='neon' \
        ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    cargo fetch --locked; \
    RUSTFLAGS="${rustflags}" cargo build --release --locked; \
    install -Dm0755 target/release/piscem /opt/piscem/bin/piscem; \
    strip --strip-unneeded /opt/piscem/bin/piscem; \
    install -Dm0644 LICENSE /opt/piscem/share/licenses/piscem/LICENSE; \
    install -Dm0644 README.md /opt/piscem/share/doc/piscem/README.md; \
    { \
      printf 'upstream_name=piscem\n'; \
      printf 'upstream_version=%s\n' "${PISCEM_VERSION}"; \
      printf 'upstream_tag=%s\n' "${PISCEM_TAG}"; \
      printf 'upstream_commit=%s\n' "${PISCEM_COMMIT}"; \
      printf 'runtime_source=official source archive build\n'; \
      printf 'source_archive_sha256=%s\n' "${PISCEM_SOURCE_SHA256}"; \
      printf 'cargo_locked=yes\n'; \
      printf 'rust=%s\n' "${RUST_VERSION}"; \
      printf 'target_arch=%s\n' "${TARGETARCH}"; \
      printf 'rustflags=%s\n' "${rustflags}"; \
      printf 'cpu_mode=%s\n' "${cpu_mode}"; \
      printf 'packed_seq_version=%s\n' "${PACKED_SEQ_VERSION}"; \
      printf 'packed_seq_crate_sha256=%s\n' "${PACKED_SEQ_SHA256}"; \
      if [ "${TARGETARCH}" = amd64 ]; then \
        printf 'packaging_patch=add locked packed-seq direct dependency with scalar feature for generic x86-64\n'; \
      else \
        printf 'packaging_patch=none\n'; \
      fi; \
      printf 'upstream_license=BSD-3-Clause\n'; \
    } > /opt/piscem/share/doc/piscem/source.txt; \
    rm -rf /tmp/piscem-build /usr/local/cargo/registry /usr/local/cargo/git

FROM debian:12-slim AS rust-assets

ARG SIMPLEAF_VERSION=0.27.0
ARG SIMPLEAF_TAG=v0.27.0
ARG SIMPLEAF_COMMIT=e4713d6ec2127426a0198c3e6ba1ce3dd25bd1fa
ARG SIMPLEAF_SOURCE_SHA256=cecb53f84d81cb8d07a1782661edc7f97d177ca7255660e816d854529410e56f
ARG SIMPLEAF_AMD64_SHA256=a50ab007e20005426d6fccb484855afbea70c9d55818e9ec5878b15f44c8d3e8
ARG SIMPLEAF_ARM64_SHA256=a275add8b54080df342ee00449114e36057e6741eb3ba36c6865fc06f090e42b
ARG PISCEM_VERSION=0.22.0
ARG PISCEM_TAG=v0.22.0
ARG PISCEM_COMMIT=7a0228a3758ef8faf92a2d3847740cd59953a56c
ARG PISCEM_SOURCE_SHA256=dfb1016fbffd98076c5e0515ed2306144f08e22ed062f117d60cf4933d99a4a2
ARG ALEVIN_FRY_VERSION=0.17.1
ARG ALEVIN_FRY_TAG=v0.17.1
ARG ALEVIN_FRY_COMMIT=9c82c0ba8432ceea18d25089833d82cc5950fb59
ARG ALEVIN_FRY_SOURCE_SHA256=c88ec6cf65a601fc75a2842780fe25cb6116a5e024bcf1d92d89f3aec4043828
ARG PROTOCOL_ESTUARY_COMMIT=3476e9fceca173cf8f31e1b921bf4d6fb409eb3c
ARG PROTOCOL_ESTUARY_SHA256=3803492f80b36b85ff39267673f9d392032d4f862371c539949d3c50984c6a49
ARG TARGETARCH
ARG BUILDARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        binutils \
        ca-certificates \
        curl \
        tar \
        xz-utils; \
    rm -rf /var/lib/apt/lists/*

COPY --from=alevin-fry-builder /opt/alevin-fry /opt/simpleaf
COPY --from=piscem-builder /opt/piscem /opt/simpleaf

WORKDIR /tmp/simpleaf-build

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        asset_arch="x86_64"; \
        simpleaf_sha256="${SIMPLEAF_AMD64_SHA256}" \
        ;; \
      arm64) \
        asset_arch="aarch64"; \
        simpleaf_sha256="${SIMPLEAF_ARM64_SHA256}" \
        ;; \
      *) \
        echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; \
        exit 1 \
        ;; \
    esac; \
    simpleaf_asset="simpleaf-${asset_arch}-unknown-linux-gnu.tar.xz"; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "https://github.com/COMBINE-lab/simpleaf/releases/download/${SIMPLEAF_TAG}/${simpleaf_asset}" \
        -o simpleaf.tar.xz; \
    echo "${simpleaf_sha256}  simpleaf.tar.xz" | sha256sum -c -; \
    mkdir simpleaf-release; \
    tar -xJf simpleaf.tar.xz -C simpleaf-release --strip-components=1; \
    install -Dm0755 simpleaf-release/simpleaf /opt/simpleaf/bin/simpleaf; \
    strip --strip-unneeded /opt/simpleaf/bin/simpleaf; \
    install -Dm0644 simpleaf-release/LICENSE /opt/simpleaf/share/licenses/simpleaf/LICENSE; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "https://github.com/COMBINE-lab/simpleaf/releases/download/${SIMPLEAF_TAG}/source.tar.gz" \
        -o simpleaf-source.tar.gz; \
    echo "${SIMPLEAF_SOURCE_SHA256}  simpleaf-source.tar.gz" | sha256sum -c -; \
    mkdir simpleaf-source; \
    tar -xzf simpleaf-source.tar.gz -C simpleaf-source --strip-components=1; \
    install -Dm0644 simpleaf-source/README.md /opt/simpleaf/share/doc/simpleaf/README.md; \
    install -Dm0644 simpleaf-source/CHANGELOG.md /opt/simpleaf/share/doc/simpleaf/CHANGELOG.md; \
    install -Dm0644 simpleaf-source/resources/chemistries.json /opt/simpleaf/home/chemistries.json; \
    test "$(sha256sum /opt/simpleaf/home/chemistries.json | awk '{print $1}')" = \
        "85d4ec8918f971787a28f59e05a037930f0090086bd7f406cbc3fc8d145ccc35"; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "https://github.com/COMBINE-lab/protocol-estuary/archive/${PROTOCOL_ESTUARY_COMMIT}.tar.gz" \
        -o protocol-estuary.tar.gz; \
    echo "${PROTOCOL_ESTUARY_SHA256}  protocol-estuary.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/simpleaf/home/protocol-estuary/protocol-estuary-main; \
    tar -xzf protocol-estuary.tar.gz \
        -C /opt/simpleaf/home/protocol-estuary/protocol-estuary-main \
        --strip-components=1; \
    install -Dm0644 \
        /opt/simpleaf/home/protocol-estuary/protocol-estuary-main/LICENSE \
        /opt/simpleaf/share/licenses/protocol-estuary/LICENSE; \
    printf '%s\n' \
        '{' \
        '  "prog_info": {' \
        '    "piscem": {' \
        '      "exe_path": "/usr/local/bin/piscem",' \
        "      \"version\": \"${PISCEM_VERSION}\"" \
        '    },' \
        '    "alevin_fry": {' \
        '      "exe_path": "/usr/local/bin/alevin-fry",' \
        "      \"version\": \"${ALEVIN_FRY_VERSION}\"" \
        '    },' \
        '    "macs": {' \
        '      "exe_path": "/usr/local/bin/macs3",' \
        '      "version": "3.0.4"' \
        '    }' \
        '  }' \
        '}' > /opt/simpleaf/home/simpleaf_info.json; \
    { \
      printf 'upstream_name=simpleaf\n'; \
      printf 'upstream_repo=https://github.com/COMBINE-lab/simpleaf\n'; \
      printf 'upstream_version=%s\n' "${SIMPLEAF_VERSION}"; \
      printf 'upstream_tag=%s\n' "${SIMPLEAF_TAG}"; \
      printf 'upstream_commit=%s\n' "${SIMPLEAF_COMMIT}"; \
      printf 'runtime_source=official GitHub release binary\n'; \
      printf 'release_asset=%s\n' "${simpleaf_asset}"; \
      printf 'release_asset_sha256=%s\n' "${simpleaf_sha256}"; \
      printf 'linux_amd64_asset_sha256=%s\n' "${SIMPLEAF_AMD64_SHA256}"; \
      printf 'linux_arm64_asset_sha256=%s\n' "${SIMPLEAF_ARM64_SHA256}"; \
      printf 'source_archive_sha256=%s\n' "${SIMPLEAF_SOURCE_SHA256}"; \
      printf 'chemistry_registry_sha256=85d4ec8918f971787a28f59e05a037930f0090086bd7f406cbc3fc8d145ccc35\n'; \
      printf 'protocol_estuary_commit=%s\n' "${PROTOCOL_ESTUARY_COMMIT}"; \
      printf 'protocol_estuary_archive_sha256=%s\n' "${PROTOCOL_ESTUARY_SHA256}"; \
      printf 'piscem_version=%s\n' "${PISCEM_VERSION}"; \
      printf 'piscem_commit=%s\n' "${PISCEM_COMMIT}"; \
      printf 'piscem_runtime_source=official source archive build\n'; \
      printf 'piscem_source_archive_sha256=%s\n' "${PISCEM_SOURCE_SHA256}"; \
      printf 'alevin_fry_version=%s\n' "${ALEVIN_FRY_VERSION}"; \
      printf 'alevin_fry_commit=%s\n' "${ALEVIN_FRY_COMMIT}"; \
      printf 'alevin_fry_runtime_source=official source archive build\n'; \
      printf 'alevin_fry_source_archive_sha256=%s\n' "${ALEVIN_FRY_SOURCE_SHA256}"; \
      printf 'target_arch=%s\n' "${TARGETARCH}"; \
      printf 'build_arch=%s\n' "${BUILDARCH}"; \
      printf 'upstream_license=BSD-3-Clause\n'; \
      printf 'bundled_database=none\n'; \
      printf 'runtime_network_required=no_for_local_index_quant_and_workflow_inputs\n'; \
    } > /opt/simpleaf/share/doc/simpleaf/source.txt; \
    rm -rf /tmp/simpleaf-build

FROM python:${PYTHON_VERSION}-slim-bookworm AS macs-builder

ARG MACS3_VERSION=3.0.4
ARG MACS3_TAG=v3.0.4
ARG MACS3_COMMIT=e8ff0409e11d743d00c12ef44361f19ea5df9161
ARG MACS3_SDIST_URL=https://files.pythonhosted.org/packages/d5/fc/7c5e99b12260372918521d52e3749b14ffc277b092a959bbe04550425e49/macs3-3.0.4.tar.gz
ARG MACS3_SDIST_SHA256=1c2c9cc219d136b026b5e517dcbc518c3f76b9c864b8b52f00c7902f11070aef
ARG PYTHON_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_RETRIES=5 \
    PYTHONNOUSERSITE=1 \
    OPENBLAS_NUM_THREADS=1 \
    OMP_NUM_THREADS=1

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*; \
    python -m venv /opt/simpleaf/macs3

ENV PATH=/opt/simpleaf/macs3/bin:${PATH}

WORKDIR /tmp/macs3-build

RUN set -eux; \
    python -m pip install --upgrade \
        "pip==26.1.1" \
        "setuptools==82.0.1" \
        "wheel==0.47.0"; \
    python -m pip install \
        "Cython==3.0.12" \
        "numpy==1.26.4" \
        "scipy==1.13.1" \
        "scikit-learn==1.5.2" \
        "hmmlearn==0.3.3" \
        "cykhash==2.0.1"; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
        "${MACS3_SDIST_URL}" -o macs3.tar.gz; \
    echo "${MACS3_SDIST_SHA256}  macs3.tar.gz" | sha256sum -c -; \
    mkdir source; \
    tar -xzf macs3.tar.gz -C source --strip-components=1; \
    python -m pip install --no-build-isolation --no-deps ./source; \
    python -m pip check; \
    install -Dm0644 source/LICENSE /opt/simpleaf/share/licenses/macs3/LICENSE; \
    install -Dm0644 source/README.md /opt/simpleaf/share/doc/macs3/README.md; \
    install -Dm0644 source/ChangeLog /opt/simpleaf/share/doc/macs3/ChangeLog; \
    python -m pip uninstall -y Cython setuptools wheel; \
    rm -rf \
        /opt/simpleaf/macs3/lib/python3.10/site-packages/pip \
        /opt/simpleaf/macs3/lib/python3.10/site-packages/pip-*.dist-info; \
    rm -f \
        /opt/simpleaf/macs3/bin/pip \
        /opt/simpleaf/macs3/bin/pip3 \
        /opt/simpleaf/macs3/bin/pip3.10; \
    python -c 'import importlib.metadata as md; print("\n".join(sorted("%s==%s" % (d.metadata["Name"], d.version) for d in md.distributions())))' \
        > /opt/simpleaf/share/doc/macs3/python-packages.txt; \
    python -c 'import MACS3, cykhash, hmmlearn, numpy, scipy, sklearn'; \
    macs3 --version 2>&1 | grep -F "${MACS3_VERSION}" >/dev/null; \
    { \
      printf 'upstream_name=MACS3\n'; \
      printf 'upstream_version=%s\n' "${MACS3_VERSION}"; \
      printf 'upstream_tag=%s\n' "${MACS3_TAG}"; \
      printf 'upstream_commit=%s\n' "${MACS3_COMMIT}"; \
      printf 'source=%s\n' "${MACS3_SDIST_URL}"; \
      printf 'source_sha256=%s\n' "${MACS3_SDIST_SHA256}"; \
      printf 'python=%s\n' "${PYTHON_VERSION}"; \
      printf 'upstream_license=BSD-3-Clause\n'; \
    } > /opt/simpleaf/share/doc/macs3/source.txt; \
    find /opt/simpleaf/macs3 -type d -name '__pycache__' -prune -exec rm -rf '{}' +; \
    find /opt/simpleaf/macs3 -type f -name '*.pyc' -delete; \
    find /opt/simpleaf/macs3/lib/python3.10/site-packages -type d \
        \( -name tests -o -name test \) -prune -exec rm -rf '{}' +; \
    find /opt/simpleaf/macs3 -type f \( -name '*.a' -o -name '*.la' \) -delete; \
    rm -rf /tmp/macs3-build /root/.cache

FROM python:${PYTHON_VERSION}-slim-bookworm

ARG SIMPLEAF_VERSION=0.27.0
ARG PISCEM_VERSION=0.22.0
ARG ALEVIN_FRY_VERSION=0.17.1
ARG MACS3_VERSION=3.0.4
ARG TARGETARCH
ARG BUILDARCH

LABEL org.opencontainers.image.title="simpleaf" \
      org.opencontainers.image.description="TAFFISH runtime for simpleaf single-cell RNA-seq and ATAC-seq orchestration" \
      org.opencontainers.image.source="https://github.com/COMBINE-lab/simpleaf" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONNOUSERSITE=1 \
    OPENBLAS_NUM_THREADS=1 \
    OMP_NUM_THREADS=1 \
    PATH=/opt/simpleaf/bin:/opt/simpleaf/macs3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LD_LIBRARY_PATH=/opt/simpleaf/macs3/lib/python3.10/site-packages/numpy.libs:/opt/simpleaf/macs3/lib/python3.10/site-packages/scipy.libs:/opt/simpleaf/macs3/lib/python3.10/site-packages/scikit_learn.libs \
    ALEVIN_FRY_HOME=/opt/simpleaf/home

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        findutils \
        gzip \
        libgomp1 \
        libstdc++6 \
        mawk \
        unzip \
        wget \
        zlib1g; \
    rm -rf /var/lib/apt/lists/*

COPY --from=rust-assets /opt/simpleaf /opt/simpleaf
COPY --from=macs-builder /opt/simpleaf/macs3 /opt/simpleaf/macs3
COPY --from=macs-builder /opt/simpleaf/share/licenses/macs3 /opt/simpleaf/share/licenses/macs3
COPY --from=macs-builder /opt/simpleaf/share/doc/macs3 /opt/simpleaf/share/doc/macs3
COPY docker/simpleaf-smoke.py /opt/simpleaf/share/testdata/simpleaf-smoke.py
COPY docker/simpleaf-smoke.sh /opt/simpleaf/share/testdata/simpleaf-smoke.sh

RUN set -eux; \
    ln -s /opt/simpleaf/bin/simpleaf /usr/local/bin/simpleaf; \
    ln -s /opt/simpleaf/bin/piscem /usr/local/bin/piscem; \
    ln -s /opt/simpleaf/bin/alevin-fry /usr/local/bin/alevin-fry; \
    ln -s /opt/simpleaf/macs3/bin/macs3 /usr/local/bin/macs3; \
    chmod 0755 /opt/simpleaf/share/testdata/simpleaf-smoke.py; \
    chmod 0755 /opt/simpleaf/share/testdata/simpleaf-smoke.sh; \
    if [ "${BUILDARCH}" = "${TARGETARCH}" ]; then \
      /opt/simpleaf/share/testdata/simpleaf-smoke.sh buildtime /tmp/taf-simpleaf-build-check; \
    else \
      test -x /opt/simpleaf/bin/simpleaf; \
      test -x /opt/simpleaf/bin/piscem; \
      test -x /opt/simpleaf/bin/alevin-fry; \
      test -x /opt/simpleaf/macs3/bin/macs3; \
      grep -Fx "target_arch=${TARGETARCH}" /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null; \
      grep -Fx "upstream_version=${SIMPLEAF_VERSION}" /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null; \
    fi; \
    find /opt/simpleaf/macs3 -type d -name '__pycache__' -prune -exec rm -rf '{}' +; \
    find /opt/simpleaf/macs3 -type f -name '*.pyc' -delete; \
    rm -rf /tmp/taf-simpleaf-* /root/.cache

ENV TAFFISH_ENV=TAFFISH \
    TAFFISH_NAME=simpleaf \
    TAFFISH_VERSION=${SIMPLEAF_VERSION} \
    TAFFISH_RELEASE=1 \
    SIMPLEAF_VERSION=${SIMPLEAF_VERSION} \
    PISCEM_VERSION=${PISCEM_VERSION} \
    ALEVIN_FRY_VERSION=${ALEVIN_FRY_VERSION} \
    MACS3_VERSION=${MACS3_VERSION}

WORKDIR /root
