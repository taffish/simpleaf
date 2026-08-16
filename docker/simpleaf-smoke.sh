#!/bin/sh
set -eu

SIMPLEAF=/opt/simpleaf/bin/simpleaf
PISCEM=/opt/simpleaf/bin/piscem
ALEVIN_FRY=/opt/simpleaf/bin/alevin-fry
MACS3=/opt/simpleaf/macs3/bin/macs3
EXPECTED_SIMPLEAF=0.28.0
EXPECTED_PISCEM=0.22.0
EXPECTED_ALEVIN_FRY=0.18.0
EXPECTED_MACS3=3.0.4
MODE=${1:-}
TMP_ROOT=${2:-/tmp}

mkdir -p "$TMP_ROOT"

fail() {
    printf 'simpleaf smoke: %s\n' "$*" >&2
    exit 1
}

new_workdir() {
    work="${TMP_ROOT%/}/taf-simpleaf-${MODE}-$$"
    rm -rf "$work"
    mkdir -p "$work"
    python /opt/simpleaf/share/testdata/simpleaf-smoke.py "$work"
}

run_logged() {
    log_file=$1
    shift
    if ! "$@" >"$log_file" 2>&1; then
        cat "$log_file" >&2
        return 1
    fi
}

check_help() {
    marker=$1
    shift
    "$@" --help >"$help_file" 2>&1
    grep -F -- "$marker" "$help_file" >/dev/null
}

identity_check() {
    [ "$($SIMPLEAF --version 2>&1)" = "simpleaf ${EXPECTED_SIMPLEAF}" ] || \
        fail "unexpected simpleaf version"
    [ "$($PISCEM --version 2>&1)" = "piscem ${EXPECTED_PISCEM}" ] || \
        fail "unexpected piscem version"
    [ "$($ALEVIN_FRY --version 2>&1)" = "alevin-fry ${EXPECTED_ALEVIN_FRY}" ] || \
        fail "unexpected alevin-fry version"
    "$MACS3" --version 2>&1 | grep -F "$EXPECTED_MACS3" >/dev/null
    RUST_LOG=warn "$SIMPLEAF" inspect >"${TMP_ROOT%/}/simpleaf-inspect-$$.json" 2>&1
    grep -F '"simpleaf_version": "0.28.0"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "0.22.0"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "0.18.0"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "3.0.4"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -Fx 'upstream_commit=02851cc02a8bbad6ea84035b38b93555d694d2ec' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'linux_amd64_asset_sha256=9fc55a8472a4a6ca3fb5f9d93cb836744e9a9db5337a24fd57c03a487702cc38' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'linux_arm64_asset_sha256=8cb38756363f4ce819747fd0a7415a95a8a59fbad1a32527bf5a575ed70e38a9' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'source_archive_sha256=6291a33bf2c4a624ec9e07810dda18e48b7160d0cf4c6fb954aad55c593cfb7e' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'chemistry_registry_sha256=85d4ec8918f971787a28f59e05a037930f0090086bd7f406cbc3fc8d145ccc35' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'protocol_estuary_commit=3476e9fceca173cf8f31e1b921bf4d6fb409eb3c' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'upstream_version=0.18.0' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'upstream_commit=85d0732413c7fc6352fb55c4a7c151f1a07c29e2' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'source_archive_sha256=fe926aa37f937d25c62e2766ddeec3ad31d7567378ae135ce6ad411668a7475c' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'runtime_source=official source archive build' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'cargo_locked=yes' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'upstream_version=0.22.0' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'runtime_source=official source archive build' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'cargo_locked=yes' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'packed_seq_version=5.0.0' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'packed_seq_crate_sha256=5a3a89b413dff56614047583dad3cc5c4a61ad16a436a578dfaf8c214e98734a' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    case "$(uname -m)" in
        x86_64)
            grep -Fx 'target_arch=amd64' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'rustflags=-C target-cpu=x86-64' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'cpu_mode=scalar' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'packaging_patch=add locked packed-seq direct dependency with scalar feature for generic x86-64' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            ;;
        aarch64)
            grep -Fx 'target_arch=arm64' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'rustflags=-C target-cpu=generic' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'cpu_mode=neon' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            grep -Fx 'packaging_patch=none' \
                /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
            ;;
        *) fail "unexpected runtime architecture: $(uname -m)" ;;
    esac
    test -s /opt/simpleaf/home/chemistries.json
    test -d /opt/simpleaf/home/protocol-estuary/protocol-estuary-main/protocols
    test -s /opt/simpleaf/share/licenses/simpleaf/LICENSE
    test -s /opt/simpleaf/share/licenses/piscem/LICENSE
    test -s /opt/simpleaf/share/licenses/alevin-fry/LICENSE
    test -s /opt/simpleaf/share/licenses/macs3/LICENSE
    test -s /opt/simpleaf/share/licenses/protocol-estuary/LICENSE
    for binary in "$SIMPLEAF" "$PISCEM" "$ALEVIN_FRY"; do
        ldd "$binary" >"${TMP_ROOT%/}/simpleaf-ldd-$$.txt" 2>&1
        grep -F 'libc.so.6' "${TMP_ROOT%/}/simpleaf-ldd-$$.txt" >/dev/null
        if grep -F 'not found' "${TMP_ROOT%/}/simpleaf-ldd-$$.txt" >/dev/null; then
            cat "${TMP_ROOT%/}/simpleaf-ldd-$$.txt" >&2
            fail "missing dynamic library for $binary"
        fi
    done
    python -c 'import importlib.metadata as md; import MACS3, numpy, scipy, sklearn, hmmlearn, cykhash; assert md.version("MACS3") == "3.0.4"'
    find /opt/simpleaf/macs3 -type f -name '*.so' -print0 | \
        xargs -0 -r ldd >"${TMP_ROOT%/}/simpleaf-python-ldd-$$.txt"
    if grep -F 'not found' "${TMP_ROOT%/}/simpleaf-python-ldd-$$.txt" >/dev/null; then
        cat "${TMP_ROOT%/}/simpleaf-python-ldd-$$.txt" >&2
        fail "missing Python extension library"
    fi
    rm -f "${TMP_ROOT%/}/simpleaf-inspect-$$.json" \
        "${TMP_ROOT%/}/simpleaf-ldd-$$.txt" \
        "${TMP_ROOT%/}/simpleaf-python-ldd-$$.txt"
}

