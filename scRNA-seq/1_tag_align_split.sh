#BSUB -q normal
#BSUB -J UU
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=9]"
#BSUB -n 9

cd `pwd`
mkdir tmp
tmpdir=tmp
sample_name=$(basename `pwd`)
dropseq_root=/share/home/hanxiaoping/tools/Drop-seq_tools-2.5.1
# fastq --> bam
java -jar ${dropseq_root}/3rdParty/picard/picard.jar FastqToSam F1=R1.fq.gz F2=R2.fq.gz \
  O=H.bam QUALITY_FORMAT=Standard SAMPLE_NAME=sample_name TMP_DIR=$tmpdir 

#-------------  Cell Barcode -------------
#  tag Barcodes
${dropseq_root}/TagBamWithReadSequenceExtended \
BASE_RANGE=1-20 BASE_QUALITY=10 BARCODED_READ=1 TAG_BARCODED_READ=false DISCARD_READ=true TAG_NAME=PC NUM_BASES_BELOW_QUALITY=4 \
INPUT=H.bam OUTPUT=$tmpdir/H1.bam 
${dropseq_root}/TagBamWithReadSequenceExtended \
BASE_RANGE=1-17 BASE_QUALITY=10 BARCODED_READ=1 TAG_BARCODED_READ=true DISCARD_READ=false TAG_NAME=RT NUM_BASES_BELOW_QUALITY=4 \
INPUT=$tmpdir/H1.bam OUTPUT=$tmpdir/H2.bam  && rm $tmpdir/H1.bam 


# #FilterBAM
${dropseq_root}/FilterBam TAG_REJECT=XQ INPUT=$tmpdir/H2.bam OUTPUT=$tmpdir/H3.bam && rm $tmpdir/H2.bam

# # corrected bam for one mismatch
barcodepath=/share/home/hanxiaoping/tools/UU_barcode/
col=$(basename `pwd`)
python3 ${barcodepath}/UU_correct_LDY.py $barcodepath $tmpdir/H3.bam col$col\_ $tmpdir/filtered.bam # && rm $tmpdir/H3.bam
# echo "correct sam files done"
# ########################

java -Xmx100g -jar /share/home/hanxiaoping/tools/Drop-seq_tools-2.5.1/3rdParty/picard/picard.jar\
 SamToFastq INPUT=$tmpdir/filtered.bam FASTQ=$tmpdir/R2.fastq  READ1_TRIM=17

# # # ## PolyATrimmer

cutadapt -a A{10} -j 0 -O 10 --minimum-length=20 -o $tmpdir/R2_trim.fastq \
$tmpdir/R2.fastq && rm $tmpdir/R2.fastq

/share/home/hanxiaoping/tools/seqtk/seqtk seq -Ar tmp/R2_trim.fastq > tmp/R2_polyA_trim_reverse.fastq && rm tmp/R2_trim.fastq

# Alignment STAR
/share/home/hanxiaoping/tools/STAR-2.7.10a/bin/Linux_x86_64_static/STAR \
--genomeDir /share/home/hanxiaoping/tools/mm10_ucsc/STAR/ \
--readFilesIn $tmpdir/R2_polyA_trim_reverse.fastq \
--outFileNamePrefix star \
--limitOutSJcollapsed 5000000 \
--outSAMtype BAM Unsorted 

## MergeBamAlignment
java -Xmx100g -jar ${dropseq_root}/3rdParty/picard/picard.jar MergeBamAlignment \
REFERENCE_SEQUENCE="/share/home/hanxiaoping/tools/mm10_ucsc/mm10.fa" \
UNMAPPED_BAM=$tmpdir/filtered.bam \
ALIGNED_BAM=starAligned.out.bam \
OUTPUT=merged.bam \
INCLUDE_SECONDARY_ALIGNMENTS=false \
PAIRED_RUN=false # && rm $tmpdir/filtered.bam

 ${dropseq_root}/TagReadWithGeneFunction I=merged.bam \
 O=star_gene_exon_tagged.bam \
 ANNOTATIONS_FILE="/share/home/hanxiaoping/tools/mm10_ucsc/mm10_ucsc.gtf" \
&& rm merged.bam

#--------split bam-----------
mkdir tag
mv star_gene_exon_tagged.bam tag
bamtools split -in ./tag/star_gene_exon_tagged.bam -tag TN

sh /share/home/hanxiaoping/tools/UU_barcode/changeTn5Names_1_768_scRNA.sh
mkdir merge

for i in Pituitary Telencephalon SpinalCord Cerebellum BrainStem Diencephalon;do
    mkdir merge/$i 
done

split=split
merge=merge
for i in 193 201 209 217 255 233 241 249 257 265 273 281;do 
  mv $split/$i/* $merge/Pituitary
done
for i in 194 202 210 218 226 234 242 250 258 266 274 282 264 272 280 288;do 
  mv $split/$i/* $merge/SpinalCord
done
for i in 195 203 211 219 227 235 243 251 259 267 275 283;do 
  mv $split/$i/* $merge/Telencephalon
done
for i in 197 205 213 221 229 237 245 253 261 269 277 285;do 
  mv $split/$i/* $merge/Diencephalon
done

for i in 198 206 214 222 230 238 246 254 262 270 278 286;do 
  mv $split/$i/* $merge/Cerebellum
done
for i in 199 207 215 223 231 239 247 255 263 271 279 287;do 
  mv $split/$i/* $merge/BrainStem
done
