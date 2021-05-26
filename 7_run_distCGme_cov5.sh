#!/bin/bash
# Author: Hyung Joo Lee

#SBATCH --mem=30G
#SBATCH --array=15-16 #1-17 	#1-12,17 done
##SBATCH --workdir=/scratch/twlab/hlee/mgi
#SBATCH --job-name=dstCGme
##SBATCH --mail-type=ALL

# SOFTWARES
ID=$SLURM_ARRAY_TASK_ID
workdir=/scratch/twlab/hlee/mgi

#ml R/3.3.3
ml r-ggplot2/2.2.1-python-2.7.15-java-11-r-3.5.1
rscript=/home/hyungjoo.lee/jobs/mgi/distCGme_cov5.R


# INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )


dir_in=${workdir}/dmr/1_dss_input
dss=${dir_in}/${sample}.dss.txt.gz


# OUTPUT
dir_out=${workdir}/7_distCGme
out=${dir_out}/${sample}_CGme_density_cov5.txt
log=${dir_out}/distCGme_cov5.R.${sample}.log

# COMMANDS
$rscript $dss $out &>$log