interfaces_check() {
    help_file="${TMP_ROOT%/}/taf-simpleaf-help-$$.txt"
    check_help 'multiplex-quant' "$SIMPLEAF"
    check_help '--probe-csv' "$SIMPLEAF" index
    check_help '--tmp-dir' "$SIMPLEAF" index
    check_help '--ram-limit-gib' "$SIMPLEAF" index
    check_help '--anndata-out' "$SIMPLEAF" quant
    check_help '--decoder' "$SIMPLEAF" quant
    check_help '--thread-policy' "$SIMPLEAF" quant
    check_help '--with-position' "$SIMPLEAF" quant
    check_help '--small-thresh' "$SIMPLEAF" quant
    check_help '--cell-bc-correction' "$SIMPLEAF" quant
    check_help '--cell-bc-neighborhood' "$SIMPLEAF" quant
    check_help '--cell-bc-confidence' "$SIMPLEAF" quant
    check_help '--collate-memory-limit' "$SIMPLEAF" quant
    check_help '--sample-bc-list' "$SIMPLEAF" multiplex-quant
    check_help '--sample-bc-ori' "$SIMPLEAF" multiplex-quant
    check_help '--small-thresh' "$SIMPLEAF" multiplex-quant
    check_help '--sample-bc-correction' "$SIMPLEAF" multiplex-quant
    check_help '--sample-bc-neighborhood' "$SIMPLEAF" multiplex-quant
    check_help '--sample-bc-confidence' "$SIMPLEAF" multiplex-quant
    check_help '--gpl-memory-limit' "$SIMPLEAF" multiplex-quant
    check_help '--gpl-tmp-dir' "$SIMPLEAF" multiplex-quant
    check_help '--collate-memory-limit' "$SIMPLEAF" multiplex-quant
    check_help 'lookup' "$SIMPLEAF" chemistry
    check_help 'process' "$SIMPLEAF" atac
    check_help '--work-dir' "$SIMPLEAF" atac index
    check_help '--ram-limit-gib' "$SIMPLEAF" atac index
    check_help '--call-peaks' "$SIMPLEAF" atac process
    check_help '--decoder' "$SIMPLEAF" atac process
    check_help '--thread-policy' "$SIMPLEAF" atac process
    check_help '--barcode-length' "$SIMPLEAF" atac process
    check_help '--cell-bc-correction' "$SIMPLEAF" atac process
    check_help '--cell-bc-neighborhood' "$SIMPLEAF" atac process
    check_help '--cell-bc-confidence' "$SIMPLEAF" atac process
    check_help 'patch' "$SIMPLEAF" workflow
    check_help '--manifest' "$SIMPLEAF" workflow run
    check_help 'map-sc' "$PISCEM"
    check_help 'generate-permit-list' "$ALEVIN_FRY"
    check_help 'callpeak' "$MACS3"
    rm -f "$help_file"
}

