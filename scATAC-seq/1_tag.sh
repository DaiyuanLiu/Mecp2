#BSUB -q normal
#BSUB -J tag
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=9]"
#BSUB -n 9

outdir=bwa_out
tmpdir=tmp
shift=shift

# if [ ! -d $outdir ]; then
#     mkdir $outdir
# fi

if [ ! -d $tmpdir ]; then
    mkdir $tmpdir
fi

# if [ ! -d $shift ]; then
#     mkdir $shift
# fi


sample_name=$(basename `pwd`)
col=$(basename `pwd`)
dropseq_root=/share/home/hanxiaoping/tools/Drop-seq_tools-2.5.1
picard_jar=${dropseq_root}/3rdParty/picard/picard.jar

# fastq --> bam
java -jar ${picard_jar} FastqToSam F1=R1.fq.gz F2=R2.fq.gz  O=H.bam QUALITY_FORMAT=Standard SAMPLE_NAME=sample_name TMP_DIR=$tmpdir && rm R1.fq.gz && rm R2.fq.gz

# -----  Cell Barcode ------
#tag barcodes_BS
${dropseq_root}/TagBamWithReadSequenceExtended SUMMARY=unaligned_tagged_Cellular.bam_summary_R1.txt \
   BASE_RANGE=1-10 BASE_QUALITY=10 BARCODED_READ=1 TAG_BARCODED_READ=True DISCARD_READ=false TAG_NAME=CB NUM_BASES_BELOW_QUALITY=2 \
 	INPUT=H.bam OUTPUT=$tmpdir/unaligned_tagged_Cell_R1.bam COMPRESSION_LEVEL=1
${dropseq_root}/TagBamWithReadSequenceExtended SUMMARY=unaligned_tagged_Cellular.bam_summary_R2.txt \
   BASE_RANGE=1-10 BASE_QUALITY=10 BARCODED_READ=1 TAG_BARCODED_READ=false DISCARD_READ=false TAG_NAME=CB NUM_BASES_BELOW_QUALITY=2 \
 	INPUT=$tmpdir/unaligned_tagged_Cell_R1.bam OUTPUT=$tmpdir/unaligned_tagged_Cell.bam COMPRESSION_LEVEL=1 && rm $tmpdir/unaligned_tagged_Cell_R1.bam

#add RT barcode
${dropseq_root}/TagBamWithReadSequenceExtended SUMMARY=unaligned_tagged_RT_summary_R1.txt \
   BASE_RANGE=1-20 BASE_QUALITY=10 BARCODED_READ=2 TAG_BARCODED_READ=false DISCARD_READ=false TAG_NAME=RT NUM_BASES_BELOW_QUALITY=4 \
   INPUT=$tmpdir/unaligned_tagged_Cell.bam OUTPUT=$tmpdir/unaligned_tagged_RT_R1.bam COMPRESSION_LEVEL=1 && rm $tmpdir/unaligned_tagged_Cell.bam
${dropseq_root}/TagBamWithReadSequenceExtended SUMMARY=unaligned_tagged_RT_summary_R2.txt \
   BASE_RANGE=1-20 BASE_QUALITY=10 BARCODED_READ=2 TAG_BARCODED_READ=True DISCARD_READ=false TAG_NAME=RT NUM_BASES_BELOW_QUALITY=4 \
   INPUT=$tmpdir/unaligned_tagged_RT_R1.bam OUTPUT=$tmpdir/unaligned_tagged_RT.bam COMPRESSION_LEVEL=1 && rm $tmpdir/unaligned_tagged_RT_R1.bam

# FilterBAM
${dropseq_root}/FilterBam TAG_REJECT=XQ INPUT=$tmpdir/unaligned_tagged_RT.bam OUTPUT=$tmpdir/unaligned_tagged_filtered.bam && rm $tmpdir/unaligned_tagged_RT.bam

# corrected bam for one mismatch
barcodepath=/share/home/hanxiaoping/tools/UU_barcode/WXY_ATAC
col=$(basename `pwd`)
python3 ${barcodepath}/UU_correct_A_1to768_B_61to76_Tn5_1to192.py $barcodepath \
   $tmpdir/unaligned_tagged_filtered.bam \
   col$col\_ $tmpdir/filtered.bam

# echo "correct sam files done"

bamtools split -in $tmpdir/filtered.bam -tag TN
sh /share/home/hanxiaoping/tools/UU_barcode/WXY_ATAC/changeTn5Names_1_192.sh

# mv
mkdir merge1
merge1=merge1
split=split


for i in  BrainStem Cerebellum Diencephalon SpinalCord  Telencephalon Pituitary; do
   mkdir $merge1/$i
done
for i in 1 9 17 25 33 41 49 57 65 73 81 89; do
   mv $split/$i/$i.bam $merge1/BrainStem
done
for i in 2 10 18 26 34 42 50 58 66 74 82 90; do
   mv $split/$i/$i.bam $merge1/SpinalCord
done
for i in 3 11 19 27 35 43 51 59 67 75 83 91; do
   mv $split/$i/$i.bam $merge1/Diencephalon
done
for i in 5 13 21 29 37 45 53 61 69 77 85 93; do
   mv $split/$i/$i.bam $merge1/Telencephalon
done
for i in 6 14 22 30 38 46 54 62 70 78 86 94; do
   mv $split/$i/$i.bam $merge1/Cerebellum
done
for i in 8 16 24 32 40 48 56 64 72 80 88 96; do
   mv $split/$i/$i.bam $merge1/Pituitary
done