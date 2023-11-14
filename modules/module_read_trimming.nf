#!/usr/bin/env nextflow
nextflow.enable.dsl=2

qual_phred       = params.qual_phred
min_len          = params.min_read_length
adapters         = params.adapters

fastq_dir        = params.fastq_dir
outdir           = params.outdir
adapters         = params.adapters

process run_fastp {

    tag "filter $sample_id"
    publishDir params.outdir, mode: 'copy', pattern: 'trimmed_reads/*fastq.gz', overwrite: false  // publish trimmed fastq files

    input:
	tuple val(sample_id), path(reads)
	path "truseq_adapters.fasta"

    output:
	tuple val(sample_id), path("trimmed_reads/${sample_id}_filt_R*.fastq.gz"), emit: trimmed_reads
	tuple val(sample_id), path("trimmed_reads/${sample_id}.fastp.json"), emit: json

    script:
    """
    mkdir trimmed_reads
    
    fastp -i ${reads[0]} -I ${reads[1]} \\
      -o 'trimmed_reads/${sample_id}_filt_R1.fastq.gz' -O 'trimmed_reads/${sample_id}_filt_R2.fastq.gz' \\
      -q $params.qual_phred \\
      -l $params.min_read_length \\
      --adapter_fasta ${adapters} \\
      -w ${task.cpus} \\
      -j 'trimmed_reads/${sample_id}.fastp.json'
    """
}

process run_fastqc {

    tag "Fastqc on $sample_id"

    cpus 24

    input:
	tuple val(sample_id), path(reads)

    output:
	path "fastqc/fastqc_${sample_id}_logs"

    script:
    """
    mkdir -p 'fastqc/fastqc_${sample_id}_logs'
    fastqc -t ${task.cpus} \\
	-o 'fastqc/fastqc_${sample_id}_logs' \\
	-f fastq -q ${reads[0]} ${reads[1]}
    """
}

process run_multiqc {

    publishDir params.outdir, mode: 'copy'

    input:
        path x
        //path "multiqc.config"

    output:
        file("multiqc/multiqc_report.html")

    script:
    """
    multiqc ${x} --filename "multiqc/multiqc_report.html" 
    """
}
