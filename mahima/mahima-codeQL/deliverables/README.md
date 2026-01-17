# Reproducibility:

The CMakeLists.txt is at the root level, not in individual CWE directories, so I made a simple build script.

# Build script:
cd ~/ersp-harness-generation/mahima-codeQL 

cat > build.sh << 'EOF' 
#!/bin/bash 
cd $HOME/mahima-codeql-wk1/juliet-test-suite-c/testcases/CWE415_Double_Free/s01 
for file in *.c; do 
[ -e "$file" ] && gcc -c "$file" -I../../../testcasesupport 2>/dev/null || true 
done 
EOF 

chmod +x build.sh

## Create CWE 415 db:
codeql database create db-juliet-cwe415 \ 
--language=cpp \ 
--command="./build.sh" \ --source-root=$HOME/mahima-codeql-wk1/juliet-test-suite-c/testcases/CWE415_Double_Free/s01 \ 
--overwrite

# Sanity check:
codeql database analyze db-juliet-cwe415 codeql/cpp-queries \ 
--format=sarif-latest --output=baseline.sarif

# Create custom CodeQL pack:
mkdir -p codeql-custom/queries
touch codeql-custom/qlpack.yml 
touch codeql-custom/README.md 
touch codeql-custom/queries/ersp-oob-memcpy-length.ql

# qlpack.yml
cat > codeql-custom/qlpack.yml << 'EOF' 
name: ersp/custom-cpp-queries 
version: 0.0.1 
dependencies: codeql/cpp-all: "*" 
EOF

# Custom Query v1:
CWE-415 (Double Free) isn't about memcpy so I changed the query to detect double-free.

# Run the query:
codeql pack install 

codeql database analyze ../db-juliet-cwe415 \ 
queries/ersp-oob-memcpy-length.ql \ 
--format=sarif-latest \ 
--output=../v1.sarif

# Revised Query v2:
Refinements: filters out NULL-checked pointers, ignores different control flow branches.

# Run the Query:
codeql database analyze ../db-juliet-cwe415 \ 
queries/ersp-double-free-v2.ql \ 
--format=sarif-latest \ 
--output=../v2.sarif

# Refinement notes:
Get comparison data:

cd ~/ersp-harness-generation/mahima-codeQL

python3 << 'EOF'
import json

with open('v1.sarif', 'r') as f:
    v1_data = json.load(f)
with open('v2.sarif', 'r') as f:
    v2_data = json.load(f)

v1_results = v1_data['runs'][0]['results']
v2_results = v2_data['runs'][0]['results']

print("="*70)
print("REFINEMENT SUMMARY")
print("="*70)
print(f"\nv1 findings: {len(v1_results)}")
print(f"v2 findings: {len(v2_results)}")
print(f"Reduction: {len(v1_results) - len(v2_results)} findings removed")
print(f"Percentage: {((len(v1_results) - len(v2_results)) / len(v1_results) * 100):.1f}% reduction\n")

v1_files = set()
v2_files = set()

for result in v1_results:
    uri = result['locations'][0]['physicalLocation']['artifactLocation']['uri']
    line = result['locations'][0]['physicalLocation']['region']['startLine']
    v1_files.add(f"{uri}:{line}")

for result in v2_results:
    uri = result['locations'][0]['physicalLocation']['artifactLocation']['uri']
    line = result['locations'][0]['physicalLocation']['region']['startLine']
    v2_files.add(f"{uri}:{line}")

removed = v1_files - v2_files
print(f"Example findings REMOVED in v2 (false positives filtered):")
print("="*70)
for i, finding in enumerate(list(removed)[:3]):
    print(f"{i+1}. {finding}")
print()

kept = v1_files & v2_files
print(f"Example findings KEPT in v2 (true positives):")
print("="*70)
for i, finding in enumerate(list(kept)[:3]):
    print(f"{i+1}. {finding}")
EOF

# Results:
======================================================================
REFINEMENT SUMMARY
======================================================================

v1 findings: 1080
v2 findings: 108
Reduction: 972 findings removed
Percentage: 90.0% reduction

Example findings REMOVED in v2 (false positives filtered):
======================================================================
1. CWE415_Double_Free__malloc_free_wchar_t_63b.c:28
2. CWE415_Double_Free__malloc_free_int64_t_66a.c:74
3. CWE415_Double_Free__malloc_free_int_06.c:39

Example findings KEPT in v2 (true positives):
======================================================================
1. CWE415_Double_Free__malloc_free_long_10.c:39
2. CWE415_Double_Free__malloc_free_struct_05.c:4