registry_check() {
    new_workdir
    RUST_LOG=warn "$SIMPLEAF" chemistry lookup --name 10xv3 >"$work/chemistry.json"
    grep -F '1{b[16]u[12]x:}2{r:}' "$work/chemistry.json" >/dev/null
    RUST_LOG=warn "$SIMPLEAF" chemistry lookup \
        --name 10x-flexv2-gex-3p-config-b >"$work/flexv2-chemistry.json"
    grep -F 'CCCATATAAGAAAACCTGAATACGCGGTT' "$work/flexv2-chemistry.json" >/dev/null
    grep -F '737K-flex-v2.txt' "$work/flexv2-chemistry.json" >/dev/null
    grep -F '"sample_bc_ori": "forward"' /opt/simpleaf/home/chemistries.json >/dev/null
    RUST_LOG=warn "$SIMPLEAF" workflow list >"$work/workflows.txt"
    grep -F 'simpleaf-index' "$work/workflows.txt" >/dev/null
    RUST_LOG=warn "$SIMPLEAF" workflow get \
        --name simpleaf-index --output "$work/export" >"$work/get.log" 2>&1
    test -s "$work/export/simpleaf-index_template/simpleaf-index.jsonnet"
    custom_home="$work/custom-home"
    ALEVIN_FRY_HOME="$custom_home" RUST_LOG=warn "$SIMPLEAF" set-paths
    test -s "$custom_home/simpleaf_info.json"
    ALEVIN_FRY_HOME="$custom_home" RUST_LOG=warn "$SIMPLEAF" inspect >"$work/custom-inspect.json" 2>&1
    grep -F '"version": "3.0.4"' "$work/custom-inspect.json" >/dev/null
    rm -rf "$work"
}

index_check() {
    new_workdir
    mkdir -p "$work/rna-tmp" "$work/atac-tmp"
    run_logged "$work/index.log" "$SIMPLEAF" index \
        --ref-seq "$work/ref.fa" \
        --output "$work/rna-index" \
        --threads 1 \
        --kmer-length 21 \
        --minimizer-length 15 \
        --tmp-dir "$work/rna-tmp" \
        --ram-limit-gib 1 \
        --dict tiny
    test -s "$work/rna-index/index/piscem_idx.ctab"
    test -s "$work/rna-index/index/piscem_idx.refinfo"
    test -s "$work/rna-index/index/piscem_idx.ssi"
    test -s "$work/rna-index/index/piscem_idx.ssi.mphf"
    grep -F '"index_type": "piscem"' "$work/rna-index/index/simpleaf_index.json" >/dev/null
    run_logged "$work/atac-index.log" "$SIMPLEAF" atac index \
        --input "$work/ref.fa" \
        --output "$work/atac-index" \
        --work-dir "$work/atac-work" \
        --threads 1 \
        --kmer-length 21 \
        --minimizer-length 15 \
        --tmp-dir "$work/atac-tmp" \
        --ram-limit-gib 1
    test -s "$work/atac-index/index/piscem_idx.ctab"
    test -s "$work/atac-index/index/simpleaf_index.json"
    grep -F 'piscem build' "$work/atac-index/index/simpleaf_index.json" >/dev/null
    rm -rf "$work"
}

