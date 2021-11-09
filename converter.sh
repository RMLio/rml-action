#!/bin/bash

cd $WORKING_DIRECTORY
meta_dir="rml_action_meta"

# a list of files that will be used for conversion
temp_filenames="$meta_dir/temp_filenames.txt"
> $temp_filenames

# if the action was called, then either 'yamlToDs.md5' or 'contents.md5' has changed,
# or one of them is not present
# if 'yamlToDs.md5' has changed, some files have been added/removed or renamed
# if 'contents.md5' has changed, the contents of some files listed in 'yamlToDs' have changed

# check if the checksum for "yamlToDs.txt" has changed
md5sum --status --check $meta_dir/yamlToDs.md5
FIRST_CHECKSUM_RESULT=$?

# if convert-all input parameter was set to true or there is no "yamlToDs.md5" or 
# the checksum "yamlToDs.md5" has changed, convert all files that were given by the
# global pattern
if [[ $CONVERT_ALL == "true" || ! -f $meta_dir/yamlToDs.md5 || \
    ! -f $meta_dir/contents.md5 || $FIRST_CHECKSUM_RESULT != 0 ]]
then
    echo "INFO: either convert-all is true or one of the checksums is not present \
        or the checksum for the list of filenames does not match"
    # add all the filenames to a list of files that will be used for conversion, because either
    # some files have been added/removed/renamed or the checksum of the contents is not present
    cat $meta_dir/yamlToDs.txt | cut -d ' ' -f1 > $temp_filenames
    if [[ ! -f $meta_dir/yamlToDs.md5 || $FIRST_CHECKSUM_RESULT != 0 ]]
    then
        echo "INFO: the checksum for the list of filenames is not present or doesn't match"
        # recalculate the checksum if it does not exist or has changed
        md5sum $meta_dir/yamlToDs.txt > $meta_dir/yamlToDs.md5
    fi
else
    # the checksum "contents.md5" has changed
    # get all files that have changed, save yaml files to a list of files that will be used for
    # conversion, map data source files to the mapping files and then save these mapping files 
    # to the same list in `$temp_filenames`
    echo "INFO: the second checksum (contents) doesn't match"
    md5sum --check $meta_dir/contents.md5 | grep -F "FAILED" | cut -f 1 -d ":" > changed_files.txt
    echo "INFO: changed files are:"
    cat changed_files.txt
    echo
    egrep "*.yml|*.yaml" changed_files.txt >> $temp_filenames
    egrep -v "*.yml|*.yaml" changed_files.txt | grep -F -f - $meta_dir/yamlToDs.txt | \
        cut -d " " -f1 >> $temp_filenames
    rm -f changed_files.txt
fi

# (re-)calculate the checksum for the contents
md5sum $(cat $meta_dir/yamlToDs.txt | tr -s ' ' '\n') > $meta_dir/contents.md5

# determine the correct extension for the output file based on the chosen serialization format
EXTENSION=""
if [[ $SERIALIZATION_FORMAT == "nquads" ]]
then
    EXTENSION="nq"
elif [[ $SERIALIZATION_FORMAT == "turtle" ]]
then
    EXTENSION="ttl"
elif [[ $SERIALIZATION_FORMAT == "trig" ]]
then
    EXTENSION="trig"
elif [[ $SERIALIZATION_FORMAT == "trix" ]]
then
    EXTENSION="xml"
elif [[ $SERIALIZATION_FORMAT == "jsonld" ]]
then
    EXTENSION="jsonld"
elif [[ $SERIALIZATION_FORMAT == "hdt" ]]
then
    EXTENSION="hdt"
else
    echo "ERROR: Unsupported serialization format" >> /dev/stderr
    exit 1
fi

# get rid of the duplicates (e.g. in case multiple data source files
# for the same mapping file were modified)
sort $temp_filenames | uniq > unique_filenames.txt
cp unique_filenames.txt $temp_filenames
rm -f unique_filenames.txt

echo "INFO: Files for conversion are:"
cat $temp_filenames

while read filepath
do    
    # get a basename from the path
    FILE_BASENAME=$(basename $filepath)
    # get a filename without an extension
    FILENAME=$(echo "$FILE_BASENAME" | sed -e 's/\..*//')
	# filename for the output file containing RDF
    OUTPUT_FILENAME="${FILENAME}_output.${EXTENSION}"
    # get a directory name from the path
    # and go to that directory
    FILE_DIRNAME=$(dirname $filepath)
    cd $FILE_DIRNAME
    # convert YARRRML rules to RML rules
    yarrrml-parser -i $FILE_BASENAME -o $WORKING_DIRECTORY/temp_rml_rules.rml.ttl
    # convert RML rules to RDF and save the result to the output folder
    java -jar $WORKING_DIRECTORY/rmlmapper.jar -m $WORKING_DIRECTORY/temp_rml_rules.rml.ttl \
        -o $WORKING_DIRECTORY/$INPUTS_OUTPUT_DIRECTORY/$OUTPUT_FILENAME -s $SERIALIZATION_FORMAT
    cd $WORKING_DIRECTORY
done < $temp_filenames

# remove the temporary file with RML rules
rm -f temp_rml_rules.rml.ttl

# remove the temporary file with all the filenames for the action
rm -f $temp_filenames
