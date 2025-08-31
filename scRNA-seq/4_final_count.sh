#BSUB -q normal
#BSUB -J FINAL
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=6]"
#BSUB -n 6

sample=$(basename `pwd`)
mkdir out
samtools merge $sample.all.bam *.bam

dropseq_root=/share/home/hanxiaoping/tools/Drop-seq_tools-2.5.1
${dropseq_root}/DigitalExpression -m 8g \
I=$sample.all.bam \
CELL_BARCODE_TAG=XC \
MOLECULAR_BARCODE_TAG=XM \
O=$sample.dge.txt.gz \
SUMMARY=$sample.dge.summary.txt \
NUM_CORE_BARCODES=20000 \
LOCUS_FUNCTION_LIST=INTRONIC \
TMP_DIR=.

