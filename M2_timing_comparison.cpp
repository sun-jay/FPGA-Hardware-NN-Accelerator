
// cd /Users/sunnyjay/Documents/vscode/NNFS/"Python imple" && g++ mmtest.cpp -o mmtest -std=c++17 && ./mmtest


#include <iostream>
#include <vector>
#include <random>
#include <chrono>

using namespace std;

// Function to generate a random matrix with normal distribution
vector<vector<int32_t>> generate_random_matrix(int rows, int cols) {
    random_device rd;
    mt19937 gen(rd());
    normal_distribution<> dist(0, 1);

    vector<vector<int32_t>> matrix(rows, vector<int32_t>(cols));
    for (auto& row : matrix) {
        for (auto& elem : row) {
            elem = dist(gen);
        }
    }
    return matrix;
}

// Function to generate a random vector with normal distribution
vector<int32_t> generate_random_vector(int size) {
    random_device rd;
    mt19937 gen(rd());
    normal_distribution<> dist(0, 1);

    vector<int32_t> vec(size);
    for (auto& elem : vec) {
        elem = dist(gen);
    }
    return vec;
}

// Function to perform matrix-vector multiplication (result passed by reference)
void matrix_vector_multiply(const vector<vector<int32_t>>& A, const vector<int32_t>& v, vector<int32_t>& result) {
    int rows = A.size();
    int cols = A[0].size();

    for (int i = 0; i < rows; ++i) {
        result[i] = 0; // Reset the result value for each row
        for (int j = 0; j < cols; ++j) {
            result[i] += A[i][j] * v[j];
        }
    }
}

int main() {
    // Define dimensions
    float sum = 0;
    int num = 200;
    
    for (int i = 0; i < num; i++) {

        int rows = 50;
        int cols = 50;

        // Generate a random matrix A and a random vector v
        vector<vector<int32_t>> A = generate_random_matrix(110, 784);
        vector<int32_t> v = generate_random_vector(784);
        vector<int32_t> result(110, 0);  // Pre-allocate result vector outside the function

        // Start timing
        auto start = chrono::high_resolution_clock::now();

        // Perform matrix-vector multiplication
        matrix_vector_multiply(A, v, result);

        // End timing
        auto end = chrono::high_resolution_clock::now();
        auto duration = chrono::duration_cast<chrono::nanoseconds>(end - start).count();

        cout << "Time taken for matrix-vector multiplication: " << duration << " nanoseconds" << endl;

        sum += duration;

        // Clear and shrink vectors to free memory
        A.clear();
        A.shrink_to_fit();

        v.clear();
        v.shrink_to_fit();

        result.clear();
        result.shrink_to_fit();
    }
    
    cout << "Average time taken for matrix-vector multiplication: " << sum/num << " nanoseconds. " << "N = " << num << endl;

    return 0;
}