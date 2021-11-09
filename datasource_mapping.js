// creates a mapping from YARRRML files to the data source files that are a part of them

let expand = require('@rmlio/yarrrml-parser/lib/expander');
let nReadlines = require('n-readlines');
let fs = require('fs');
let { v4: uuid_v4 } = require('uuid');
let YAML = require('yamljs');
let path = require('path');

let meta_dir = 'rml_action_meta';

let yamlToDatasourceMapping = "";

// file with all the filenames of the mapping files for conversion
let input_filename = path.join(meta_dir, 'filenames.txt');
let filenamesLines = new nReadlines(input_filename);
let line;

// for all yarrrml-files
while (line = filenamesLines.next()) {
    let lineString = line.toString('ascii');

    yamlToDatasourceMapping += lineString + " ";

    // extract data sources from this yarrrml-file
    let nativeObject = YAML.load(lineString);
    let yamlString = YAML.stringify(nativeObject);
    let json = expand(YAML.parse(yamlString));

    // make sure all sources are known beforehand
    if (!json.sources) {
        json.sources = {}
    }
    Object.keys(json.mappings).forEach(mappingKey => {
        if (!json.mappings[mappingKey].sources) {
            return
        }
        // add data source for YARRRML line
        let newSources = [];
        json.mappings[mappingKey].sources.forEach(sourceDescription => {
            if (typeof sourceDescription === 'string') {
                newSources.push(sourceDescription);
                return;
            }
            let sourceId = uuid_v4();
            json.sources[sourceId] = Object.assign({}, sourceDescription);
            newSources.push(sourceId)
        })
        json.mappings[mappingKey].sources = newSources;
    });
    
    // for each yarrrml-file: create a string of the form:
    // "(yarrrml-file-name) (data-source-file-name) (other-data-source)[optional]..."
    // where the data source files required for this yarrrml-file are separated by
    // spaces, the number of the data sources may vary
    // such strings for different yarrrml-files are separated by newlines
    let dirName = path.dirname(lineString);
    Object.values(json.sources).forEach(value =>
        yamlToDatasourceMapping += path.join(dirName, value.access) + " " 
    )
    yamlToDatasourceMapping = yamlToDatasourceMapping.trim() + "\n";
}

// save the mapping of yarrrml-files to data source files in a "yamlToDs.txt"-file
let output_filename = path.join(meta_dir, 'yamlToDs.txt');

fs.writeFileSync(output_filename, yamlToDatasourceMapping);