#BSUB -q normal
#BSUB -J align_0820
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=9]"
#BSUB -n 9

outdir=bwa_out
tmpdir=tmp
shift=shift

if [ ! -d $outdir ]; then
    mkdir $outdir
fi

if [ ! -d $tmpdir ]; then
    mkdir $tmpdir
fi

if [ ! -d $shift ]; then
    mkdir $shift
fi

# sample_name=$(basename `pwd`)
dropseq_root=/share/home/hanxiaoping/tools/Drop-seq_tools-2.5.1
reference=/share/home/hanxiaoping/tools/mm10_ucsc/mm10.fa
bwa_exec=/share/home/hanxiaoping/tools/bwa-0.7.15/bwa

# # merge sample.bam using Tn5 barcode
sample=$(basename `pwd`)
samtools merge -n $outdir/$sample.bam ./*.bam 

# # add barcode to qname
samtools view $outdir/$sample.bam -H > $tmpdir/unaligned_tagged_qname.sam
samtools view $outdir/$sample.bam | awk '{for (i=12; i<=NF; ++i) { if ($i ~ "^BC:Z:"){ td[substr($i,1,2)] = substr($i,6,length($i)-5); printf "%s:%s\n", td["BC"], $0 } } }' \
>> $tmpdir/unaligned_tagged_qname.sam 

# sam --> fastq
java -Xmx100g -jar ${dropseq_root}/3rdParty/picard/picard.jar \
  SamToFastq INPUT=$tmpdir/unaligned_tagged_qname.sam READ1_TRIM=10 READ2_TRIM=20\
  FASTQ=$tmpdir/unaligned_R1_ME.fastq  SECOND_END_FASTQ=$tmpdir/unaligned_R2_ME.fastq && rm $tmpdir/unaligned_tagged_qname.sam

# trim reverse ME
cutadapt -a CTGTCTCTTATACACATCT -A CTGTCTCTTATACACATCT -j 0 -O 16 -m 20 \
-o $tmpdir/unaligned_R1.fastq -p $tmpdir/unaligned_R2.fastq \
$tmpdir/unaligned_R1_ME.fastq $tmpdir/unaligned_R2_ME.fastq \
--info-file=$tmpdir/poly.cut.log> $tmpdir/poly_trim_report.txt && rm $tmpdir/poly.cut.log && rm $tmpdir/unaligned_R1_ME.fastq && rm $tmpdir/unaligned_R2_ME.fastq

# align
fq1=$tmpdir/unaligned_R1.fastq
fq2=$tmpdir/unaligned_R2.fastq
bwa mem -M -t 8 ${reference} ${fq1} ${fq2} > $outdir/Aligned.out.bam

samtools sort $outdir/Aligned.out.bam -o $outdir/$sample.sort.bam && rm $tmpdir/*fastq
samtools index $outdir/$sample.sort.bam && rm $outdir/Aligned.out.bam
alignmentSieve --numberOfProcessors 8 --ATACshift -b  $outdir/$sample.sort.bam -o $shift/$sample.shift.bam
samtools sort -n $shift/$sample.shift.bam -o $shift/$sample.shift.sort.bam && rm $shift/$sample.shift.bam


