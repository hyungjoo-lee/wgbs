#!/bin/bash
# Author: Hyung Joo Lee

#SBATCH --cpus-per-task=5
#SBATCH --mem=10G
#SBATCH --array=14	#1-12,17 done
#SBATCH --job-name=tracks_cov
##SBATCH --workdir=/scratch/twlab/hlee/mgi

ID=$SLURM_ARRAY_TASK_ID
CPUS=$(( $SLURM_CPUS_PER_TASK - 1 ))

ml samtools/1.9
ml bedtools/2.27.1
workdir=/scratch/twlab/hlee/mgi


# INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

dir_in=${workdir}/2_bismark
bam_in=${dir_in}/${sample}_bismark_bt2_pe.deduplicated.bam
bam_sorted=${dir_in}/${sample}_bismark_bt2_pe.deduplicated.sorted.bam


# OUTPUT
dir_out=${workdir}/6_tracks
cov_out=${dir_out}/${sample}.cov.bg.gz


# COMMNADS for coverage bedgraph file
samtools sort -m 2G -o $bam_sorted -T /tmp/$sample -@ $CPUS $bam_in

genomeCoverageBed -bg -ibam $bam_sorted |
    bgzip >$cov_out
tabix -p bed $cov_out

