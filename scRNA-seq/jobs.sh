#BSUB -q normal
#BSUB -J jobs
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=2]"
#BSUB -n 2

for i in {41..48} {57..60};do
    cd $i
    cp ../1_tag_align_split.sh .
    bsub < 1_tag_align_split.sh
    cd ..
done

for i in {41..48} {57..60};do
    cd $i
    cp ../jobs2.sh .
    bsub < jobs2.sh
    cd ..
done

