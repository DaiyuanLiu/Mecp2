#BSUB -q normal
#BSUB -J rna_1-12
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=6]"
#BSUB -n 6
# 1.cutadapt
cutadapt -a CTGTCTCTTATACACATCT -A CTGTCTCTTATACACATCT -j 0 -O 16 -m 20 \
-o unaligned_R1.fastq -p unaligned_R2.fastq \
*_R1_* *_R2_* \
--info-file=poly.cut.log> poly_trim_report.txt && rm poly.cut.log 

/share/home/hanxiaoping/tools/STAR-2.7.10a/bin/Linux_x86_64_static/STAR \
	--genomeDir /share/home/hanxiaoping/tools/mm10_ucsc/STAR/ \
	--readFilesIn unaligned_R1.fastq unaligned_R2.fastq \
	--outFileNamePrefix star \
	--outSAMtype BAM SortedByCoordinate \
    --outBAMsortingThreadN 10 && rm unaligned_R*

sample=$(basename `pwd`)
featureCounts -T 10 -t exon -g gene_id -p \
	-a /share/home/hanxiaoping/tools/mm10_ucsc/STAR/mm10_ucsc.gtf \
	-o $sample.count.txt starAligned.sortedByCoord.out.bam
