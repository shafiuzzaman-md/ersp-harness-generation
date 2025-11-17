# LLM-Assisted Fuzzing and Symbolic Execution Harness Generation

## Daniil Novak


## Example build
for each cwe, go to output/generated, and run the build.sh file. Then run the run_klee.sh file.

## Python usage
### readandprint.py
Input the target directory as an arg:
python3 readandprint.py <TARGET DIRECTORY>

### createfiles.py
Input the file to read from (NOTE, this may be buggy and require some manual edits.).

## Info
I will elaborate further later, but essentially I tried to make the LLM understand and directly work with my environment. 