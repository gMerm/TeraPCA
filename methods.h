#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include "structures.h"

// Detect architecture and include appropriate BLAS/LAPACK headers
#if defined(__x86_64__) || defined(_M_X64)
    #include "mkl.h"
    #include "mkl_lapacke.h"
#elif defined(__aarch64__) || defined(__arm__) || defined(__ARM_ARCH) || defined(arm64)
    #include <cblas.h>
    #include <lapacke.h>
    #include <chrono>
    // Replacement for Intel MKL's dsecnd() function
    // Returns time in seconds with high precision
    static double dsecnd() {
        static auto start_time = std::chrono::high_resolution_clock::now();
        auto current_time = std::chrono::high_resolution_clock::now();
        return std::chrono::duration<double>(current_time - start_time).count();
    }

#else
    #error "Unsupported architecture: please define BLAS/LAPACK backend for this platform."
#endif

//=========================
// Define min, max routines
//=========================
#define min(a,b) (a<=b?a:b)
#define max(a,b) (a>=b?a:b)
//=========================

void subspaceIteration(double *MAT, double *RHS2, struct logistics *logg);

void BlockSubspaceIter(std::ifstream& in, double *RHS2, logistics *logg);

void benchmarking(std::ifstream& in, double *RHS2, logistics *logg);