quant_check() {
    new_workdir
    run_logged "$work/index.log" "$SIMPLEAF" index \
        --ref-seq "$work/ref.fa" \
        --output "$work/index" \
        --threads 1 \
        --kmer-length 21 \
        --minimizer-length 15 \
        --dict tiny
    run_logged "$work/quant.log" "$SIMPLEAF" quant \
        --chemistry '1{b[16]u[12]x:}2{r:}' \
        --output "$work/quant" \
        --threads 1 \
        --index "$work/index/index" \
        --reads1 "$work/reads1.fastq" \
        --reads2 "$work/reads2.fastq" \
        --explicit-pl "$work/permit.txt" \
        --t2g-map "$work/t2g.tsv" \
        --decoder serial \
        --thread-policy "$work/thread-policy.json" \
        --with-position \
        --cell-bc-correction frequency \
        --cell-bc-neighborhood hamming-1 \
        --cell-bc-confidence 39/40 \
        --collate-memory-limit 256MiB \
        --small-thresh 0 \
        --resolution cr-like \
        --dict tiny
    test -s "$work/quant/af_map/map.rad"
    test -s "$work/quant/af_quant/alevin/quants_mat.mtx"
    test -s "$work/quant/af_quant/alevin/quants_mat_rows.txt"
    test -s "$work/quant/af_quant/alevin/quants_mat_cols.txt"
    test -s "$work/quant/af_quant/correction_plan.bin"
    test -s "$work/quant/simpleaf_quant_log.json"
    grep -Fx 'AAAAAAAAAAAAAAAA' "$work/quant/af_quant/alevin/quants_mat_rows.txt" >/dev/null
    grep -Fx 'geneA' "$work/quant/af_quant/alevin/quants_mat_cols.txt" >/dev/null
    grep -Fx 'geneB' "$work/quant/af_quant/alevin/quants_mat_cols.txt" >/dev/null
    grep -F 'piscem map-sc' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F 'alevin-fry quant' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--decoder serial' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--with-position' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--small-thresh 0' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--cell-bc-correction frequency' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--cell-bc-neighborhood hamming-1' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--cell-bc-confidence 39/40' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '--memory-limit 256MiB' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F -- '-t 2' "$work/quant/simpleaf_quant_log.json" >/dev/null
    rm -rf "$work"
}

workflow_check() {
    new_workdir
    run_logged "$work/workflow.log" "$SIMPLEAF" workflow run \
        --manifest "$work/workflow.json"
    test -f "$work/workflow-out/executed.txt"
    test -s "$work/workflow-out/simpleaf_workflow_log.json"
    test -s "$work/workflow-out/workflow_execution_log.json"
    grep -F '"Succeed": true' "$work/workflow-out/simpleaf_workflow_log.json" >/dev/null
    rm -rf "$work"
}

macs_check() {
    new_workdir
    run_logged "$work/macs.log" "$MACS3" callpeak \
        -t "$work/reads.bed" \
        -f BED \
        -g 1000 \
        -n smoke \
        --outdir "$work/macs" \
        --nomodel \
        --extsize 50 \
        --shift 0 \
        --keep-dup all \
        -B \
        --nolambda \
        -p 0.99
    test -s "$work/macs/smoke_peaks.xls"
    test -s "$work/macs/smoke_treat_pileup.bdg"
    grep -F 'chr1' "$work/macs/smoke_treat_pileup.bdg" >/dev/null
    rm -rf "$work"
}

case "$MODE" in
    buildtime)
        identity_check
        interfaces_check
        ;;
    identity)
        identity_check
        ;;
    interfaces)
        interfaces_check
        ;;
    registry)
        registry_check
        ;;
    index)
        index_check
        ;;
    quant)
        quant_check
        ;;
    workflow)
        workflow_check
        ;;
    macs)
        macs_check
        ;;
    *)
        fail 'usage: simpleaf-smoke.sh {buildtime|identity|interfaces|registry|index|quant|workflow|macs} [tmp-root]'
        ;;
esac

printf 'simpleaf smoke %s: PASS\n' "$MODE"
