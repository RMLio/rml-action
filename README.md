# rml-action

`rml-action` is a GitHub Action that converts a structured data source file (e.g. JSON, XML, CSV...) to [Resource Description Framework (RDF)](https://www.w3.org/RDF/) rules.
Multiple serialization formats are supported: `nquads` (default), `turtle`, `trig`, `trix`, `jsonld`, `hdt`.

## Usage

Create a `.github/workflows/data.yaml` file in the repository where you want to fetch and convert data. An example:

```yaml
name: Convert to RDF Workflow

on:
  # Triggers the workflow on push or pull request events but only for the master branch
  push:
    branches: [master]
  pull_request:
    branches: [master]

  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      GLOBAL_PATTERN: "*.yml"
      SERIALIZATION_FORMAT: turtle
      OUTPUT_DIRECTORY: output
      CONVERT_ALL: true
    steps:
      # Checks-out your repository
      - uses: actions/checkout@v2

      - name: Converts YARRRML rules to RDF
        uses: RMLio/rml-action@v1.0.0
        with:
          # the global pattern for all YARRRML mappings
          global-pattern: ${{  env.GLOBAL_PATTERN  }}
          # serialization format is optional; default - "nquads"
          serialization-format: ${{  env.SERIALIZATION_FORMAT  }}
          # the name of the directory where all the output files will be stored
          output-directory: ${{  env.OUTPUT_DIRECTORY  }}
          # convert-all is optional; default - "false"
          # if convert-all is "true", the action will always convert all the files to
          # RDF based on the yarrrml-files provided by `GLOBAL_PATTERN`, even if no
          # changes were detected
          convert-all: ${{ env.CONVERT_ALL }}

      # Push the generated RDF files to the repository
      - name: Commit and push the output
        run: |
          git config --global user.name 'your_username'
          git config --global user.email 'your.email@example.com'
          git add .
          set +e
          git status | grep "nothing to commit, working tree clean"
          if [ $? -eq 0 ]; then set -e; echo "INFO: No changes since last run"; else set -e; \
            git commit -m "feat: convert to RDF with Github Actions"; git push; fi
        shell: bash
```

If you are using the example workflow that was provided above, make sure to update it as follows:

- Verify whether the conditions to trigger the action are set properly (change the name of the branch(-es) if needed etc.).
- Configure the environment variables for the input parameters for the action under `jobs` > `build` > `env` (`GLOBAL_PATTERN`, `SERIALIZATION_FORMAT`, `OUTPUT_DIRECTORY` and `CONVERT_ALL`).
- In the "Commit and push the output" step, replace `user.name` and `user.email` from the example with your github username and email. You may also want to change the commit message that will be used to commit the files created by the action.

The `RMLio/rml-action` action will perform the following operations:

1. iterate over all files matching the provided global pattern (which are all expected to contain `YARRRML` rules and have an extension `.yaml` or `.yml`)
2. convert `YARRRML` rules in all these files to RDF

**Note:** you need to follow the guidelines of the above workflow file example (step "Commit and push the output") to commit and push all of the generated data to your repository.

## Inputs

### `global-pattern`

The global pattern that matches all the mapping files that need to be converted (e.g. `"*.yml"`). The pattern has to be surrounded by quotes.

### `serialization-format` (optional)

The serialization format that needs to be used for conversion. Default: `nquads`. Possible values: `nquads`, `turtle`, `trig`, `trix`, `jsonld`, `hdt`.

### `output-directory`

The relative path from the root of your repository to a directory where the output files will be stored (e.g. `output` (or `path_from_root/output_folder_name`), this will save all the output files to a folder named `output` (or `path_from_root/output_folder_name`) that can be found at the root of the repository).

### `convert-all` (optional)

An indicator as to whether or not the conversion should be run for all files. Default: `false`. Possible values: `true`, `false`.
If `convert-all` is set to `true`, all files will be converted, even if no changes were detected.
If the meta folder of the action (`rml_action_meta`) or some file in that folder is not present (e.g. it was deleted), again, all files will be converted, even if no changes were made to the input files.

## Important remarks

- Don't remove the meta folder for this action (`rml_action_meta`). This folder is created when the action runs for the first time and contains the information that is relevant for it. Removing this folder won't cause any errors - it will just be created again, but this will result in a performance loss, since all the files will be converted again.
- Changes to the output folder are not detected. This means that if you remove a part of or all of the files that were already generated and are stored in the output folder, they will not be generated again by default. In this case, you might want to set `convert-all` to `true` to convert all the files once again.
- If some files (yarrrml-files or data source files) have been added/removed or renamed, the action will run for all the files (all of them will be converted).
- If some files (yarrrml-files or data source files) have been modified, the action will only convert the modified files (if data source files were modified) or the files that are a part of yarrrml-files that were modified.
