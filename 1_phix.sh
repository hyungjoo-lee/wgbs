#!/bin/bash

#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --array=1-16%1
#SBATCH --job-name=phix
#SBATCH --mail-type=ALL

### SOFTWARES and PARAMETERS
workdir=/scratch/wgbs

ml samtools/1.9
ml bwa/0.7.15

ID=$SLURM_ARRAY_TASK_ID
#CPU=$SLURM_CPUS_PER_TASK
CPU=4

genome_path=/scratch/genomes/phiX174/bwa_index/phiX174.fa


### INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

indir=${workdir}/1_trim
fq1=${indir}/${sample}_R1.fq.gz
fq2=${indir}/${sample}_R2.fq.gz


### OUTPUT
outdir=${workdir}/1_phix

bam=${outdir}/${sample}.bwa_phiX.bam
output=${outdir}/${sample}.bwa_phiX.txt
log=${outdir}/${sample}.bwa_phiX.log


### COMMANDS
mkdir -p $outdir

# Total number of reads
total=$( zcat $fq1 | grep -c "^@" )

# Mapping to the phiX genome to check the contamination, reporting only mapped reads
bwa mem -t $CPU $genome_path $fq1 $fq2 2> $log | samtools view -b -o $bam -F 4 -@ $(( $CPU - 1 )) -

# Count reads mapped to the phiX genome
phi=$( samtools view -c -@ $(( $CPU - 1 )) $bam )

# Calculate the rate of phiX mapped reads
phi_rate=$( awk -v c=$phi -v t=$total 'BEGIN{ rate=sprintf("%.7g", c/(t*2)); print rate}' )

# Print out the results
echo -e "$sample\t$total\t$phi\t$phi_rate" > $output


