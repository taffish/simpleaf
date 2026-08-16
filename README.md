# simpleaf

`simpleaf` packages the COMBINE-lab single-cell RNA-seq and ATAC-seq
orchestrator for TAFFISH. The image is ready to run: compatible versions of
`piscem`, `alevin-fry` and `macs3` are configured inside the container, and
versioned chemistry and workflow registries are available offline.

## Package Identity

- Name: `simpleaf`
- Command: `taf-simpleaf`
- Kind: `tool`
- TAFFISH version: `0.28.0-r1`
- Container image: `ghcr.io/taffish/simpleaf:0.28.0-r1`
- Upstream release: [`v0.28.0`](https://github.com/COMBINE-lab/simpleaf/releases/tag/v0.28.0)
- Upstream commit: `02851cc02a8bbad6ea84035b38b93555d694d2ec`
- Native platforms: `linux/amd64`, `linux/arm64`
- TAFFISH app license: `Apache-2.0`
- Upstream license: `BSD-3-Clause`

The official architecture-specific simpleaf assets are pinned by SHA256:

| Platform | Release asset SHA256 |
| --- | --- |
| `linux/amd64` | `9fc55a8472a4a6ca3fb5f9d93cb836744e9a9db5337a24fd57c03a487702cc38` |
| `linux/arm64` | `8cb38756363f4ce819747fd0a7415a95a8a59fbad1a32527bf5a575ed70e38a9` |

`piscem 0.22.0` and `alevin-fry 0.18.0` are built from their checksum-pinned
official source archives with their upstream `Cargo.lock` files and Rust
`1.96.0`. Generic CPU baselines replace upstream release tuning so the images
run on the full declared platform baseline. On `linux/amd64`, piscem's locked
`packed-seq 5.0.0` dependency is explicitly given its documented `scalar`
feature; this avoids an upstream AVX2 requirement without changing dependency
versions. The `linux/arm64` build uses the generic ARM/NEON path unchanged.

## Installation

```sh
taf update
taf install simpleaf
```

For local validation before publication, use `taf install --from .` in this
app directory.

## Scope

The app exposes the complete simpleaf `v0.28.0` command surface:

- direct, probe CSV, feature CSV, splici and spliceu reference indexing
- standard sc/snRNA-seq mapping and quantification through piscem and
  alevin-fry
- multiplexed quantification for 10x Flex and custom multi-barcode assays
- scATAC-seq indexing, mapping, barcode processing, fragment output and MACS3
  peak calling
- local chemistry lookup, addition, removal, cleanup and resource fetching
- Jsonnet workflow listing, export, patching, execution, resume and step control
- optional AnnData output supported by simpleaf's built-in Rust implementation
- shared mapping/decompression budgets with explicit decoder and thread-policy controls
- bounded piscem index scratch/RAM controls and optional positional RAD output
- explicit tiny-cell thresholds and sample-barcode orientation for multiplex assays
- deterministic cell/sample-barcode correction policy, neighbourhood and
  confidence controls, plus stage-specific GPL/collate resource limits

Simpleaf workflows may name arbitrary external commands. The image provides
the simpleaf RNA/ATAC stack and common shell/download utilities, but it cannot
anticipate every executable named by a custom or future workflow template.

Version 0.28.0 requires piscem 0.22.0 or newer and alevin-fry 0.18.0 or newer;
`set-paths` rejects older binaries. Requests below two threads warn and are
raised to two, then the effective count is used consistently across mapping,
permit-list generation, collation or ATAC sorting, and quantification. Index
builds default to an 8 GiB `--ram-limit-gib`; override it and `--tmp-dir`
explicitly for local HPC scratch policies.

## Container Contents

| Component | Version or snapshot | Purpose |
| --- | --- | --- |
| `simpleaf` | `0.28.0` | Orchestration, reference construction and registries |
| `piscem` | `0.22.0` | RNA/ATAC index construction and mapping |
| `alevin-fry` | `0.18.0` | Deterministic barcode correction, RAD processing and quantification |
| `macs3` | `3.0.4` | Optional ATAC peak calling |
| Chemistry registry | simpleaf `v0.28.0` | Geometry and remote resource definitions |
| Protocol estuary | commit `3476e9fceca173cf8f31e1b921bf4d6fb409eb3c` | Offline workflow templates and Jsonnet utilities |

The final image contains no compiler, Cargo registry, package-manager cache,
reference genome, complete barcode whitelist, probe set or biological
database. Piscem and alevin-fry are source-built in disposable builder stages.
MACS3 is built from its checksum-pinned PyPI source distribution; its runtime
Python dependencies are pinned and development caches are removed.

## Command Mode

Simpleaf operations are subcommands, so use the explicit upstream command in
normal work:

```sh
taf-simpleaf simpleaf inspect
taf-simpleaf simpleaf index --help
taf-simpleaf simpleaf quant --help
```

Without the second `simpleaf`, TAFFISH automatic command mode may interpret a
subcommand such as `index` as another executable. Wrapper and upstream help
are distinct:

```sh
taf-simpleaf --help
taf-simpleaf --version
taf-simpleaf -- --help
taf-simpleaf simpleaf --version
```

The bundled companion commands are also directly available:

```sh
taf-simpleaf piscem --version
taf-simpleaf alevin-fry --version
taf-simpleaf macs3 --version
```

## Indexing

Build an index directly from transcript or probe sequences:

```sh
taf-simpleaf simpleaf index \
  --ref-seq transcripts.fa \
  --output index-out \
  --threads 8 \
  --tmp-dir local-sshash-scratch \
  --ram-limit-gib 8
```

Build a spliced plus intronic reference and index from a genome and annotation:

```sh
taf-simpleaf simpleaf index \
  --fasta genome.fa \
  --gtf genes.gtf \
  --ref-type spliced+intronic \
  --rlen 91 \
  --output index-out \
  --threads 8
```

Use `--gff3-format` for GFF3 input. `--probe-csv` and `--feature-csv` expose
the corresponding upstream direct-reference modes. Piscem index construction
creates many temporary files; use a local scratch path with `--work-dir` and
raise the file-descriptor limit to at least 2048 for production references.

## RNA Quantification

An ordinary 10x v3 path is:

```sh
taf-simpleaf simpleaf quant \
  --chemistry 10xv3 \
  --index index-out/index \
  --reads1 sample_R1.fastq.gz \
  --reads2 sample_R2.fastq.gz \
  --output sample-quant \
  --threads 8 \
  --decoder auto \
  --cell-bc-correction frequency \
  --cell-bc-neighborhood hamming-1 \
  --cell-bc-confidence 39/40 \
  --collate-memory-limit 2GiB \
  --small-thresh 0 \
  --expected-ori fw \
  --unfiltered-pl barcodes.txt \
  --resolution cr-like-em
```

Use one permit-list strategy: `--knee`, `--expect-cells`, `--forced-cells`,
`--explicit-pl`, or `--unfiltered-pl`. A transcript-to-gene map is inferred
from a simpleaf-built splici/probe index when available; otherwise provide
`--t2g-map`. Multiple read files are comma-separated and must be ordered
consistently between read 1 and read 2.

For 10x Flex or another multi-barcode protocol, use:

```sh
taf-simpleaf simpleaf multiplex-quant --help
```

This interface supports explicit or registry-derived geometry, cell and sample
barcode lists, probe sets, reusable indexes, independent cell/sample correction
controls, `--gpl-memory-limit`, `--gpl-tmp-dir`, `--collate-memory-limit`,
`--sample-bc-ori`, `--small-thresh`, decoder controls and optional
`--anndata-out`.

## scATAC-seq

Build a genome index:

```sh
taf-simpleaf simpleaf atac index \
  --input genome.fa \
  --output atac-index \
  --work-dir local-scratch \
  --threads 8
```

Inspect the exact assay and read-layout options before processing:

```sh
taf-simpleaf simpleaf atac process --help
```

The processing path uses piscem for mapping and alevin-fry for barcode and
fragment processing. Version 0.28.0 also forwards deterministic cell-barcode
correction controls. MACS3 is invoked only when `--call-peaks` is set; ordinary
ATAC processing no longer requires it. This image still bundles MACS3 `3.0.4`
for the opt-in peak-calling path. Supply an explicit unfiltered barcode list to
keep the run offline.

## Chemistry And Workflows

The tagged chemistry definitions and a pinned protocol-estuary snapshot are
available without network access:

```sh
taf-simpleaf simpleaf chemistry lookup --name 10xv3
taf-simpleaf simpleaf workflow list
taf-simpleaf simpleaf workflow get \
  --name simpleaf-index --output workflow-templates
taf-simpleaf simpleaf workflow run --manifest workflow.json
```

`workflow run` executes both simpleaf steps and external commands declared by
the manifest. Review a template before execution. An absent external program
is a workflow dependency, not something simpleaf can infer or install safely.

## Configuration And Persistence

The image sets `ALEVIN_FRY_HOME=/opt/simpleaf/home`. Its preconfigured
`simpleaf_info.json` points to the bundled programs, so `set-paths` is not
required for normal use. The default chemistry and workflow snapshots are
part of the immutable image provenance.

Changes made by `chemistry add`, `chemistry remove`, `chemistry fetch`,
`chemistry refresh`, `workflow refresh`, or `set-paths` live only in that
container invocation unless `ALEVIN_FRY_HOME` points to a host-mounted
directory. For a persistent Docker-backed home:

```sh
mkdir -p "$PWD/simpleaf-home"

TAFFISH_DOCKER_RUN_ARGS="-e ALEVIN_FRY_HOME=/simpleaf-home -v $PWD/simpleaf-home:/simpleaf-home" \
  taf-simpleaf simpleaf set-paths

TAFFISH_DOCKER_RUN_ARGS="-e ALEVIN_FRY_HOME=/simpleaf-home -v $PWD/simpleaf-home:/simpleaf-home" \
  taf-simpleaf simpleaf inspect
```

Keep the same mount and environment arguments for later commands. Podman uses
the equivalent `TAFFISH_PODMAN_RUN_ARGS`. A fresh custom home contains program
paths only after `set-paths`; copy or refresh chemistry/workflow registries if
those features are needed there.

## Network And Resource Boundaries

Local indexing and quantification with explicit files are offline. Network is
used only when requested by operations such as:

- `chemistry refresh` and `workflow refresh`
- `chemistry fetch`
- automatic permit-list, sample-barcode or probe-set retrieval
- external commands in a workflow that contact remote services

The chemistry registry contains URLs and hashes or names, not all referenced
data. To keep a run offline, provide permit lists, probe sets, indexes and
other resources explicitly. No reference genome or biological database is
bundled.

## Inputs And Outputs

| Item | Meaning |
| --- | --- |
| Genome FASTA plus GTF/GFF3 | Input for splici or spliceu construction |
| Reference FASTA or probe/feature CSV | Direct index input |
| Paired FASTQ files | Barcode/UMI and biological reads for RNA quantification |
| Barcode/probe resources | Explicit local files or opt-in registry downloads |
| `index_info.json`, `simpleaf_index_log.json` | Reference and index provenance |
| `index/simpleaf_index.json` | Resolved piscem index metadata |
| `af_map/` | Piscem mapping output, including RAD data |
| `af_quant/alevin/` | Matrix Market counts and row/column labels |
| `simpleaf_quant_log.json` | Mapping and quantification command provenance |
| `simpleaf_workflow_log.json` | Workflow execution status and timing |

Keep JSON logs and matrix label files with the results. Fixture smoke tests
verify packaging behavior; production chemistry selection, filtering,
resolution and biological interpretation remain study-specific decisions.

## Platform And Performance

Native images are available for `linux/amd64` and `linux/arm64`. All packaged
programs are CPU-based. Use `--threads` to control parallelism. For large
indexes, place `--work-dir` and preferably output on local scratch rather than
NFS, and make at least 2048 file descriptors available to the container.

The amd64 piscem build favors broad x86-64 compatibility over the upstream
AVX2-tuned release profile. It has the same command and file-format behavior,
but indexing and mapping may be slower than an AVX2-native upstream build. The
arm64 image uses the architecture's baseline NEON support.

## Testing

The independent offline smoke suite checks:

- exact identities, commits, checksums, licenses and dynamic-library closure
- locked source-build and architecture-specific CPU-policy provenance
- every simpleaf command family plus companion-program interfaces
- default and newly initialized `ALEVIN_FRY_HOME` configuration
- offline chemistry lookup and workflow registry export
- real direct-reference RNA and scATAC piscem index construction
- real tiny paired-read mapping, permit-list processing, collation and RNA
  quantification through simpleaf, including positional RAD, decoder policy
  forwarding, deterministic correction controls, bounded collation, the
  two-thread floor and explicit tiny-cell resolution
- real manifest execution with workflow provenance logs
- real MACS3 peak calling on deterministic BED input

It does not perform production-scale biological validation, download remote
assay resources, or execute every external command named by every registry
workflow.

## Documentation And License

- [Upstream repository](https://github.com/COMBINE-lab/simpleaf)
- [Simpleaf documentation](https://combine-lab.github.io/simpleaf/)
- [Alevin-fry tutorials](https://combine-lab.github.io/alevin-fry-tutorials/)
- [Protocol estuary](https://github.com/COMBINE-lab/protocol-estuary)
- [Release `v0.28.0`](https://github.com/COMBINE-lab/simpleaf/releases/tag/v0.28.0)

TAFFISH packaging code and documentation use Apache-2.0. Simpleaf, piscem,
alevin-fry, MACS3 and protocol-estuary retain their upstream BSD-3-Clause
licenses. Follow upstream project and component guidance when citing results.
