#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <ctime>
using namespace std;

__global__ void addKernel(int *dev_c, const int *dev_a, const int *dev_b, const int WIDTH){
    int a_idx = (blockIdx.y * blockDim.y + threadIdx.y) * WIDTH;
    int b_idx = blockIdx.x * blockDim.x + threadIdx.x;
    int c_idx = a_idx + b_idx;
    int sum = 0;

    for(int i = 0; i < WIDTH; i++, a_idx++, b_idx += WIDTH)
        sum += dev_a[a_idx] * dev_b[b_idx]; 
    dev_c[c_idx] = sum;

    return;
}

int main(void){
    const int WIDTH = 16;
    const int TILE_WIDTH = 2;
    int a[WIDTH][WIDTH], b[WIDTH][WIDTH], c[WIDTH][WIDTH];
    int c_check[WIDTH][WIDTH];
    int *dev_a, *dev_b, *dev_c;

    srand((unsigned int)time(NULL));

    for(int i = 0; i < WIDTH; i++){
        for(int j = 0; j < WIDTH; j++){
            a[i][j] = rand() % 10;
            b[i][j] = rand() % 10;
        }
    }

    cudaMalloc((void **)&dev_a, WIDTH * WIDTH * sizeof(int));
    cudaMalloc((void **)&dev_b, WIDTH * WIDTH * sizeof(int));
    cudaMalloc((void **)&dev_c, WIDTH * WIDTH * sizeof(int));

    cudaMemcpy((void *)dev_a, (void *)a, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy((void *)dev_b, (void *)b, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice);

    dim3 DimGrid(WIDTH / TILE_WIDTH, WIDTH / TILE_WIDTH, 1);
    dim3 DimBlock(TILE_WIDTH, TILE_WIDTH, 1);
    addKernel<<<DimGrid, DimBlock>>> (dev_c, dev_a, dev_b, WIDTH);

    cudaDeviceSynchronize();
    cudaMemcpy((void *)c, (void *)dev_c, WIDTH * WIDTH * sizeof(int), cudaMemcpyDeviceToHost);

    cout << "Matrix Multiplication" << endl;
    for(int i = 0; i < WIDTH; i++){
        for(int j = 0; j < WIDTH; j++)  cout << setw(4) << a[i][j];
        (i == WIDTH / 2) ? cout << "  *" : cout << "   ";

        for(int j = 0; j < WIDTH; j++)  cout << setw(4) << b[i][j];
        (i == WIDTH / 2) ? cout << "  =" : cout << "   ";

        cout << endl;
    }

    for(int i = 0; i < 4; i++){
        cout << i + 1 << " block : " << endl;
        int block_x = i / 2;
        int block_y = i % 2;
        int block_size = WIDTH / 2;
        for(int j = 0; j < block_size; j++){
            for(int k = 0; k < WIDTH / 2; k++)  cout << setw(4) << c[block_x * block_size + j][block_y * block_size + k];
            cout << endl;
        }
    }

    bool state = [&](){
        for(int i = 0; i < WIDTH; i++){
            for(int j = 0; j < WIDTH; j++){
                c_check[i][j] = 0;
                for(int k = 0; k < WIDTH; k++)  c_check[i][j] += a[i][k] * b[k][j];
                if(c[i][j] != c_check[i][j])    return false;
            }
        }
        return true;
    }();

    cout << "\n\nCheck Muliplication : " << (state == true ? "true" : "false") << endl;
    // for(int i = 0; i < WIDTH; i++){
    //     for(int j = 0; j < WIDTH; j++)  cout << setw(4) << c_check[i][j];
    //     cout << endl;
    // }

    cudaFree(dev_a);
    cudaFree(dev_b);
    cudaFree(dev_c);
}