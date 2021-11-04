#!/bin/bash

while read filepath
do
    if [[ "$filepath" == *".github"* ]]; then
        continue 
    fi
    # get a basename from the path
    FILE_BASENAME=$(basename $filepath)
    # get a filename without an extension
    FILENAME=$(echo "$FILE_BASENAME" | sed -e 's/\..*//')
	# filename for the output file containing RDF
    OUTPUT_FILENAME="${FILENAME}_output.ttl"
    # get a directory name from the path
    # and go to that directory
    FILE_DIRNAME=$(dirname $filepath)
    cd $FILE_DIRNAME
    # convert YARRRML rules to RML
    yarrrml-parser -i $FILE_BASENAME -o $WORKING_DIRECTORY/temp_rml_rules.rml.ttl
    # convert RML rules to RDF and save it to the output folder
    java -jar $WORKING_DIRECTORY/rmlmapper.jar -m $WORKING_DIRECTORY/temp_rml_rules.rml.ttl \
        -o $WORKING_DIRECTORY/$INPUTS_OUTPUT_DIRECTORY/$OUTPUT_FILENAME -s $SERIALIZATION_FORMAT
    cd $WORKING_DIRECTORY
done

# remove the temporary file with RML rules
rm -f $WORKING_DIRECTORY/temp_rml_rules.rml.ttl

