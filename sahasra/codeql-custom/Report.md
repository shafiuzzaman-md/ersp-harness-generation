# CodeQL Assignment - Sahasra

## Target Selection
Initially, I worked with CWE 126, which I had worked with in previous tasks. 

## Baseline

Make Based Build:
```codeql database create db-CWE126 \
  --language=cpp \
  --command="make all"
```

Analyzing database to create baseline.sarif:
```codeql database analyze db-CWE126 codeql/cpp-queries \
  --format=sarif-latest --output=baseline.sarif
```

## Task 2: v1
Commands 
```
codeql database analyze db-CWE126   /root/codeql-custom   --rerun   --format=sarif-latest   --output=v1.sarif
```
I started with the Starter Query provided by Shafi, but noticed that it was leading to errors. I researched on how to fix these errors and better understood CodeQL. The updated query is in the file ersp-oob-memory-length.ql. 
In the v1.sarif file, I noticed that I was getting 0 results. I attempted to fix this in v2.sarif. 

## Task 3: v2
I attempted to refine my queries, but I still ended up with 0 results.
Gowever, since CWE 126 includes vulnerabilities related to setting a buffer size, I realized I should be looking for strncpy or wcsncpy instead of memcpy or malloc. These are used a lot more within the CWE 126 files. Since my v1 and v2 attempts looked for memcpy, it makes sense that my results equal zero. 

