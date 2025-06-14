# Detect architecture
ARCH := $(shell uname -m)

# Intel x86_64
ifeq ($(ARCH),x86_64)

MKL_ROOT = /apps/rhel6/intel/mkl
MKL_LIBROOT = $(MKL_ROOT)/lib/intel64
MKL_LIB = -L$(MKL_LIBROOT) -lmkl_blas95_lp64 -lmkl_lapack95_lp64 \
	-Wl,--start-group \
	$(MKL_LIBROOT)/libmkl_intel_lp64.a \
	$(MKL_LIBROOT)/libmkl_intel_thread.a \
	$(MKL_LIBROOT)/libmkl_core.a \
	$(MKL_LIBROOT)/libmkl_sequential.a \
	-Wl,--end-group -qopenmp -lmkl_intel_lp64 -lmkl_gnu_thread -lmkl_core \
	-liomp5 -lpthread -lm -V

COMP = icpc -mkl -Wall
CFLAGS = -O3
SOURCE = terapca.cpp
EXE = TeraPCA.exe
OBJ = terapca.o

$(EXE): $(OBJ)
	$(COMP) $(SOURCE) utilities.cpp gaussian.c gennorm.c methods.cpp io.c -o $@ $(MKL_LIB)

%.o: %.cpp
	$(COMP) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.exe *.o *~

# Apple Silicon (ARM64, e.g. MacBook)
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

CPP_SOURCES = terapca.cpp utilities.cpp methods.cpp
C_SOURCES = gaussian.c gennorm.c io.c
EXE = TeraPCA.exe

CPP_OBJECTS = $(CPP_SOURCES:.cpp=.o)
C_OBJECTS = $(C_SOURCES:.c=.o)
OBJECTS = $(CPP_OBJECTS) $(C_OBJECTS)

$(EXE): $(OBJECTS)
	$(COMP) $(OBJECTS) -o $@ $(LDFLAGS)

%.o: %.cpp
	$(COMP) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CCOMP) $(CFLAGS_C) -c $< -o $@

clean:
	rm -f *.exe *.o *~

else
$(error Unsupported architecture: $(ARCH))
endif

.PHONY: all clean
all: $(EXE)