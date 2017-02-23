#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <iostream>
#include <numeric>
#include <math.h>
#include <cuda.h>



int block = 1024;
int thread = 1024;
__device__ int mandel(float cr, float ci);

__device__ int mandel(float cr, float ci){
	float zr=0, zi=0, zr2=0, zi2=0;
	int i;
	for(i=1;i<256;i++){
		zi=zr*zi;
		zi+=zi;
		zi+=ci;
		//zi=2*zr*zi+ci;
		zr=zr2-zi2+cr;
		zr2=zr*zr;
		zi2=zi*zi;
		if(zr2+zi2>4)
			break;
	}
	//printf("yo %d\n",i);
	return i;
}

__global__ void kernel(int *arr, int width, int height, float Xmin, float Ymin, float Xinc, float Yinc){


	float px_per_thread = width*height/(gridDim.x*blockDim.x);
	float index = blockDim.x*blockIdx.x+threadIdx.x;
	float offset = px_per_thread*index;
	for(int i=offset; i<offset+px_per_thread;i++){
		int x=i%width;
		int y=i/width;
		float cr=Xmin+x*Xinc;
		float ci=Ymin+y*Yinc;
		arr[y*width + x] = mandel(cr, ci);

	}
	//if(gridDim.x * blockDim.x * px_per_thread < width*height && index < (width*height) - (blockDim.x * gridDim.x)){
		//int i = blockDim.x * gridDim.x * px_per_thread + index;
		//int x = i%width;
		//int y = i/width;
		//float cr = xmin + x*0.00293;
		//float ci = ymin + y*0.0039;
		//arr[y*width+x] = mandel(cr, ci);
		//arr[y*width+x] = 500;
	//}
	//printf("index %f\n", index);
}

int main(int argc, char *argv[]){
    clock_t tic = clock();
    if(argc != 4){
        printf("Enter width, height and filename\n");
        return 1;
    }
    int width = atoi(argv[1]);
    int height = atoi(argv[2]);
	int size = width*height*sizeof(int);
	int *ar;
	int *d_arr;
	float Xmin = -2, Xmax = 1, Ymin = -1.5, Ymax = 1.5;
	float Xinc = (Xmax-Xmin)/width;
	float Yinc = (Ymax-Ymin)/height;

    //cuda memory
	cudaMalloc((void**) &d_arr, size);

	//host memory
    ar = (int*)malloc(size);

    //run cuda
	kernel<<<block, thread>>>(d_arr, width, height, Xmin, Ymin, Xinc, Yinc);

	cudaMemcpy(ar, d_arr, size, cudaMemcpyDeviceToHost);

	//Create and write output
	FILE *fp;
	fp = (fopen(argv[3],"w"));
	if(fp==NULL){
		printf("Error!");
		exit(1);
	}
	fprintf(fp,"%d %d\n", width, height);
	for(int i=0; i<(width*height);i++){
			fprintf(fp,"%d ",ar[i]);
	}

	cudaFree(d_arr);
	free(ar);
    clock_t toc = clock();

    float time_spent = (float)(toc-tic)/CLOCKS_PER_SEC;
    printf("CUDA Execution Time %f sec\n", time_spent);
}

