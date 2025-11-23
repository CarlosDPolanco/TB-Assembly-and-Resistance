#!/bin/bash
set -uo pipefail

#Step1: Set files
RAW_DIR="fastq_data"
PREQUALITY_DIR="fastqc_reports"
POSQUALITY_DIR="trimming_reports"
TRIMMED_DIR="trimmed_reads"
ASSEMBLY_DIR="spades_output"
DRAFT_DIR="fasta_data"
ADAPTERS="TruSeq3-PE.fa"
SUCCESS_LOG="success.txt"

#Step1.5: Set threads (it depends the capacity of your PC)
THREADS=8

#Step2: Quality control
echo "🔍 Running FastQC..."
fastqc "$RAW_DIR"/*.fastq -o "$PREQUALITY_DIR" -t "$THREADS"
multiqc "$RAW_DIR" -o "$PREQUALITY_DIR" --quiet || true

#Step2.5: remove useless data (.zip and .html repots) (remove it you need)
find "$PREQUALITY_DIR" -type f -name "*_fastqc.zip" -delete
find "$PREQUALITY_DIR" -type f -name "*_fastqc.html" -delete

#Step3: trimming
echo "✂️ Trimming reads..."
for R1 in "$RAW_DIR"/*_1.fastq; do
    sample=$(basename "$R1" _1.fastq)
    R1="${RAW_DIR}/${sample}_1.fastq"
    R2="${RAW_DIR}/${sample}_2.fastq"
    OUT1="${TRIMMED_DIR}/${sample}_R1_paired.fastq.gz"
    OUT2="${TRIMMED_DIR}/${sample}_R2_paired.fastq.gz"
    UNP1="${TRIMMED_DIR}/${sample}_R1_unpaired.fastq.gz"
    UNP2="${TRIMMED_DIR}/${sample}_R2_unpaired.fastq.gz"

    trimmomatic PE -threads "$THREADS" -phred33 "$R1" "$R2" \
        "$OUT1" "$UNP1" "$OUT2" "$UNP2" \
        ILLUMINACLIP:$ADAPTERS:2:30:10 SLIDINGWINDOW:4:20 MINLEN:50

    #Step3.5: remove useless data (unpaired fastq)
    rm -f "$UNP1" "$UNP2"
    #rm -f "$R1" "$R2" (If you want to remove original fastq, to optimize storage)
done

#Step4: Quality control
echo "🔍 Running FastQC..."
fastqc "$TRIMMED_DIR"/*.fastq -o "$POSQUALITY_DIR" -t "$THREADS"
multiqc "$TRIMMED_DIR" -o "$POSQUALITY_DIR" --quiet || true

#Step4.5: remove useless data (.zip and .html repots) (remove it you need)
find "$POSQUALITY_DIR" -type f -name "*_fastqc.zip" -delete
find "$POSQUALITY_DIR" -type f -name "*_fastqc.html" -delete

#Step5: assembly
echo "🧬 Running SPAdes assembly..."
for R1 in "$TRIMMED_DIR"/*_R1_paired.fastq.gz; do
    sample=$(basename "$R1" _R1_paired.fastq.gz)
    echo "🔹 Assembling sample: $sample"

    R1="${TRIMMED_DIR}/${sample}_R1_paired.fastq.gz"
    R2="${TRIMMED_DIR}/${sample}_R2_paired.fastq.gz"
    OUTDIR="${ASSEMBLY_DIR}/${sample}_spades"

    mkdir -p "$OUTDIR"

    spades.py \
        -1 "$R1" \
        -2 "$R2" \
        -o "$OUTDIR" \
        -t "$THREADS" \
        --careful

    if [[ -f "${OUTDIR}/contigs.fasta" ]]; then
        cp "${OUTDIR}/contigs.fasta" "${DRAFT_DIR}/${sample}.fasta"
        echo "✅ Assembly completed for $sample"
        echo "$sample" >> "$SUCCESS_LOG"
    else
        echo "⚠️ No contigs.fasta found for $sample — check SPAdes logs."
    fi

    #Step5.5 remove useless data 
    rm -f "$R1" "$R2" #trimmed reads, useless now
    rm -rf "$ASSEMBLY_DIR"/* || true #dir with intermediate archives

    echo "---------------------------------------------"
done

#Step6: final cleanup
echo "🧹 Final cleanup..."
find "$ASSEMBLY_DIR" -type d -empty -delete
echo "🎉 Pipeline completed successfully."
echo "📝 Successful samples logged in $SUCCESS_LOG"