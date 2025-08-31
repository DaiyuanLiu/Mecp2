#BSUB -q normal
#BSUB -J mv
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=6]"
#BSUB -n 6

mkdir merge2
for i in Pituitary Telencephalon SpinalCord Cerebellum BrainStem Diencephalon Testis Epididymis;do
  mkdir merge2/$i
done

for i in {41..48} {57..60};do
    for j in Pituitary Telencephalon SpinalCord Cerebellum BrainStem Diencephalon Testis Epididymis;do
      mv $i/merge/$j/$j.bam merge2/$j/$i.$j.bam
    done
done
  


