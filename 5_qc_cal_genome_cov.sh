#!/bin/bash -e
# Author: Hyung Joo Lee

#SBATCH --mem=1G
#SBATCH --array=1-16
#SBATCH --job-name=c_cov
#SBATCH --mail-type=ALL

# SOFTWARE and PARAMETERS
workdir=/scratch/wgbs

ID=$SLURM_ARRAY_TASK_ID


# INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

dir_in=${workdir}/2_bismark
cx_me=${dir_in}/${sample}_bismark_bt2.CXme.txt


cnt_c=$(( 598683433+600854940 ))	# Watson strand + Crick strand	
cnt_c=$(( $cnt_c - 171823*2 )) 		# Discard chrEBV
cnt_cg=$(( 29303965 * 2 ))


# OUTPUT
dir_out=${workdir}/5_coverage
cov_genome=${dir_out}/${sample}.genome_cov.txt


# COMMANDS
mkdir -p $dir_out
c_cov=$( cat $cx_me | awk -F"\t" -v c=$cnt_c 'BEGIN{s=0} {s+=$2+$3} END{print s/c}' )
cg_cov=$( cat $cx_me | awk -F"\t" -v c=$cnt_cg 'BEGIN{s=0} $1=="CG" {s+=$2+$3} END{print s/c}' )

echo -e "$sample\t$c_cov\t$cg_cov" > $cov_genome

