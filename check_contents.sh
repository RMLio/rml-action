#!/bin/bash

# if "convert_all" input parameter was set to TRUE,
# convert all files anyway (e.g. if one of the output files or the output folder and 
# all the files were deleted and need to be recovered)
if [[ $CONVERT_ALL == "true" ]]
then
    echo "INFO: convert-all is true => running the action"
    exit 1
fi

cd $WORKING_DIRECTORY
meta_dir="rml_action_meta"

# "rml_action_meta" is the directory that contains the metadata for the action
# "yamlToDs.md5" is the checksum of a list of all mapping files used for conversion
# and the data source files that need to be converted 
# "contents.md5" is the checksum of contents of all mapping files and all the data source files
# if both checksums exist and are correct, finish the action without conversion

if [[ ! -f $meta_dir/yamlToDs.md5 || ! -f $meta_dir/contents.md5 ]]
then
    # one of the checksums is not present => run the action
    echo "INFO: one of the checksums is not present => running the action"
    exit 1
fi

# check if the checksum for the list of filenames hasn't changed
# if it has, some files have been added/removed or renamed,
# so the action should be run further (conversion)
md5sum --status --check $meta_dir/yamlToDs.md5
FIRST_CHECKSUM_RESULT=$?
# check if the checksum for the contents of mapping files and data source files
# is still the same; if it's not, run the action further (conversion)
md5sum --status --check $meta_dir/contents.md5
SECOND_CHECKSUM_RESULT=$?

if [[ $FIRST_CHECKSUM_RESULT == 0 && $SECOND_CHECKSUM_RESULT == 0 ]]
then
    # there are no changes, don't run the action
    echo "INFO: No changes, stopping the action"
    exit 0
fi

# the action needs to be run in this case
echo "INFO: Changes detected: running the action"
exit 1
