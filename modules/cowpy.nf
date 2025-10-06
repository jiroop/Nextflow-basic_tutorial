process cowpy {
    
    // Generate ASCII art with cowpy 

    publishDir "results/" 
    container 'community.wave.seqera.io/library/cowpy:1.1.5--1a5414f41afdfd25' // uses the cowpy Docker container from https://seqera.io/containers/
    
    input:
    path input_file
    val character

    output:
    path "cowpy_${character}.txt", emit: output_file
    
    
    script:
    """
    cat $input_file | cowpy -c $character > cowpy_${character}.txt
    """
}
