# Process Statistics

This is our first project of the *Operating Systems* class, written in BASH. This script is used to visualize the total memory quantity of a process, the quantity of physical memory occupied by a process, the total number of input/output bytes a process read/wrote and the read/write rate corresponding to the last *s* seconds of a process.

## Introduction

The procstat.sh script allows us to:
- View the amount of total memory and the memory resident in physical memory (VmSize and VmRSS lines from */proc/[pid]/status*)
- The number of total I/O bytes (rchar and wchar lines from */proc/[pid]/io*)
- The read/write rate (in bytes per second) of the processes selected in the last *s* seconds (calculated from 2
readings from */proc/[pid]/io* with *s* seconds interval). 

This script has a mandatory parameter which is the number of seconds that will be used to calculate the I/O rates. The selection of the processes to be visualized can be performed through a regular expression that is verified with the associated command (as it appears in */proc/[pid]/comm*) **(option -c)**, or through the
definition of a time period for the start of the process. The specification of the time period is made through the minimum date **(option -s)** and maximum date **(option -e)** for the start of the process. The process selection can also be done using the username **(option -u)**. THE
visualization is formatted as a table, with a header, showing the processes by alphabetical order. The number of processes to be viewed is controlled by the **-p option**. There are also options to change the order of the table **(-m - sort on MEM ↑, -t - sort on RSS ↑, -d - sort on RATER ↑, -w
- sort on RATEW ↑ and -r - reverse)**.

## How to run

To run this script file, you will need to be in a Ubuntu based Operating System. Before running the script, make sure you give the user permissions to execute it by typing the following line in the command line:

```
chmod u+x procstat.sh
```

## Authors

- [João Reis](https://github.com/joaoreis16)
- [Ricardo Rodriguez](https://github.com/ricardombrodriguez)
