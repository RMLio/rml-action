#!/bin/bash

while read file
do
    # get a filename without an extension
    filename=$(echo `basename $file` | sed -e 's/\..*//')
	# filename for the output file containing RDF
    output_filename="${filename}_output.ttl"
    # convert YARRRML rules to RML
    yarrrml-parser -i $file -o $INPUTS_INPUT_DIRECTORY/rml_rules.rml.ttl
    # go to the directory with data files
    cd $INPUTS_INPUT_DIRECTORY
    # convert RML rules to RDF
    java -jar rmlmapper.jar -m rml_rules.rml.ttl -o $output_filename -s $SERIALIZATION_FORMAT
    # go back to the root directory of a repository
    cd $WORKING_DIRECTORY
    # move the output file to the output directory
    mv $INPUTS_INPUT_DIRECTORY/$output_filename $INPUTS_OUTPUT_DIRECTORY/$output_filename
    # remove the temporary file with RML rules
    rm $INPUTS_INPUT_DIRECTORY/rml_rules.rml.ttl
done

