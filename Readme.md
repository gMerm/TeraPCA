# TeraPCA 🧬⚡

> **Enhanced Fork** - Multithreaded Principal Component Analysis for Genomic Data



## ✨ What's New in This Fork

This is an **enhanced fork** of the original TeraPCA project with improved cross-platform support:

- 🔄 **Universal Architecture Support**: Makefile now supports both **x86** and **ARM Silicon** processors
- 🚀 **Simplified Installation**: Streamlined setup process for modern systems
- 🛠️ **Enhanced Compatibility**: Better compiler support and error handling

## 🔬 About TeraPCA

TeraPCA is a high-performance C++ software suite for Principal Component Analysis of large-scale genomic datasets. Built on Intel's MKL library, it combines the robustness of subspace iteration with the power of randomization for efficient computation.

### Key Features
- 🧵 **Multithreaded Processing**: Leverages Intel MKL for optimal performance
- 📊 **Memory Efficient**: Handles large datasets with configurable memory usage
- 🎯 **Randomized Algorithms**: Fast convergence with sketching techniques
- 📁 **Binary PED Support**: Direct processing of genomic file formats

## 🛠️ Installation

### Intel x86 Systems

1. **Install Intel oneAPI Toolkits**
```bash
# Add Intel repository
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

# Install toolkits
sudo apt update
sudo apt install intel-basekit intel-hpckit intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic
```

2. **Setup Environment**
```bash
# Check installation
ls /opt/intel/oneapi

# Set environment variables
source /opt/intel/oneapi/setvars.sh --force
```

3. **Compile TeraPCA**
```bash
# Navigate to TeraPCA directory
cd /path/to/TeraPCA

# Edit Makefile (set MKL_ROOT)
nano Makefile
# Set: MKL_ROOT = $(MKLROOT)

# Build
make clean
make
```

### ARM Silicon Systems

For ARM-based systems (Apple Silicon, etc.):

```bash
# Simply compile with default settings
make clean
make
```

## 🚀 Quick Start

### Basic Usage
```bash
./TeraPCA.exe -bfile example_mermigkis/ToyHapmap -nsv 5 -filewrite 1
```

### Validate Installation
```bash
# Compare outputs with provided example
cat example/ToyHapmap_singularValues.txt     # Reference output
cat noprefix_singularValues.txt              # Your output
```

## ⚙️ Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-bfile` | string | **required** | Input Binary PED file path |
| `-nsv` | int | 10 | Number of Principal Components |
| `-nrhs` | int | 2×nsv | RHS in sketching matrix |
| `-memory` | int | 2 | Memory usage (GB) |
| `-rfetched` | int | - | Exact number of rows to extract |
| `-power` | int | 1 | Power iterations for speed |
| `-filewrite` | bool | 0 | Write output files (1=yes) |
| `-print` | int | 1 | Verbosity level (2=detailed) |
| `-prefix` | string | input filename | Output filename prefix |

### Threading
```bash
# Set number of threads before execution
export OMP_NUM_THREADS=8
./TeraPCA.exe -bfile your_data -nsv 10
```

## 📁 Output Files

When `-filewrite 1` is set:
- `prefix_singularValues.txt` - Eigenvalues
- `prefix_singularVectors.txt` - Eigenvectors

## 📋 Example Dataset

Included in the `example` directory:
- 10 individuals, 50 SNPs from HapMap dataset
- Reference outputs for validation

## 🤝 Contributors

**Original Authors:**
- Vassilis Kalantzis
- Aritra Bose  
- Eugenia Kontopoulou

**Fork Extensions:**
- Giorgos Mermigkis (`giwrgosmerm@gmail.com` | `up1084639@ac.upatras.gr`)

**Contact:** `kalan019@umn.edu` | `a.bose@ibm.com`

---

⭐ **Star this repository if TeraPCA helped your research!**