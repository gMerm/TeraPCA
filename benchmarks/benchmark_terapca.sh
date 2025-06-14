#!/bin/bash

# TeraPCA Performance Benchmark Script
# Usage: ./benchmark_terapca.sh [iterations] [output_file]

set -e

# Configuration
ITERATIONS=${1:-1000000}  # Default to 1M iterations if not specified
OUTPUT_FILE=${2:-"terapca_benchmark_results.txt"}
TERAPCA_CMD="../TeraPCA.exe -bfile ../example/ToyHapmap -nsv 5 -filewrite 1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get system information
get_system_info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Architecture: $(uname -m)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "CPU Info:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sysctl -n machdep.cpu.brand_string
        echo "CPU Cores: $(sysctl -n hw.ncpu)"
        echo "Memory: $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')"
    else
        # Linux
        grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//'
        echo "CPU Cores: $(nproc)"
        echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    fi
    echo ""
}

# Function to check if TeraPCA is built and ready
check_terapca() {
    if [[ ! -f "../TeraPCA.exe" ]]; then
        print_error "TeraPCA.exe not found. Please build it first with 'make'."
        exit 1
    fi
    
    if [[ ! -d "../example" ]] || [[ ! -f "../example/ToyHapmap.bed" ]]; then
        print_warning "Example data not found. Make sure example/ToyHapmap.* files exist."
    fi
    
    # Test run to ensure it works
    print_status "Testing TeraPCA execution..."
    if ! $TERAPCA_CMD > /dev/null 2>&1; then
        print_error "TeraPCA test run failed. Please check your setup."
        exit 1
    fi
    print_success "TeraPCA test run successful."
}

# Function to run benchmark
run_benchmark() {
    local iterations=$1
    local output_file=$2
    
    print_status "Starting benchmark with $iterations iterations..."
    print_status "Command: $TERAPCA_CMD"
    print_status "Results will be saved to: $output_file"
    
    # Initialize results file
    {
        echo "# TeraPCA Benchmark Results"
        echo "# Generated on: $(date)"
        echo "# Iterations: $iterations"
        echo "# Command: $TERAPCA_CMD"
        echo "#"
        get_system_info
        echo "=== Benchmark Results ==="
        echo "Run#,Execution_Time(seconds),Status"
    } > "$output_file"
    
    local total_time=0
    local successful_runs=0
    local failed_runs=0
    local min_time=999999
    local max_time=0
    
    # Progress tracking
    local progress_interval=$((iterations / 100))  # Update every 1%
    if [[ $progress_interval -eq 0 ]]; then
        progress_interval=1
    fi
    
    for ((i=1; i<=iterations; i++)); do
        # Show progress
        if [[ $((i % progress_interval)) -eq 0 ]] || [[ $i -eq 1 ]]; then
            local percent=$((i * 100 / iterations))
            print_status "Progress: $percent% ($i/$iterations runs completed)"
        fi
        
        # Clean up any previous output files to ensure fresh run
        rm -f output_* *.eigenval *.eigenvec 2>/dev/null || true
        
        # Time the execution
        local start_time=$(date +%s.%N)
        if $TERAPCA_CMD > /dev/null 2>&1; then
            local end_time=$(date +%s.%N)
            local execution_time=$(echo "$end_time - $start_time" | bc -l)
            
            # Update statistics
            total_time=$(echo "$total_time + $execution_time" | bc -l)
            successful_runs=$((successful_runs + 1))
            
            # Track min/max times
            if (( $(echo "$execution_time < $min_time" | bc -l) )); then
                min_time=$execution_time
            fi
            if (( $(echo "$execution_time > $max_time" | bc -l) )); then
                max_time=$execution_time
            fi
            
            echo "$i,$execution_time,SUCCESS" >> "$output_file"
        else
            failed_runs=$((failed_runs + 1))
            echo "$i,N/A,FAILED" >> "$output_file"
        fi
        
        # Clean up output files after each run
        rm -f output_* *.eigenval *.eigenvec 2>/dev/null || true
    done
    
    # Calculate final statistics
    local avg_time=0
    if [[ $successful_runs -gt 0 ]]; then
        avg_time=$(echo "scale=6; $total_time / $successful_runs" | bc -l)
    fi
    
    # Append summary to results file
    {
        echo ""
        echo "=== Summary Statistics ==="
        echo "Total runs: $iterations"
        echo "Successful runs: $successful_runs"
        echo "Failed runs: $failed_runs"
        echo "Success rate: $(echo "scale=2; $successful_runs * 100 / $iterations" | bc -l)%"
        echo "Total execution time: ${total_time}s"
        echo "Average execution time: ${avg_time}s"
        echo "Minimum execution time: ${min_time}s"
        echo "Maximum execution time: ${max_time}s"
        echo "Throughput: $(echo "scale=2; $successful_runs / $total_time" | bc -l) runs/second"
    } >> "$output_file"
    
    # Display summary
    print_success "Benchmark completed!"
    echo ""
    echo "=== Final Results ==="
    echo "Total runs: $iterations"
    echo "Successful runs: $successful_runs"
    echo "Failed runs: $failed_runs"
    echo "Average execution time: ${avg_time}s"
    echo "Min time: ${min_time}s"
    echo "Max time: ${max_time}s"
    echo "Total time: ${total_time}s"
    echo ""
    print_success "Detailed results saved to: $output_file"
}

