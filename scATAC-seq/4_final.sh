#BSUB -q normal
#BSUB -J AgingM_merge
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=9]"
#BSUB -n 9

i=$(basename `pwd`)
str4=_UM_UQ.txt
# merge
samtools merge -n $i.shift.all.bam *shift.sort.bam

samtools view -b -q 30 -F 4 -F 256 \
    $i.shift.all.bam | \
    bedtools bamtobed -bedpe | \
    awk '{if ($1 == $4 && $9 != $10){print $0}}'> $i.bed

  python3 /share/home/hanxiaoping/tools/UU_barcode/WXY_ATAC/bedClean.py \
    $i.bed $i.clean.bed && rm $i.bed

  python3 /share/home/hanxiaoping/tools/UU_barcode/WXY_ATAC/OB_use/bedClean2.py \
    $i.clean.bed $i.filter.bed 30000 $i$str4

  cat $i.filter.bed | sort -k1,1V -k2,2n -k3,3n > $i.final.sort.bed && rm $i.filter.bed
  bgzip $i.final.sort.bed

