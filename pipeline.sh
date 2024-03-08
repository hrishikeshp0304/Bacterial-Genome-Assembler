#!/bin/bash

parse_args() {

    # Function to parse arguments
    # Specifying usage message
    usage="Usage: bash pipeline.sh -i <input directory> -o <output directory> -[OPTIONS]
              Bacterial Genome Assembler for Illumina short-reads. The options available are:
                        -i : Directory for Illumina paired-end reads [required]
                        -o : Output directory for Assembly [required]
                        -q : Output directory for Quast Output [optional]
                        -f : For fast assembly (uses megahit)
                        -v : Flag to turn on verbose mode
                        -h : Print usage instructions"

  #Specifying default Arguments
  f=0
  assembler="unicycler"
  trimming=1
  quast=0
  v=0

  #Getopts block, will take in the arguments as inputs and assign them to variables
  while getopts "i:o:q:fvh" option; do
          case $option in
                  i) input_dir=$OPTARG;;
                  o) output_dir=$OPTARG;;
                  q) quast_dir=$OPTARG;;
                  f) f=1;;
                  v) v=1;;
                  h) echo "$usage"
                        exit 0;;
                 \?) echo "Invalid option."
                    "$usage"
                             exit 1;;
          esac
  done

  #Check for presence of required arguments
  if [ ! "$input_dir" ] || [ ! "$output_dir" ]
  then
    echo "ERROR: Required arguments not provided!"
    echo "$usage"
    exit 1
  fi

  if [ ! -d "$input_dir" ]
  then 
    echo "ERROR: Not a valid input reads directory"
    echo "$usage"
    exit 1
  fi

  #If quast directory was given, set quast to 1.
  if [ -n "$quast_dir" ]
  then 
    echo "Quast directory has been provided: $quast_dir"
    quast=1
  fi

  #If 'fast' option is selected, assembling using megahit
  if [ $f == 1 ]
  then
    assembler="megahit"
  fi

}


#bbduk
run_bbduk() {
    local sample_name=$1
    local forward_reads="${sample_name}_R1.fastq.gz"
    local reverse_reads="${sample_name}_R2.fastq.gz"
    mkdir -p temp/bbduk/phix
    mkdir -p temp/bbduk/qual_filter

#    if  [ $v == 1 ]
#    then
#	   echo "Phix Trimming ${sample_name} with bbduk"
#    fi


    # Run bbduk phix removal 
    bbduk.sh -Xmx1g in1="${input_dir}/${forward_reads}" in2="${input_dir}/${reverse_reads}" out1="temp/bbduk/phix/${forward_reads}" out2="temp/bbduk/phix/${reverse_reads}" ref=reference_files/phix_adapters.fa.gz k=31 hdist=1 

    if  [ $v == 1 ]
    then
	   echo "Quality Filtering ${sample_name} with bbduk"
    fi

    # Run bbduk adapter and qual filter
    bbduk.sh -Xmx1g in1="temp/bbduk/phix/${forward_reads}" in2="temp/bbduk/phix/${reverse_reads}" out1="temp/bbduk/qual_filter/${forward_reads}" out2="temp/bbduk/qual_filter/${reverse_reads}" ref=reference_files/nextera.fa.gz,reference_files/truseq.fa.gz,reference_files/truseq_rna.fa.gz ktrim=rl k=23 mink=11 hdist=1 tpe tbo qtrim=r trimq=20

    if  [ $v == 1 ]
    then
	   echo "Trimming for ${sample_name} finished!"
    fi

}


#Unicyler
run_unicycler() {
    local sample_name=$1
    local forward_reads="temp/bbduk/qual_filter/${sample_name}_R1.fastq.gz"
    local reverse_reads="temp/bbduk/qual_filter/${sample_name}_R2.fastq.gz"
    mkdir -p "temp/unicycler/${sample_name}"
    mkdir -p temp/final_assemblies

    if  [ "$v" == 1 ]
    then
	   echo "Assembling ${sample_name} with Unicycler"
    fi

    # Run unicycler
    unicycler -1 "$forward_reads" -2 "$reverse_reads" -o "temp/unicycler/${sample_name}" --keep 0

    # Check if unicycler was successful
    if  [ "$v" == 1 ]
    then
	   echo "Assembled ${sample_name} with Unicycler successfully!"
    fi     

    mv "temp/unicycler/${sample_name}/assembly.fasta" "temp/final_assemblies/${sample_name}.fasta"  
    rm -r "temp/unicycler/${sample_name}"        
}



