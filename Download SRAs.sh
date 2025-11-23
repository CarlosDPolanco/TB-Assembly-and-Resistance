#!/bin/bash
set -uo pipefail

#Step1: Set files
input_file="sra_list.txt"
RAW_DIR="fastq_data"

#Step2: .sra download and switch to fastq
echo "📥 Downloading and converting SRA accessions..."
while IFS= read -r sra; do
    echo "🔹 Processing $sra..."
    # --- Verificación previa ---
    if [[ -f "${DRAFT_DIR}/${sra}.fasta" ]]; then
        echo "⏩ $sra ya fue ensamblado, se omite."
        echo "$sra" >> "$SUCCESS_LOG"
        continue
    fi
    prefetch "$sra"
    fasterq-dump --split-files "$sra" -O "$RAW_DIR"
    echo "🧹 Removing temporary prefetch folder..."
    rm -rf "$sra"
    echo "✅ $sra downloaded and ready."
    echo "----------------------------------------"

    #step2.5: delete sras and leave .fastq
    find "$RAW_DIR" -type f -name "*.sra" -delete
done < "$input_file"