# Detect architecture
ARCH := $(shell uname -m)

SRC_DIR := src

# X86_64 architecture with Intel MKL
ifeq ($(ARCH),x86_64)

ifndef MKLROOT
$(error MKLROOT is not set. Please run: source /opt/intel/oneapi/setvars.sh)
endif

MKL_ROOT = $(MKLROOT)
MKL_LIBROOT = $(MKL_ROOT)/lib/intel64
MKL_INCROOT = $(MKL_ROOT)/include

# Use g++ instead of icpc - otherwise strange NaN values
COMP = g++ -mkl -Wall 
CCOMP = icc
CFLAGS = -O3 -std=c++11 -I$(MKL_INCROOT)
CFLAGS_C = -O3 -fPIE -I$(MKL_INCROOT)

MKL_LIB = -Wl,--start-group $(MKL_LIBROOT)/libmkl_intel_lp64.a $(MKL_LIBROOT)/libmkl_intel_thread.a $(MKL_LIBROOT)/libmkl_core.a -Wl,--end-group -liomp5 -lpthread -lm -ldl

# Use utilities.c and not utilities.cpp
CPP_SOURCES = $(SRC_DIR)/terapca.cpp $(SRC_DIR)/methods.cpp
C_SOURCES = $(SRC_DIR)/gaussian.c $(SRC_DIR)/gennorm.c $(SRC_DIR)/io.c $(SRC_DIR)/utilities.c
EXE = TeraPCA.exe

CPP_OBJECTS = $(CPP_SOURCES:$(SRC_DIR)/%.cpp=%.o)
C_OBJECTS = $(C_SOURCES:$(SRC_DIR)/%.c=%.o)
OBJECTS = $(CPP_OBJECTS) $(C_OBJECTS)

$(EXE): $(OBJECTS)
	$(COMP) $(OBJECTS) -o $@ $(MKL_LIB)

%.o: $(SRC_DIR)/%.cpp
	$(COMP) $(CFLAGS) -c $< -o $@

%.o: $(SRC_DIR)/%.c
	$(CCOMP) $(CFLAGS_C) -c $< -o $@

clean:
	rm -f *.exe *.o *~


# ARM64 architecture with OpenBLAS and OpenMP
else ifeq ($(ARCH),arm64)

OPENBLAS_ROOT = /opt/homebrew/opt/openblas
OPENBLAS_INC = $(OPENBLAS_ROOT)/include
OPENBLAS_LIB = $(OPENBLAS_ROOT)/lib

OPENMP_ROOT = /opt/homebrew/opt/libomp
OPENMP_INC = $(OPENMP_ROOT)/include
OPENMP_LIB = $(OPENMP_ROOT)/lib

COMP = clang++
CCOMP = clang
CFLAGS = -Wall -O3 -std=c++11 -I$(OPENBLAS_INC) -I$(OPENMP_INC) -Xpreprocessor -fopenmp
CFLAGS_C = -Wall -O3 -I$(OPENBLAS_INC) -I$(OPENMP_INC) -Xpreprocessor -fopenmp
LDFLAGS = -L$(OPENBLAS_LIB) -lopenblas -L$(OPENMP_LIB) -lomp -lpthread -lm

CPP_SOURCES = $(SRC_DIR)/terapca.cpp $(SRC_DIR)/utilities.cpp $(SRC_DIR)/methods.cpp
C_SOURCES = $(SRC_DIR)/gaussian.c $(SRC_DIR)/gennorm.c $(SRC_DIR)/io.c
EXE = TeraPCA.exe

CPP_OBJECTS = $(CPP_SOURCES:$(SRC_DIR)/%.cpp=%.o)
C_OBJECTS = $(C_SOURCES:$(SRC_DIR)/%.c=%.o)
OBJECTS = $(CPP_OBJECTS) $(C_OBJECTS)

$(EXE): $(OBJECTS)
	$(COMP) $(OBJECTS) -o $@ $(LDFLAGS)

%.o: $(SRC_DIR)/%.cpp
	$(COMP) $(CFLAGS) -c $< -o $@

%.o: $(SRC_DIR)/%.c
	$(CCOMP) $(CFLAGS_C) -c $< -o $@

clean:
	rm -f *.exe *.o *~

else
$(error Unsupported architecture: $(ARCH))
endif

.PHONY: all clean
all: $(EXE)
