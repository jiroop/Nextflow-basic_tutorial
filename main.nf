params.str = "Hello world!" // defines a parameter named str with a default value of "Hello world!". 
                            // Parameters are inputs you can change when running the pipeline, e.g. nextflow run main.nf --str "Different text"

params.character = "turkey"


include { cowpy } from './modules/cowpy.nf'  // includes the cowpy.nf file, making its process available to this workflow

process split {             // defines a process -- a unit of work in Nextflow -- named split
    publishDir "results/lower"   // save a copy/link of outfiles files to this directory. 
                                // Actual files are crated in the work/ directory; publishDir creates symlinks pointing there

    input:                  // this proces takes one input named x; val means its a value, in this case a string. 
    val x                   // Other types of input could be a file (path) or multiple items together (tuple)

    output:                     // path tells nextflow that the output is a file(s) and how to identify them. 
                                // Without this, files will be created in work/ but not passed to the channel. 
                                // By default nextflow knows to look for the files in the work directory.
    
    path 'chunk_*'              // the output files will be named chunk_aa, chunk_ab, chunk_ac, etc. 
                                // We don't know how many output files there will be (it depends on the length of params.str), hence the '*'

    script:                     // actual bash commands to run in this process 

    """                         # triple quotes allow multi-line strings in Groovy (the language Nextflow is written in)
    printf '${x}' | split -b 6 - chunk_      # Splits the input into 6 byte chunks and writes each chunk to a file with "chunk_" as prefix for the filename. 
                                             #  Split outputs files, not text to stdout. By default, split names output files with aa, ab, ac, etc. suffixes
    
    """
}


process convert_to_upper {

    publishDir "results/upper"  
    tag "$y"  // labels the process with the input filename so it shows up in the terminal when running> Useful for logging and tracking

    input:              // path specifies the input is a file
    path y

    output:                 // output is a file or files that match the pattern "upper_*". 
                            // Even though this is the last process in the workflow, we need to specify output so that files get written to the publishDir
    path 'upper_*'

    script:

    """
    cat $y | tr '[a-z]' '[A-Z]' > upper_${y}       # reads the input file, translates from lowercase to uppercase, writes to a new file prefixed with "upper_"
    """

}

process collect_results {

    publishDir "results/collected"

    input:
    path input_files

    output:
    path "collected_output.txt", emit: outfile // outputs the collected output file as 'outfile' to the channel
    val num_chunks, emit: count // outputs the number of chunks as 'count' to the channel

    script:
    num_chunks = input_files.size()  // counts number of input files and assigns them to the variable num_chunks. This is nextflow Groovy code, not bash
    """ 
    cat ${input_files} > collected_output.txt
    """
}




workflow {               // defines the workflow, the main part of the pipeline that connects processes together
    ch_str = channel.of(params.str)  // creates a channel (a data stream) named ch_str and puts the params.str value in the channel. 
                                    // Channels are like conveyer belts that carry data between processes
                                    // to pass a file, use channel.fromPath('path/to/file')
                                    // Note that if a .csv file is passed, the splitCsv operator can be used to split the file into rows/columns, and
                                    // the .map{} operator can be used to specifty how to handle each row/column

    ch_chunks = split(ch_str) // runs the split process with ch_str as input. 
                              // The output is a channel of chunk files grouped as single element in a list, e.g. [[chunk_aa, chunk_ab, chunk_ac]]
             

    
    convert_to_upper(ch_chunks
                    .view()     // see input to the process before flatten
                    .flatten() // runs the convert_to_upper process on each chunk file. 
                                          // flatten() separates the grouped files so each chunk is processed independently in parallel.
                                          // Without flatten: [[chunk_aa, chunk_ab]] (one element containing both files)
                                          // With flatten: [chunk_aa], [chunk_ab] (two separate elements, processed in parallel)
                    .view())    // see input after flatten
    
    convert_to_upper.out.collect().view()  // view the output of convert_to_upper process, which is a channel of upper_chunk files

    collect_results(convert_to_upper.out.collect())   // runs the collect_results process with all the output files from convert_to_upper as input. 
                                            // collect() gathers all items in the channel into a single list, e.g. [upper_chunk_aa, upper_chunk_ab]
                                            // Without collect(): [upper_chunk_aa], [upper_chunk_ab] (two separate elements)
                                            // With collect(): [[upper_chunk_aa, upper_chunk_ab]] (one element containing both files)
                                            // Note that collect() is a terminal operation; it ends the channel and no further operations can be performed on it
                                            // If you want to see the contents of the channel before collecting, use the view() operator as shown below
                                            // collect_results( convert_to_upper.out.view()
                                            // Note that collect does not sort the input files, they will be input in whatever order they finish processing.

    collect_results.out.count.view {var -> "The number of chunks created and processed was: ${var}"}  // view the output of collect_results process, which is a tuple of the collected output file and the number of chunks

    cowpy(collect_results.out.outfile, params.character)  // runs the cowpy process from the included cowpy.nf module, with the collected output file and character parameter as inputs

}
// NOTES    

// Resume:
// If the nextflow pipeline is modified, or inputs change, you can re-run only the processes that have different inputs / code/ outputs using the -resume flag when running the pipeline 
// Nextflow will save a hash of each process code that is specific to inputs/outputs/script, and if these change it will flag the proccess to be re-run

