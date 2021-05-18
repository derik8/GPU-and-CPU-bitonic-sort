# GPU-and-CPU-bitonic-sort

In this implementation of bitonic sorting using CUDA technology. 


### Program options:
+ -d - select a device for sorting (GPU or CPU);
+ -s - amount of data for sorting (integer 2^n, where n is the number of data; max is 2^24);
+ -i - input text file, which contains data for sorting;
+ -o - source text file, where the sorted data will be written;
+ -n - source text file, which will be written MMBS (the matrix of a bitonic sorting network (MMBS) is a two-dimensional array containing information about pairs for exchange for bitonic sort. The number of columns in the matrix is the number of data, and the number of rows is the number of substages in the bitonic sort)

### Examles
1)GPU, size-16, data in file, output in file, greate NBS:

-d GPU -s 16 -i in.txt -o out.txt -n out_nbs.txt


2)CPU, size-1024, rand data, output in file, greate NBS:

-d CPU -s 1024 -o out.txt -n out_nbs.txt


3)GPU, size-2048, data in file, output in file, greate NBS:

-d GPU -s 2048 -i in.txt -o out.txt

