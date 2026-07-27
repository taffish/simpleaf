#!/usr/bin/env python3
import json
from pathlib import Path
import random
import sys


def write_fastq(path, records):
    with path.open("w", encoding="ascii") as handle:
        for name, sequence in records:
            handle.write(f"@{name}\n{sequence}\n+\n{'I' * len(sequence)}\n")


def barcode_umi(index):
    alphabet = "ACGT"
    chars = []
    value = index
    for _ in range(12):
        chars.append(alphabet[value % 4])
        value //= 4
    return "".join(chars)


root = Path(sys.argv[1]).resolve()
root.mkdir(parents=True, exist_ok=True)

rng = random.Random(2602)
seq1 = "".join(rng.choice("ACGT") for _ in range(220))
seq2 = "".join(rng.choice("ACGT") for _ in range(220))
(root / "ref.fa").write_text(f">tx1\n{seq1}\n>tx2\n{seq2}\n", encoding="ascii")
(root / "t2g.tsv").write_text("tx1\tgeneA\ntx2\tgeneB\n", encoding="ascii")
(root / "permit.txt").write_text("AAAAAAAAAAAAAAAA\n", encoding="ascii")

read1 = []
read2 = []
for index in range(160):
    transcript = seq1 if index % 2 == 0 else seq2
    offset = index % 80
    read1.append((f"read{index}/1", "AAAAAAAAAAAAAAAA" + barcode_umi(index)))
    read2.append((f"read{index}/2", transcript[offset : offset + 75]))
write_fastq(root / "reads1.fastq", read1)
write_fastq(root / "reads2.fastq", read2)

bed_lines = []
for index in range(80):
    start = 100 + index % 20
    bed_lines.append(f"chr1\t{start}\t{start + 36}\tplus_{index}\t255\t+\n")
    bed_lines.append(f"chr1\t{start + 8}\t{start + 44}\tminus_{index}\t255\t-\n")
(root / "reads.bed").write_text("".join(bed_lines), encoding="ascii")

workflow_out = root / "workflow-out"
manifest = {
    "meta_info": {
        "output": str(workflow_out),
        "template_version": "1.0.0",
    },
    "steps": {
        "create-marker": {
            "step": 1,
            "program_name": "touch",
            "active": True,
            "arguments": [str(workflow_out / "executed.txt")],
        }
    },
}
(root / "workflow.json").write_text(
    json.dumps(manifest, indent=2) + "\n", encoding="ascii"
)
