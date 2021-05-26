#!/bin/bash

#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --array=1-16
#SBATCH --job-name=preseq
#SBATCH --mail-type=ALL

### SOFTWARES and PARAMETERS
workdir=/scratch/wgbs

ml samtools/1.9
ml preseq/3.1.2

ID=$SLURM_ARRAY_TASK_ID
CPU=$SLURM_CPUS_PER_TASK


### INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

indir=${workdir}/2_bismark
bam=${indir}/${sample}_bismark_bt2_pe.bam


### OUTPUT
outdir=${workdir}/3_preseq
bam_sorted=${outdir}/${sample}.sorted.bam
output=${outdir}/${sample}.preseq_lc_extrap.txt
log=${outdir}/${sample}.preseq_lc_extrap.log

### COMMANDS
CPU=$(( $CPU - 1 ))

mkdir -p $outdir
samtools sort -m 2G -o $bam_sorted -T /tmp/$sample -@ $CPU $bam
preseq lc_extrap -o $output -B -P -D $bam_sorted 2>$log
rm $bam_sorted


