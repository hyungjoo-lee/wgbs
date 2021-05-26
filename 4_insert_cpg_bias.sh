#!/bin/bash

##SBATCH --cpus-per-task=6
#SBATCH --mem=20G
#SBATCH --array=1-16
#SBATCH --job-name=insert_cpg_bias
#SBATCH --mail-type=ALL

### SOFTWARES and PARAMETERS
workdir=/scratch/wgbs

ml samtools/1.9
ml bedtools/2.27.1
ml R/3.6.1
#ml r-ggplot2/2.2.1-python-2.7.15-java-11-r-3.5.1 # for QC Rscript

ID=$SLURM_ARRAY_TASK_ID
CPU=$SLURM_CPUS_PER_TASK
CPU=6

dir_qc=/scratch/genomes/hg38/wgbs_qc
bg_chr1_1kb=${dir_qc}/CpGs.hg38_chr1_1kb_win.bg.gz
rscript_insert=${dir_qc}/density_insert_length.R
rscript_cpgbias=${dir_qc}/CpGbias_1kb.R


### INPUT
list=${workdir}/samples.txt
sample=$( cat $list | sed "${ID}q;d" )

indir=${workdir}/2_bismark
bam_dedup=${indir}/${sample}_bismark_bt2_pe.deduplicated.bam


### OUTPUT
outdir=${workdir}/4_insert_cpg_bias

bam_tmp=${outdir}/${sample}.tmp.bam
insert_tmp=${outdir}/${sample}.tmp.insert.txt.gz
cov_chr1=${outdir}/${sample}.tmp.CpG.cov_chr1_1kb_win.txt.gz

out_insert=${outdir}/${sample}.insert_length.txt
rlog_insert=${outdir}/${sample}.density_insert_length.R.log
rlog_cpgbias=${outdir}/${sample}.CpGbias_1kb.R.log


### COMMANDS
CPU=$(( $CPU - 1 ))

mkdir -p $outdir
cd $outdir

# select the first 100K alignments
samtools view -h -@ $CPU $bam_dedup |
    head -100000197 | samtools view -b -o $bam_tmp -@ $CPU

# make temporary insert length txt file
bamToBed -bedpe -i $bam_tmp | awk -vOFS="\t" '{print $1,$2,$6,$6-$2}' | gzip -nc > $insert_tmp

# select only chr1 
bamToBed -bedpe -i $bam_tmp | awk '$1=="chr1"' |
    coverageBed -counts -a $bg_chr1_1kb -b stdin | awk '$4>0 && $5>0' | gzip -nc > $cov_chr1

# run rscripts
Rscript $rscript_insert $insert_tmp $out_insert &> $rlog_insert
Rscript $rscript_cpgbias $cov_chr1 $sample &> $rlog_cpgbias

# remove temporary files
#rm $bam_tmp$insert_tmp  $cov_chr1

