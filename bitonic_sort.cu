#include<iostream>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h> 
#include<string.h>
#include<string>
#include<cuda.h>
#include "cuda_runtime.h"
#include<vector>
#include <algorithm>  


#include <fstream>
#include<ctime>
#include<chrono>



__global__  static void bitonicSequence(int * values, int k, int j);

void sort_GPU(int * mass,int size);
void sort_CPU(int * mass, int size);

void write(std::ofstream &file, int * mass, int size, std::string s);
void generate_mass(  int * mass, int size);
void read_mass(std::ifstream &file, int * mass,  int size);
void write_nbs(std::ofstream & file,int size);

int main(int argc, char* argv[])
{
	srand(time(0));
	
	std::vector<std::string> vec_arg;

	
	for (int i = 0; i < argc; i++) {
		
		vec_arg.push_back(std::string(argv[i]));
	}

	std::vector<std::string>::iterator d = find(vec_arg.begin(), vec_arg.end(), "-d");
	std::vector<std::string>::iterator s = find(vec_arg.begin(), vec_arg.end(), "-s");
	std::vector<std::string>::iterator i = find(vec_arg.begin(), vec_arg.end(), "-i");
	std::vector<std::string>::iterator o = find(vec_arg.begin(), vec_arg.end(), "-o");
	std::vector<std::string>::iterator n = find(vec_arg.begin(), vec_arg.end(), "-n");
	
	
//size mass
	int size_mass = stoi(*(++s));

//mass
	int *mass = new int[size_mass];
	

//read or generate data
	if(i!=vec_arg.end()){
		std::ifstream file_read(*(++i));
		read_mass(file_read, mass, size_mass);
	}
	else {
		generate_mass(mass, size_mass);
	}
	
	

	std::cout << "calculation" << std::endl;

// start sort GPU or CPU
	if(*(++d)=="GPU")
		sort_GPU(mass, size_mass);
	else
		sort_CPU(mass, size_mass);
		
	
	if (o != vec_arg.end())	{
		std::cout << "write to file..."<< std::endl;
		std::ofstream file_write(*(++o));
		write(file_write, mass, size_mass, *d);
		
	}
	
	if (n != vec_arg.end()){
		std::cout << "write to file..."<< std::endl;
		std::ofstream file_write(*(++n));
		write_nbs(file_write, size_mass);	
		
	}
	

	

	delete[] mass;
	system("pause");
	return 0;
}


__global__  static void bitonicSequence(int * values, int k, int j)
{
	int temp;
	int tid = blockIdx.x * blockDim.x + threadIdx.x;


	unsigned int ixj = tid ^ j;
	if (ixj > tid) {
		if ((tid & k) == 0)
		{
			if (values[tid] > values[ixj]) {
				temp = values[tid];
				values[tid] = values[ixj];
				values[ixj] = temp;
			}
		}
		else
		{
			if (values[tid] < values[ixj]) {
				temp = values[tid];
				values[tid] = values[ixj];
				values[ixj] = temp;
			}
		}

	}
}

void sort_GPU(int * mass, int size)
{
	


	std::cout << "GPU" << std::endl;

	
	int * dvalues;
	cudaMalloc(&dvalues, sizeof(int) * size);
	cudaMemcpy(dvalues, mass, sizeof(int) * size, cudaMemcpyHostToDevice);

	int threads = 128;
	int blocks = ceil(size / threads);

	if (size < threads)
	{
		threads = size;
		blocks = 1;
	}
	
	cudaEvent_t start, stop;
	float gpuTime = 0.0f;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	
	


	for (unsigned int k = 2; k <= size; k *= 2) {
		for (unsigned int j = k / 2; j > 0; j /= 2) {
			bitonicSequence << <blocks, threads >> > (dvalues, k, j);
			
		}
	}
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&gpuTime, start, stop);

	std::cout << "time: " << gpuTime <<" milliseconds"<<  std::endl;
	

	cudaMemcpy(mass, dvalues, sizeof(int) * size, cudaMemcpyDeviceToHost);


	cudaFree(dvalues);

}

void sort_CPU(int * mass, int size)
{
	
	std::cout << "CPU" << std::endl;

	auto start = std::chrono::high_resolution_clock::now();
	for (unsigned int k = 2; k <= size; k *= 2) 
	{
		for (unsigned int j = k / 2; j > 0; j /= 2)
		{
			for (int i = 0; i < size; i++)
			{
				unsigned int ixj = i ^ j;
				if (ixj > i) {
					
					
					if ((i & k) == 0)
					{
						if (mass[i] > mass[ixj])
							std::swap(mass[i], mass[ixj]);			

					}
					else
					{
						if (mass[i] < mass[ixj])
							std::swap(mass[i], mass[ixj]);
						
					}					
				}
			}			
		}
	}
	auto elapsed = std::chrono::high_resolution_clock::now() - start;
	long long microseconds = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
	std::cout << "time: " << (double)microseconds/1000 << " milliseconds" << std::endl;
}

void write(std::ofstream &file, int * mass, int size,std::string s)
{
	if (file.is_open())
	{
		file << s << std::endl;
		for (int i = 0; i < size; i++)
		{
			file << mass[i] << std::endl;
		}
		file.close();
	}
	else std::cout << "Unable to open file";
}

void generate_mass(int * mass, int size)
{
	for (int i = 0; i < size; i++)
	{
		mass[i] = rand();
	}
	
}

void read_mass(std::ifstream &file,int *mass,  int size)
{
	
	if (file.is_open())
	{
		for (int i = 0; i < size; i++)
		{
			file >> mass[i];
		}
		
		file.close();
	}

	else std::cout << "Unable to open file";
}

void write_nbs(std::ofstream & file, int size)
{
	int *mass_index_BN = new int[size];

	for (unsigned int k = 2; k <= size; k *= 2)	{
		for (unsigned int j = k / 2; j > 0; j /= 2)	{
			for (int i = 0; i < size; i++){

				unsigned int ixj = i ^ j;

				if (ixj > i) {
					mass_index_BN[i] = ixj + 1;
					mass_index_BN[ixj] = i + 1;
					if ((i & k) == 0)
						mass_index_BN[ixj] *= -1;
					else
						mass_index_BN[i] *= -1;
				}
				
			}
			for (size_t i = 0; i < size; i++){
				file << mass_index_BN[i] << " ";
			}
			file << std::endl;
		}
		file << std::endl;
	}

	file.close();
	delete[]mass_index_BN;	
}
