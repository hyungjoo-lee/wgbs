#!/usr/bin/env bash

#SBATCH --array=1-16%4
#SBATCH --cpus-per-task=16
#SBATCH --job-name=trim_galore
#SBATCH --mail-type=ALL

### SOFTWARES and PARAMETERS
workdir=/scratch/wgbs

trim_base1=10
trim_base2=15

ml trim_galore/0.6.6	# uses cutadapt 1.9
ml FastQC/0.11.5

ID=$SLURM_ARRAY_TASK_ID
#CPUS=$SLURM_CPUS_PER_TASK
CPUS=16

cores=$(( $CPUS / 2 ))


### INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

indir=${workdir}/0_fastq
read1_fq=${indir}/${sample}_R1.fq.gz
read2_fq=${indir}/${sample}_R2.fq.gz


### OUTPUT
outdir=${workdir}/1_trim

log_trimgalore=${outdir}/${sample}.trim_galore.log
trim1_fq=${outdir}/${sample}_R1.fq.gz
trim2_fq=${outdir}/${sample}_R2.fq.gz


### COMMANDS
mkdir -p $outdir

# Trimming reads
#### Note first 10 bp of R1 and 15 bp of R2 in Accel libraries should be trimmed.
trim_galore -q 20 --phred33 --fastqc --fastqc_args "-o $outdir --noextract --nogroup" \
	    --illumina --stringency 1 -e 0.1 --length 20 \
	    --clip_R1 $trim_base1 --clip_R2 $trim_base2 \
	    -o $outdir \
	    -j $cores \
	    --paired --retain_unpaired -r1 21 -r2 21 $read1_fq $read2_fq &>$log_trimgalore 

mv ${outdir}/${sample}_R1_val_1.fq.gz $trim1_fq
mv ${outdir}/${sample}_R2_val_2.fq.gz $trim2_fq

rename "s/_val_[12]/_trimmed/g" ${outdir}/${sample}_R[12]_val_[12]_fastqc.*
rename "s/.fq.gz//g" ${outdir}/${sample}_R[12].fq.gz_trimming_report.txt