# megahit
run_megahit(){
    local sample_name=$1
    local forward_reads="temp/bbduk/qual_filter/${sample_name}_R1.fastq.gz"
    local reverse_reads="temp/bbduk/qual_filter/${sample_name}_R2.fastq.gz"
    mkdir -p "temp/megahit"
    mkdir -p temp/final_assemblies

    # Iterate over each pair of FASTQ files in the input directory
    if  [ "$v" == 1 ]
    then
	   echo "Assembling ${sample_name} with Megahit"
    fi

    # Run MegaHit with paired-end reads
    megahit -1 "${forward_reads}" -2 "${reverse_reads}" -o "temp/megahit/${sample_name}"

    if  [ "$v" == 1 ]
    then
	   echo "Assembly for ${sample_name} with Megahit completed!"
    fi

    mv "temp/megahit/${sample_name}/final.contigs.fa" "temp/final_assemblies/${sample_name}.fasta"
    rm -r "temp/megahit/${sample_name}"
}


#Quast
run_quast() {
    local sample_name=$1
    local assembly="temp/final_assemblies/${sample_name}.fasta"
    mkdir -p "temp/quast/${sample_name}"

    if  [ "$v" == 1 ]
    then
	   echo "Quast for sample ${sample_name}..."
    fi

    # Run Quast
    quast.py "$assembly" -o "temp/quast/${sample_name}"
    
    if  [ "$v" == 1 ]
    then
	   echo "Quast for sample ${sample_name} completed!"
    fi

    mv "temp/quast/${sample_name}/report.html" "temp/quast/${sample_name}.html"
    rm -r "temp/quast/${sample_name}"
}

main(){
    parse_args "$@"
    
    if  [ $v == 1 ]
    then
	   echo "Assembly pipeline starts"
    fi

    
    if [ "$trimming" == 1 ]
    then
        for forward_read in "${input_dir}"/*_R1.fastq.gz; do
            # Extract the sample name based on the forward read file name
            sample_name_t=$(basename "$forward_read" "_R1.fastq.gz")

            # Call the bbduk function for each sample
            run_bbduk "$sample_name_t" 
        done
    fi
    
    if [ "$assembler" == "unicycler" ]
    then
        for trim_forward_read in "temp/bbduk/qual_filter"/*_R1.fastq.gz; do
            # Extract the sample name based on the forward read file name
            sample_name_a=$(basename "$trim_forward_read" "_R1.fastq.gz")

            # Call the bbduk function for each sample
            run_unicycler "$sample_name_a" 
        done
    fi

    if [ "$assembler" == "megahit" ]
    then
        for trim_forward_read in "temp/bbduk/qual_filter"/*_R1.fastq.gz; do
            # Extract the sample name based on the forward read file name
            sample_name_a=$(basename "$trim_forward_read" "_R1.fastq.gz")

            # Call the bbduk function for each sample
            run_megahit "$sample_name_a" 
        done
    fi

    if [ "$quast" == 1 ]
    then
        for assembly in "temp/final_assemblies"/*.fasta; do
            # Extract the sample name based on the forward read file name
            sample_name_q=$(basename "$assembly" ".fasta")

            # Call the bbduk function for each sample
            run_quast "$sample_name_q" 
        done

        mkdir -p "${quast_dir}"
        cp temp/quast/*.html "${quast_dir}/"
    fi
    
    mkdir -p "${output_dir}"
    cp temp/final_assemblies/*.fasta "${output_dir}/"

    if [ "$v" == 1 ]
    then
          echo "Assembly pipeline complete!"
    fi
    
    rm -r temp/

}



# Calling the main function
main "$@"

