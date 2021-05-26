#!/bin/bash
# Author: Hyung Joo Lee

#SBATCH --mem=5G
#SBATCH --array=1-16
#SBATCH --job-name=tracks_mC

workdir=/scratch/wgbs
ID=$SLURM_ARRAY_TASK_ID

ml bedtools/2.27.1
ml htslib/1.3.1


# INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

dir_in=${workdir}/2_bismark
cx_report=${dir_in}/${sample}.CX_report.txt.gz 


# OUTPUT
dir_out=${workdir}/6_tracks
methylc=${dir_out}/${sample}.CG.methylC.gz


# COMMNADS for strand-merged CG track
mkdir -p $dir_out
zcat $cx_report | 
    awk -F"\t" 'BEGIN{OFS=FS} $6=="CG" && $4+$5>0 { if ($3=="+") {print $1,$2-1,$2+1,$4,$5} if ($3=="-") {print $1,$2-2,$2,$4,$5} }' |
    sort -k1,1 -k2,2n |
    groupBy -g 1,2,3 -c 4,5 -o sum,sum |
    awk -F"\t" 'BEGIN{OFS=FS} {mcg=sprintf("%.3f", $4/($4+$5)); print $1,$2,$3,"CG",mcg,"+",$4+$5 }' |
    bgzip >$methylc
tabix -p bed $methylc

