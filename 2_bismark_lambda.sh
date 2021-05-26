#!/usr/bin/env bash

#SBATCH --cpus-per-task=12
#SBATCH --mem=10G
#SBATCH --array=1-16%1
#SBATCH --job-name=bismark_lambda
#SBATCH --mail-type=ALL

### SOFTWARES and PARAMETERS
workdir=/scratch/wgbs

ID=$SLURM_ARRAY_TASK_ID
CPU=$SLURM_CPUS_PER_TASK
CPU=12

ml bismark/0.18.1
#ml perl-gd-graph/1.4308-python-2.7.15

genome_dir=/scratch/genomes/lambda
min_insert=0
max_insert=2000

cpus=$(( $CPU / 2 ))

### INPUT
list=${workdir}/samples.txt
base=$( cat $list | sed "${ID}q;d" )

indir=${workdir}/1_trim
read1_fq=${indir}/${base}_R1.fq.gz
read2_fq=${indir}/${base}_R2.fq.gz


### OUTPUT
outdir=${workdir}/2_bismark_lambda
tmp_dir=/tmp

# 1. bismark PE files
log_bismark_pe=${outdir}/${base}.bismark.log
bam_pe=${outdir}/${base}_bismark_bt2_pe.bam

# 2. deduplicate files
log_dedup_pe=${outdir}/${base}.deduplicate_bismark.log
bam_dedup_pe=${outdir}/${base}_bismark_bt2_pe.deduplicated.bam

# 3. extract files
log_methx_pe=${outdir}/${base}_pe.bismark_methylation_extractor.log

cg_pe=${outdir}/CpG_context_${base}_bismark_bt2_pe.deduplicated.txt.gz
ch_pe=${outdir}/Non_CpG_context_${base}_bismark_bt2_pe.deduplicated.txt.gz
merged=${outdir}/${base}_bismark_bt2.extracted.txt.gz

# 4. bismark2bedgraph files
log_bismark2bg=${outdir}/${base}.bismark2bedGraph.log
bedGraph=${base}.bedGraph.gz
cov=${base}.bismark.cov.gz

# 5. coverage2cytosine files
log_cov2c=${outdir}/${base}.coverage2cytosine.log
cx_report=${base}.CX_report.txt.gz
cx_me=${outdir}/${base}_bismark_bt2.CXme.txt


### COMMANDS
echo "-- Started on $(date) with SLURM JOB ID: $SLURM_JOB_ID"
echo ""
echo ""

# Mapping with bismark/bowtie2
# Note --bowtie2 and -p $nthreads are both SLOWER than single threaded bowtie1
echo "-- 1. Mapping to reference with bismark/bowtie2... started on $(date)"
mkdir -p $outdir
bismark -q -I $min_insert -X $max_insert --parallel 2 -p $cpus \
        --bowtie2 -N 1 -L 28 --score_min L,0,-0.6 \
        -o $outdir --temp_dir $tmp_dir --gzip --nucleotide_coverage \
        $genome_dir -1 $read1_fq -2 $read2_fq &>$log_bismark_pe
rename "s/_R1_bismark_bt2/_bismark_bt2/g" ${outdir}/${base}_R1_bismark_bt2_*
echo ""

# Dedpulicate reads
echo "-- 2. Deduplicating aligned reads... started on $(date)"
deduplicate_bismark -p --bam $bam_pe  &>$log_dedup_pe
echo ""

# Run methylation extractor for the sample
echo "-- 3. Analyse methylation in $bam_dedup_pe using $CPU threads... started on $(date)"
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report \
			      -o $outdir --gzip --parallel $CPU \
                              $bam_dedup_pe &>$log_methx_pe
echo ""

# Generate HTML Processing Report
echo "-- 4. Generate bismark HTML processing report file... started on $(date)"
bismark2report -o ${base}_bismark_bt2_PE_report.html --dir $outdir \
	       --alignment_report ${outdir}/${base}_bismark_bt2_PE_report.txt \
	       --dedup_report ${outdir}/${base}_bismark_bt2_pe.deduplication_report.txt \
	       --splitting_report ${outdir}/${base}_bismark_bt2_pe.deduplicated_splitting_report.txt \
	       --mbias_report ${outdir}/${base}_bismark_bt2_pe.deduplicated.M-bias.txt \
	       --nucleotide_report ${outdir}/${base}_bismark_bt2_pe.nucleotide_stats.txt &>${outdir}/${base}_pe.bismark2report.log
echo ""

# Generate bedGraph file
echo "-- 5. Generate bedGraph file... started on $(date)"
mv $ch_pe $merged
cat $cg_pe >>$merged
bismark2bedGraph --dir $outdir --cutoff 1 --CX_context --buffer_size=75G --scaffolds \
                 -o $bedGraph $merged &>$log_bismark2bg
rm ${outdir}/$bedGraph # $merged
echo ""

# Calculate average methylation levels per each CN context
echo "-- 6. Generate cytosine methylation file... started on $(date)"
coverage2cytosine -o $cx_report --dir $outdir --genome_folder $genome_dir --CX_context --gzip \
                  $cov &>$log_cov2c
rm ${outdir}/$cov
zcat ${outdir}/$cx_report |
    awk 'BEGIN{ca=0;cc=0;cg=0;ct=0;mca=0;mcc=0;mcg=0;mct=0}
         $7~/^CA/ {ca+=$5; mca+=$4}
         $7~/^CC/ {cc+=$5; mcc+=$4}
         $7~/^CG/ {cg+=$5; mcg+=$4}
         $7~/^CT/ {ct+=$5; mct+=$4}
         END{printf("CA\t%d\t%d\t%.3f\n", ca, mca, mca/(ca+mca));
             printf("CC\t%d\t%d\t%.3f\n", cc, mcc, mcc/(cc+mcc));
             printf("CG\t%d\t%d\t%.3f\n", cg, mcg, mcg/(cg+mcg));
             printf("CT\t%d\t%d\t%.3f\n", ct, mct, mct/(ct+mct));}' >$cx_me
echo ""

# Print the files generated
echo "-- The results..."
ls -l ${outdir}/*${base}*
echo ""
echo "-- Finished on $(date)"
