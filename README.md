LicenseTools
============
Run the LicenseAnalyse.pl script to get all the identical files.

This scipt will use the configuration in config.txt file. This file contais 
three lines, example as follows:
-----------------
/home/t-kanda/HDQL16/src_debian-750/
cpp,c,java,
3
-----------------

The first line is the path to the project.
The second line is the type of source code file to analyse, seperated by ','.
The third line is the threshold of files to copy. For example, for cpp files,
we got the result of same-name files like below, the script will only copy the
top 3 file-names, which is main.cpp, mainwindow.cpp and nothing_to_do.pass.cpp.

------------
(In statistics.cpp.txt file)
file name;count
---------
main.cpp;2994
mainwindow.cpp;340
nothing_to_do.pass.cpp;209
Main.cpp;146
test.cpp;145
Client.cpp;142
window.cpp;128
...
------------

The copied source files are under the folder AnalysisData/Source/.
And the statistics are under the folder AnalysisData/Statistics/.