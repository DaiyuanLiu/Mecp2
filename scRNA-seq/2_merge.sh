#BSUB -q normal
#BSUB -J merge
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=6]"
#BSUB -n 6

sample=$(basename `pwd`)
samtools merge $sample.bam *.bam
