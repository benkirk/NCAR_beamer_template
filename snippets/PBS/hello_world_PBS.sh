#!/bin/bash -l
#PBS -N job_array
#PBS -A MYACCOUNT
#PBS -l select=1:ncpus=1:mem=1GB
#PBS -l walltime=00:10:00
#PBS -q casper
#PBS -j oe

export TMPDIR=/glade/scratch/${USER}/temp && mkdir -p ${TMPDIR}

### Interrogate Environment
env | sort | grep PBS

module list

### Run program
echo "Hello, World!"
