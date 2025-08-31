#BSUB -q normal
#BSUB -J mv2
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=1]"
#BSUB -n 1

# mv Tn5 bam files
col=$(basename `pwd`)
mkdir ../merge
for i in  BrainStem Cerebellum Diencephalon SpinalCord Telencephalon Pituitary; do
    mkdir ../merge/upload
    mkdir ../merge/analysis
    mkdir ../merge/upload/$i
    mkdir ../merge/analysis/$i
    mv merge1/$i/bwa_out/$i.sort.bam ../merge/upload/$i/$col.$i.sort.bam
    mv merge1/$i/shift/$i.shift.sort.bam ../merge/analysis/$i/$col.$i.shift.sort.bam
done