simpleaf 0.27.0-r1

Purpose:
  Build single-cell references, map and quantify sc/snRNA-seq, process
  multiplex assays and scATAC-seq, and execute simpleaf workflows.

Usage:
  taf-simpleaf -- --help
  taf-simpleaf simpleaf <subcommand> [options]

Command form:
  Subcommands are not executables: use "taf-simpleaf simpleaf index ...".

Main subcommands:
  index              Build direct, probe/feature, splici, or spliceu indexes.
  quant              Map and quantify a standard single-cell RNA sample.
  multiplex-quant    Quantify 10x Flex or custom multi-barcode assays.
  atac               Build an index or process an scATAC sample.
  chemistry          Inspect or manage chemistry definitions and resources.
  workflow           List, export, patch, run, or resume workflows.
  inspect            Show configured programs, versions, and chemistries.
  set-paths          Initialize a custom ALEVIN_FRY_HOME.

Direct reference index:
  taf-simpleaf simpleaf index \
    --ref-seq transcripts.fa --output index-out --threads 8 --ram-limit-gib 8

Splici index:
  taf-simpleaf simpleaf index \
    --fasta genome.fa --gtf genes.gtf --ref-type spliced+intronic \
    --rlen 91 --output index-out --threads 8

Paired 10x quantification:
  taf-simpleaf simpleaf quant \
    --chemistry 10xv3 --index index-out/index \
    --reads1 sample_R1.fastq.gz --reads2 sample_R2.fastq.gz \
    --output sample-quant --threads 8 --decoder auto --with-position \
    --unfiltered-pl barcodes.txt --resolution cr-like-em --small-thresh 0

Permit lists:
  Use one of --knee, --expect-cells, --forced-cells, --explicit-pl, or
  --unfiltered-pl. Provide --t2g-map when the index has no gene map.

Other interfaces:
  taf-simpleaf simpleaf multiplex-quant --help
  taf-simpleaf simpleaf atac index --help
  taf-simpleaf simpleaf atac process --help
  taf-simpleaf simpleaf chemistry lookup --name 10xv3
  taf-simpleaf simpleaf workflow run --manifest workflow.json

Bundled runtime:
  simpleaf 0.27.0, piscem 0.22.0, alevin-fry 0.17.1, MACS3 3.0.4,
  the tagged chemistry registry, and a pinned protocol-estuary snapshot.
  Native linux/amd64 and linux/arm64 images; CPU only. Companion commands:
  taf-simpleaf piscem --version
  taf-simpleaf alevin-fry --version
  taf-simpleaf macs3 --version

Configuration:
  ALEVIN_FRY_HOME is preconfigured. Changes are ephemeral unless it points to
  a host-mounted directory. Run "taf-simpleaf simpleaf set-paths" once in a
  fresh persistent home; mount and registry details are in README.md.

Network and data:
  Explicit local index/quant runs are offline. Refresh/fetch, automatic assay
  resource retrieval, or remote workflow commands need network. No reference
  genome, complete barcode/probe resource, or database is bundled.

Workflow boundary:
  Templates may name arbitrary programs. The RNA/ATAC stack and common shell
  tools are present; custom dependencies are not inferred.

Performance:
  --threads is shared by mapping and gzip decoding; index RAM defaults to 8 GiB.
  Use --tmp-dir/--work-dir scratch. amd64 is scalar; arm64 uses baseline NEON.

Key outputs:
  index_info.json, simpleaf_index_log.json, index/simpleaf_index.json
  af_map/map.rad, af_quant/alevin/quants_mat.mtx and labels, provenance logs

Documentation:
  https://github.com/taffish/simpleaf
  https://combine-lab.github.io/simpleaf/
  https://combine-lab.github.io/alevin-fry-tutorials/
Wrapper options:
  taf-simpleaf --help       Show this TAFFISH help.
  taf-simpleaf --version    Show the TAFFISH wrapper version.
  taf-simpleaf --compile    Print the generated wrapper shell.
  taf-simpleaf -- --help    Pass --help to the default simpleaf command.
License: TAFFISH Apache-2.0; bundled upstream components BSD-3-Clause.
