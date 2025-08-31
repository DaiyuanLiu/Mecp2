#BSUB -q normal
#BSUB -J bowtie2
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=9]"
#BSUB -n 9


# # trim reverse ME
cutadapt -a CTGTCTCTTATACACATCT -A CTGTCTCTTATACACATCT -j 0 -O 16 -m 20 \
-o unaligned_R1.fastq -p unaligned_R2.fastq \
*_R1_* *_R2_* \
--info-file=poly.cut.log> poly_trim_report.txt && rm poly.cut.log 


ref=/share/home/hanxiaoping/tools/mm10_ucsc/bowtie2/mm10
bowtie2 --end-to-end --very-sensitive --no-mixed --no-discordant \
	--phred33 -I 10 -X 700 -p 8 -x ${ref} \
	-1 unaligned_R1.fastq -2 unaligned_R2.fastq -S bowtie2.sam &> bowtie2.txt && rm unaligned_R*

minQualityScore=2
samtools view -H bowtie2.sam > bowtie2.qs$minQualityScore.sam
samtools view -q $minQualityScore bowtie2.sam >> bowtie2.qs$minQualityScore.sam && rm bowtie2.sam

samtools view -bS -F 0x04 bowtie2.qs$minQualityScore.sam > bowtie2.mapped.bam && rm bowtie2.qs$minQualityScore.sam

samtools sort -n -o sorted.name.bam bowtie2.mapped.bam && rm bowtie2.mapped.bam                       

sample=$(basename `pwd`)
bedtools bamtobed -i sorted.name.bam -bedpe > bowtie2.bed
awk '$1==$4 && $6-$2 < 1000 {print $0}' bowtie2.bed > bowtie2.clean.bed && rm bowtie2.bed
cut -f 1,2,6 bowtie2.clean.bed | sort -k1,1 -k2,2n -k3,3n  > $sample.fragments.bed && rm bowtie2.clean.bed

sample=$(basename `pwd`)
blacklist="/share/home/hanxiaoping/tools/mm10_ucsc/ENCFF547MET.bed"
bedtools subtract -a $sample.fragments.bed -b $blacklist -A > $sample.sub.bed

# #---bed2bw-----
bedtools genomecov -i $sample.sub.bed -g /share/home/hanxiaoping/tools/mm10_ucsc/mm10_chromSize -bg > $sample.bedGraph
bedGraphToBigWig $sample.bedGraph /share/home/hanxiaoping/tools/mm10_ucsc/mm10_chromSize $sample.sub.bw && rm  $sample.bedGraph

mkdir peak # --broad 
sample=$(basename `pwd`)
macs3 callpeak -f BED -t $sample.sub.bed \
	-g mm -n $sample --keep-dup 1  --nolambda \
	--nomodel --shift 0 --extsize 200 \
	--outdir ./peak/ 
cat ./peak/$sample\_peaks.narrowPeak | awk '$5 > 19{print $0}' > ./peak/$sample\_peaks_20.narrowPeak
