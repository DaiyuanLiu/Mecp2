#BSUB -q normal
#BSUB -J Jobs
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -R "span[ptile=1]"
#BSUB -n 1


# 1. 1_tag.sh 
for i in {73..80} 47 48; do
    cd $i;
    cp ../1_tag.sh .;
    bsub < ./1_tag.sh;
    cd ../;
done

# 2.align.sh
for i in {73..80} 47 48; do
    cd $i;
    cp ../0_jobs2.sh .;
    bsub < 0_jobs2.sh
    cd ../;
done


# 3_mv.sh
for i in {73..80} 47 48; do 
    cd $i;
    cp ../3_mv.sh .;
    bsub < 3_mv.sh;
    cd ../;
done
