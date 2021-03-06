#!/bin/bash
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=12G
#SBATCH --cpus-per-task=6
#SBATCH -o log/slurmjob-%A-%a
#SBATCH --job-name=trim_atac
#SBATCH --partition=short
#SBATCH --array=0-5

# Program configuration
__author__='Babacar Ndao'
__email__='babacar.ndao@etu.uca.fr'
__credits__=["Babacar Ndao"]
__license__='GPL3'
__maintainer__='Babacar Ndao'
__status__='Development'
__version__='0.0.1'

echo 'Quality control and trimming'

# Handling errors
#set -x # debug mode on
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation
#set -o verbose
#set -euo pipefail

IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/8.1.0 java/oracle-1.7.0_79 trimmomatic/0.38


echo "Set up directories ..." >&2
#Set up the temporary directory
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/results/atacseq/trim
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

#Set up data directory
DATA_DIR="/home/users/student05/data/atacseq"

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Set up 2 arrays with forward and reverse fastq.gz sequence files..." >&2
tab_fwd=($(ls "$DATA_DIR"/*_1.fastq.gz | sort -k9,9 ))
echo "tab_fwd = " >&2
printf '%s\n' "${tab_fwd[@]}" >&2

tab_rev=($(ls "$DATA_DIR"/*_2.fastq.gz | sort -k9,9))
echo "tab_rev = " >&2
printf '%s\n' "${tab_rev[@]}" >&2

echo "Run the trimming with trimmomamic tool..." >&2
java -jar /opt/apps/trimmomatic-0.38/trimmomatic-0.38.jar PE -threads ${SLURM_CPUS_ON_NODE} \
    -trimlog "$OUTPUT"/trim.log -summary "$OUTPUT"/stats \
    "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" "${tab_rev[$SLURM_ARRAY_TASK_ID]}" \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz ILLUMINACLIP:"$DATA_DIR"/NexteraPE-PE.fa:2:30:10:2:keepBothReads LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:33


# Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"


echo "Stop job : "`date` >&2

