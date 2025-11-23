#!/bin/bash
set -uo pipefail

#Step1: set files
FASTA_DIR="fasta_data"

#Step2: Indexation
while read -r id srr; do
    for ext in fasta fa fna fas; do
        file_path="${FASTA_DIR}/${srr}.${ext}"
        if [[ -f "$file_path" ]]; then
            mv "$file_path" "${FASTA_DIR}/${id}.${ext}"
            echo "✅ Renombrado: ${srr}.${ext} → ${id}.${ext}"
            break
        fi
    done
done < IDlist.txt
