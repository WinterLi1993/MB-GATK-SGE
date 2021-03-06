#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=24:00:00
#$ -l h_vmem=20G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs MuTect 1 on a pair of .bam files

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Get right version of Java (FMS cluster specific)
module unload apps/java/jre-1.8.0_92
module add apps/java/jre-1.7.0_75

# Get info for pair using task id from array job
LINE=`awk "NR==$SGE_TASK_ID" $MUTECT_LIST`
set $LINE
RUN_ID=$1
NORMAL=$2
TUMOUR=$3

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../MuTect1_split_bam"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$NORMAL.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$NORMAL.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$NORMAL.bai $TMPDIR

echo "Copying tumour input $INPUT_DIR/$TUMOUR.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$TUMOUR.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$TUMOUR.bai $TMPDIR

echo "Running MuTect 1 on normal:$NORMAL vs tumor:$TUMOUR"
/usr/bin/time --verbose $JAVA7 -Xmx16g -jar $MUTECT1 \
-dcov $DCOV \
--analysis_type MuTect \
$INTERVALS \
--interval_padding $PADDING \
--reference_sequence $REF \
--cosmic $COSMIC \
--dbsnp $DBSNP \
--input_file:normal $TMPDIR/$NORMAL.bam \
--input_file:tumor $TMPDIR/$TUMOUR.bam \
--out $TMPDIR/$OUTPUT.out \
--coverage_file $TMPDIR/$OUTPUT.wig \
-vcf $TMPDIR/$OUTPUT.vcf \
--log_to_file $TMPDIR/$OUTPUT.log

echo "Copying $TMPDIR/$OUTPUT.MuTect1.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.* $PWD

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
