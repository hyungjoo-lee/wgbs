#!/usr/bin/env bash
# Author: Hyung Joo

#SBATCH --mem=20G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=FastQC


## SOFTWARES and PARAMETERS
#CPU=$SLURM_CPUS_PER_TASK
CPU=16
workdir=/scratch/wgbs
base=LLFS_WGBS

ml FastQC/0.11.5
ml multiqc/1.7  # seems not working at least on bluemoon


## INPUT
dir_in=${workdir}/0_fastq
fastq=${dir_in}/*_R[12].fq.gz


## OUTPUT
dir_out=${workdir}/0_fastqc


## COMMANDS
mkdir -p $dir_out
fastqc -o $dir_out --noextract --nogroup -t $CPU $fastq &> ${dir_out}/${base}.fastqc.log

multiqc -m fastqc -n ${dir_out}/${base}_R1 -v ${dir_out}/*_R1* &> ${dir_out}/${base}_R1.multiqc_fastqc.log
multiqc -m fastqc -n ${dir_out}/${base}_R2 -v ${dir_out}/*_R2* &> ${dir_out}/${base}_R2.multiqc_fastqc.log