# Function to analyze results
analyze_results() {
    local output_file=$1
    
    if [[ ! -f "$output_file" ]]; then
        print_error "Results file not found: $output_file"
        return 1
    fi
    
    print_status "Analyzing results from $output_file..."
    
    # Extract execution times and calculate percentiles
    local temp_times="/tmp/terapca_times.txt"
    grep "SUCCESS" "$output_file" | cut -d',' -f2 | sort -n > "$temp_times"
    
    local count=$(wc -l < "$temp_times")
    if [[ $count -eq 0 ]]; then
        print_error "No successful runs found in results file."
        return 1
    fi
    
    # Calculate percentiles
    local p50_line=$((count / 2))
    local p90_line=$((count * 90 / 100))
    local p95_line=$((count * 95 / 100))
    local p99_line=$((count * 99 / 100))
    
    local p50=$(sed -n "${p50_line}p" "$temp_times")
    local p90=$(sed -n "${p90_line}p" "$temp_times")
    local p95=$(sed -n "${p95_line}p" "$temp_times")
    local p99=$(sed -n "${p99_line}p" "$temp_times")
    
    echo ""
    echo "=== Performance Percentiles ==="
    echo "50th percentile (median): ${p50}s"
    echo "90th percentile: ${p90}s"
    echo "95th percentile: ${p95}s"
    echo "99th percentile: ${p99}s"
    
    # Clean up
    rm -f "$temp_times"
}

# Main execution
main() {
    echo "=== TeraPCA Performance Benchmark ==="
    echo ""
    
    # Check dependencies
    if ! command -v bc &> /dev/null; then
        print_error "bc (basic calculator) is required but not installed."
        exit 1
    fi
    
    get_system_info
    check_terapca
    
    print_status "Starting benchmark with $ITERATIONS iterations..."
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    run_benchmark "$ITERATIONS" "$OUTPUT_FILE"
    analyze_results "$OUTPUT_FILE"
    
    print_success "Benchmark complete! Results saved to $OUTPUT_FILE"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [iterations] [output_file]"
        echo ""
        echo "Arguments:"
        echo "  iterations   Number of test iterations (default: 1000000)"
        echo "  output_file  Output file for results (default: terapca_benchmark_results.txt)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run 1M iterations with default output file"
        echo "  $0 100000             # Run 100K iterations"
        echo "  $0 50000 my_results.txt  # Run 50K iterations, save to my_results.txt"
        exit 0
        ;;
    *)
        main
        ;;
esac