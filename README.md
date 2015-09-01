# Descriptions

This repository contains scripts to analyze a target data set (typically a
bunch of projects) and report the license inconsistencies within this data set.

This tool is an implementation of the method in our paper:

Yuhao Wu, Yuki Manabe, Tetsuya Kanda, Daniel M. German and Katsuro Inoue. A Method 
to Detect License Inconsistencies in Large-Scale Open Source Projects. In 12th Working
Conference on Mining Software Repositories (MSR 2015).

This paper can be downloaded here:
http://sel.ist.osaka-u.ac.jp/lab-db/betuzuri/archive/992/992.pdf

# How to use it

Run the LicenseAnalyse.pl script, it will complete the analysis.

This scipt will use the configuration in config.txt file. This file contais 
three lines, example as follows:

```
/path/to/your/analysis/target/
cpp,c,java,
20
```

The first line is the path to the projects.
The second line is the type of source code file to analyse, seperated by ','.
The third line is the threshold of lines of token files we consider as valid. 
Since some source files are too small to be considered as copies of each other,
we use this value to filter out these false postives. "20" is an experience value.

# Output

The grouped source files are under AnalysisData/Source/.
And the analysis results are under the folder AnalysisData/Statistics/.
