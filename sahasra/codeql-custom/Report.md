# CodeQL Assignment - Sahasra

## Target Selection
Initially, I worked with CWE 126, which I had worked with in previous tasks. 

## Baseline

Make Based Build:
```
codeql database create db-CWE126 \
  --language=cpp \
  --command="make all"
```

Analyzing database to create baseline.sarif:
```
codeql database analyze db-CWE126 codeql/cpp-queries \
  --format=sarif-latest --output=baseline.sarif
```

## Task 2: v1
Commands 
```
codeql database analyze db-CWE126   /root/codeql-custom   --rerun   --format=sarif-latest   --output=v1.sarif
```
I started with the Starter Query provided by Shafi, but noticed that it was leading to errors. I researched on how to fix these errors and better understood CodeQL. The updated query is in the file ersp-oob-memory-length.ql. 
In the v1.sarif file, I noticed that I was getting 0 results. 

## Task 3: v2
Since there is a lot of variation in the CWE126 testcases, I decided to focus on the ones related to memmove. My query in 'memmove-query.ql' detects locations where the size is calculated from the destination (the first parameter) instead of the source (the second parameter), leading to a potential overread. The query detects locations in the bad() function and the GoodG2B() function. Buffer Overread is only a problem in the bad() functions since the source is smaller than the size parameters. However, the GoodG2B() functions also have a potential flaw, since the size parameter still relies on the destination size. 
Overall, 399 locations were detected. The corresponding SARIF file is v3.sarif.
Some examples are:
```
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_01.cpp",
  "line": 40
}
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_01.cpp",
  "line": 66
}
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_02.cpp",
  "line": 43
}
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_02.cpp",
  "line": 102
}
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_02.cpp",
  "line": 77
}
{
  "message": "memmove may read beyond source buffer: size is calculated from destination instead of source",
  "file": "s02/CWE126_Buffer_Overread__new_char_memmove_03.cpp",
  "line": 102
}
```

Example of a True Positive:
```
// "file": "s02/CWE126_Buffer_Overread__new_char_memmove_01.cpp"

void bad()
{
    char * data;
    data = NULL;
    /* FLAW: Use a small buffer */
    data = new char[50];
    memset(data, 'A', 50-1); /* fill with 'A's */
    data[50-1] = '\0'; /* null terminate */
    {
        char dest[100];
        memset(dest, 'C', 100-1);
        dest[100-1] = '\0'; /* null terminate */
        /* POTENTIAL FLAW: using memmove with the length of the dest where data
         * could be smaller than dest causing buffer overread */
        memmove(dest, data, strlen(dest)*sizeof(char));
        dest[100-1] = '\0';
        printLine(dest);
        delete [] data;
    }
}
```

## Further Refinement Notes:
Further refinement could include a more specific and complex query that checks the size of the dest and 'data' parameters and compares that to the size parameter in the memmove() function call. 