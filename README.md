# Bacterial Genome Assembler (BGA) - C1

This pipeline is designed by Team C Group 1 to take Illumina paired-end reads as input and produce contiguous genome assemblies for the same along with assembly quality metrics. As for intermediate steps, the pipeline performs trimming and quality filtering to improve the quality of reads used by downstream genome assemblers. It has two assemblers built into it, Unicycler(slow) and Megahit(fast) to cater to the requirements of the user. 

The pipeline takes two required arguments: (i) an input reads directory and (ii) an output directory for storing final assembly files. It also provides an option to give a quast output directory in case the user would like assembly quality metrics. As for other arguments, the user can choose a fast mode (enabling Megahit) and a verbose mode.

## Installation

This pipeline is a bash script that uses a Conda/Mamba environment with the appropriate packages and dependecies. We recommend using Mamba over Conda due to its overall better performance in package installation and dependency resolution. You can find the Mamba installation guide here - [Mamba Docs](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html#mamba-install).

Next, we recommend you to clone this repository into your local system using either the https option or ssh. For reference, here is how to do it using the https option.
```
git clone https://github.gatech.edu/comgenomics2024/C1.git
```

Now, that you have this repo cloned and available as a directory in your system, go ahead and create and activate a mamba environment from the yml files provided in the *setup* directory.

```
## FOR LINUX USERS ##
cd C1/
mamba env create -f setup/BGA_linux.yml -n your_env_name
source activate your_env_name

## FOR MAC USERS ##
cd C1/
mamba env create -f setup/BGA_OS.yml -n your_env_name
source activate your_env_name
```
For Windows users, you can run this pipeline on a WSL2 Linux terminal **without the -f option**. This is because Megahit throws an operation error when running on a WSL2 terminal on a Windows system. This bug will be fixed in future versions.

Although we recommend following the above steps to setup an environment with all required dependencies, you could use alternatives such as Docker containers to ensure appropriate package and dependency installation. In that case, you would be responsible to setup the following packages,
- bbduk
- Unicycler
- Megahit
- QUAST

## Usage

### Preparing your data
Your paired-end reads, i.e. forward and reverse reads for all your genomes should be in a single input folder. Additionally, every read pair should be named as follows - ``{sample_name}_R1.fastq.gz`` and ``{sample_name}_R2.fastq.gz``. 

See ``example_input/`` as a reference below.

```
C1/
  example_input/
     SRR20966265_R1.fastq.gz
     SRR20966265_R2.fastq.gz
```

### Running the script
In order to see the usage of the script and all required and optional arguments, you can print the help message by typing the following inside the ``C1/`` directory
```
./pipeline.sh -h
```
This will display the following
```
Usage: bash pipeline.sh -i <input directory> -o <output directory> -[OPTIONS]
              Bacterial Genome Assembler for Illumina short-reads. The options available are:
                        -i : Directory for Illumina paired-end reads [required]
                        -o : Output directory for Assembly [required]
                        -q : Output directory for Quast Output [optional]
                        -f : For fast assembly (uses megahit)
                        -v : Flag to turn on verbose mode
                        -h : Print usage instructions
```

### Testing the script
We have provided you with an ``example_input`` directory in this repo that you can use to test out the script with various combinations of the options/arguments available. One such usage is shown below where the script is run in the fast-mode (using Megahit), a verbose-mode and a quast directory is provided for outputting assembly quality metrics.
```
./pipeline.sh -i example_input -o test_assembly_out -q test_quast_out -f -v
```

You will find two output directories upon running this command, one called ``test_assembly_out/`` containing the final assembly and one called ``test_quast_out/`` containing the quast report for the assembly.

### Additional Note
There is a directory called ``reference_files/`` in the repo which contains the sequences of the Phix adapter and three commonly used Illumina adapters - nextera.fa, truseq.fa and truseq_rna.fa. These files are required during the contaminant filtering and trimming step. Please **do not** delete that folder.
