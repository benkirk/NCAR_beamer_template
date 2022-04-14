#!/bin/bash -l
#PBS -N job_array
#PBS -A MYACCOUNT
### Each array subjob will be assigned a single CPU with 1 GB of memory
#PBS -l select=1:ncpus=1:mem=1GB
#PBS -l walltime=00:10:00
#PBS -q casper
### Request 10 subjobs with array indices spanning 2010-2020 (input year)
#PBS -J 2010-2020
#PBS -j oe

export TMPDIR=/glade/scratch/${USER}/temp && mkdir -p ${TMPDIR}

### Run program
env | sort | grep PBS

echo "data.year-$PBS_ARRAY_INDEX"
