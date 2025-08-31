#BSUB -q normal
#BSUB -J jobs
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=2]"
#BSUB -n 2

for i in Pituitary Telencephalon SpinalCord Cerebellum BrainStem Diencephalon;do
    cd merge/$i
    cp ../../../2_merge.sh .
    bsub < 2_merge.sh
    cd ../..
done


for i in Pituitary Telencephalon SpinalCord Cerebellum BrainStem Diencephalon;do
    cd merge2/$i
    cp ../../4_final_count.sh .
    bsub < 4_final_count.sh
    cd ../..
done