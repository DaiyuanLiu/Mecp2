#BSUB -q normal
#BSUB -J Jobs
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=1]"
#BSUB -n 1


for i in  BrainStem Cerebellum Diencephalon SpinalCord  Telencephalon Pituitary; do
    cd merge1/$i;
    cp ../../../2_align.sh .;
    bsub < ./2_align.sh;
    cd ../..;
done

for i in  BrainStem Cerebellum Diencephalon SpinalCord  Telencephalon Pituitary; do
    cd merge/analysis/$i;
    cp ../../../4_final.sh .;
    bsub < ./4_final.sh;
    cd ../../..;
done

