#!/bin/sh
set -eu

SIMPLEAF=/opt/simpleaf/bin/simpleaf
PISCEM=/opt/simpleaf/bin/piscem
ALEVIN_FRY=/opt/simpleaf/bin/alevin-fry
MACS3=/opt/simpleaf/macs3/bin/macs3
EXPECTED_SIMPLEAF=0.26.2
EXPECTED_PISCEM=0.21.1
EXPECTED_ALEVIN_FRY=0.16.2
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
    grep -F '"simpleaf_version": "0.26.2"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "0.21.1"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "0.16.2"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -F '"version": "3.0.4"' "${TMP_ROOT%/}/simpleaf-inspect-$$.json" >/dev/null
    grep -Fx 'upstream_commit=7fbc1ad0531df03e71888ed1a3ada98a8841d630' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'protocol_estuary_commit=3476e9fceca173cf8f31e1b921bf4d6fb409eb3c' \
        /opt/simpleaf/share/doc/simpleaf/source.txt >/dev/null
    grep -Fx 'upstream_version=0.16.2' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'runtime_source=official source archive build' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'cargo_locked=yes' \
        /opt/simpleaf/share/doc/alevin-fry/source.txt >/dev/null
    grep -Fx 'upstream_version=0.21.1' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'runtime_source=official source archive build' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'cargo_locked=yes' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'packed_seq_version=4.4.2' \
        /opt/simpleaf/share/doc/piscem/source.txt >/dev/null
    grep -Fx 'packed_seq_crate_sha256=dfb66483c3186c6582f3046d6ec8cd5e9e4db8039f6bd3ca60dce3f895b6a56c' \
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
    check_help '--anndata-out' "$SIMPLEAF" quant
    check_help '--sample-bc-list' "$SIMPLEAF" multiplex-quant
    check_help 'lookup' "$SIMPLEAF" chemistry
    check_help 'process' "$SIMPLEAF" atac
    check_help '--work-dir' "$SIMPLEAF" atac index
    check_help '--call-peaks' "$SIMPLEAF" atac process
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
    run_logged "$work/index.log" "$SIMPLEAF" index \
        --ref-seq "$work/ref.fa" \
        --output "$work/rna-index" \
        --threads 1 \
        --kmer-length 21 \
        --minimizer-length 15 \
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
        --minimizer-length 15
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
        --resolution cr-like \
        --dict tiny
    test -s "$work/quant/af_map/map.rad"
    test -s "$work/quant/af_quant/alevin/quants_mat.mtx"
    test -s "$work/quant/af_quant/alevin/quants_mat_rows.txt"
    test -s "$work/quant/af_quant/alevin/quants_mat_cols.txt"
    test -s "$work/quant/simpleaf_quant_log.json"
    grep -Fx 'AAAAAAAAAAAAAAAA' "$work/quant/af_quant/alevin/quants_mat_rows.txt" >/dev/null
    grep -Fx 'geneA' "$work/quant/af_quant/alevin/quants_mat_cols.txt" >/dev/null
    grep -Fx 'geneB' "$work/quant/af_quant/alevin/quants_mat_cols.txt" >/dev/null
    grep -F 'piscem map-sc' "$work/quant/simpleaf_quant_log.json" >/dev/null
    grep -F 'alevin-fry quant' "$work/quant/simpleaf_quant_log.json" >/dev/null
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
        index_check
        workflow_check
        macs_check
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
