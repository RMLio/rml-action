# rml-action

`rml-action` is a GitHub Action that converts a structured data source file (e.g. JSON, XML, CSV...) to RDF
[Resource Description Framework (RDF)](https://www.w3.org/RDF/). Multiple serialization formats are supported: `nquads` (default), `turtle`, `trig`, `trix`, `jsonld`, `hdt`.

## Usage

Create a `.github/workflows/data.yaml` file in the repository where you want to fetch data. An example:

```yaml
name: Convert to RDF Workflow

on:
  # Triggers the workflow on push or pull request events but only for the master branch
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      # Checks-out your repository
      - uses: actions/checkout@v2
        
      - name: Creates an output directory for RDF files (if doesn't exist)
        run: mkdir -p output
        shell: bash
        
      - name: Converts YARRRML rules to RDF
        uses: RMLio/rml-action@main
        with:
          # the name of the directory that stores all the input files (JSON/XML/CSV/...) 
          # and the corresponding YARRRML mappings
          input-directory: data
          # serialization format is optional; default - "nquads"
          serialization-format: turtle
          # the name of the directory where all the output files will be stored
          output-directory: output
        
      - name: Commit and push the output
        run: |
          git config --global user.name 'elytvyno'
          git config --global user.email 'elena.lytvynova@ugent.be'
          git add .
          set +e
          git status | grep "nothing to commit, working tree clean"
          if [ $? -eq 0 ]; then set -e; echo "No changes since last run"; else set -e; \
            git commit -m "feat: convert to RDF with Github Actions"; git push; fi
        shell: bash
```
If you are using the example that was provided above:
- Make sure to check whether the conditions to trigger the action are set properly (change the name of the branch(-es) if needed etc.).
- Configure the input parameters for the action.
- In the "Commit and push the output" step, replace `user.name` and `user.email` from the example with your github username and email. You may also want to change the commit message that will be used to commit the files created by the action.

The `RMLio/rml-action` action will perform the following operations:
1. iterate over all files containing `YARRRML` rules in the `input-directory`
2. convert `YARRRML` rules in all these files to RDF

**Note that** you need to follow the guidelines of the above workflow file example (step "Commit and push the output") to commit and push all of the generated data to your repository.

## Inputs

### `input-directory`

The relative path from the root of your repository to a directory where the input files (data files, e.g. JSON/XML/CSV/... and YARRRML rules) that need to be converted are stored.

### `serialization-format` (optional)

The serialization format that needs to be used for convertion. Default: `nquads`.

### `output-directory`

The relative path from the root of your repository to a directory where the output files will be stored.
