#!/bin/bash
# Author: Hyung Joo Lee

#SBATCH --mem=30G
#SBATCH --array=1-16
#SBATCH --job-name=dstCGme
##SBATCH --mail-type=ALL

# SOFTWARES
workdir=/scratch/twlab/hlee/mgi
ID=$SLURM_ARRAY_TASK_ID

#ml R/3.3.3
ml r-ggplot2/2.2.1-python-2.7.15-java-11-r-3.5.1

dir_qc=/scratch/genomes/hg38/wgbs_qc
rscript=${dir_qc}/distCGme_cov10.R


# INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )


dir_in=${workdir}/dmr/1_dss_input
dss=${dir_in}/${sample}.dss.txt.gz


# OUTPUT
dir_out=${workdir}/7_distCGme
out=${dir_out}/${sample}_CGme_density_cov10.txt
log=${dir_out}/distCGme_cov10.R.${sample}.log

# COMMANDS
mkdir -p $dir_out
$rscript $dss $out &>$log

