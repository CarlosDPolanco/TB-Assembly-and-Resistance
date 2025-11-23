#!/bin/bash
set -uo pipefail

#Step1: Set files
FASTA_DIR="fasta_data"

#Step2: Analize resistence
for fasta in "$FASTA_DIR"/*.fasta; do
    id=$(basename "$fasta" .fasta)
    echo "🔹 Procesando ${id}..."
    tb-profiler profile --fasta "$fasta" -p "tb-${id}"
done

echo "✅ Análisis completado. Todos los resultados en el directorio actual"
