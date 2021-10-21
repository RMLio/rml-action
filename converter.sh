#!/bin/bash

while read file
do
    # get a filename without extension
    filename=$(echo `basename $file` | sed -e 's/\..*//')
    output_filename="${filename}_output.ttl"
    echo $INPUTS_INPUT_DIRECTORY
    # convert YARRRML rules to RML
    yarrrml-parser -i $file -o $INPUTS_INPUT_DIRECTORY/rml_rules.rml.ttl
    # go to the input directory
    cd $INPUTS_INPUT_DIRECTORY
    # convert RML rules to RDF
    java -jar rmlmapper.jar -m rml_rules.rml.ttl -o $output_filename -s $SERIALIZATION_FORMAT
    # go back to the root directory of a repository
    cd $WORKING_DIRECTORY
    # copy the output file to the output directory
    mv $INPUTS_INPUT_DIRECTORY/$output_filename $INPUTS_OUTPUT_DIRECTORY/$output_filename
    # remove the temporary file with RML rules
    rm $INPUTS_INPUT_DIRECTORY/rml_rules.rml.ttl
done

