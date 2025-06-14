"""
TeraPCA Benchmark Results Analyzer
Compares performance results between different architectures
"""

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import sys

def parse_benchmark_file(filepath):
    """Parse a TeraPCA benchmark results file."""
    results = {
        'system_info': {},
        'data': None,
        'summary': {}
    }
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Parse system information
    in_system_section = False
    in_data_section = False
    in_summary_section = False
    
    data_lines = []
    
    for line in lines:
        line = line.strip()
        
        if line.startswith('=== System Information ==='):
            in_system_section = True
            continue
        elif line.startswith('=== Benchmark Results ==='):
            in_system_section = False
            in_data_section = True
            continue
        elif line.startswith('=== Summary Statistics ==='):
            in_data_section = False
            in_summary_section = True
            continue
        
        if in_system_section and ':' in line:
            key, value = line.split(':', 1)
            results['system_info'][key.strip()] = value.strip()
        elif in_data_section and not line.startswith('#') and ',' in line:
            if line.startswith('Run#'):
                continue  # Skip header
            data_lines.append(line)
        elif in_summary_section and ':' in line:
            key, value = line.split(':', 1)
            results['summary'][key.strip()] = value.strip()
    
    # Parse data into DataFrame
    if data_lines:
        data = []
        for line in data_lines:
            parts = line.split(',')
            if len(parts) >= 3:
                run_num = int(parts[0])
                exec_time = float(parts[1]) if parts[1] != 'N/A' else None
                status = parts[2]
                data.append({'run': run_num, 'time': exec_time, 'status': status})
        
        results['data'] = pd.DataFrame(data)
    
    return results

def analyze_single_result(results, label=""):
    """Analyze results from a single benchmark run."""
    if results['data'] is None:
        print(f"No data found for {label}")
        return None
    
    # Filter successful runs
    successful = results['data'][results['data']['status'] == 'SUCCESS']
    times = successful['time'].dropna()
    
    if len(times) == 0:
        print(f"No successful runs found for {label}")
        return None
    
    stats = {
        'label': label,
        'architecture': results['system_info'].get('Architecture', 'Unknown'),
        'cpu': results['system_info'].get('CPU Info', 'Unknown'),
        'total_runs': len(results['data']),
        'successful_runs': len(successful),
        'success_rate': len(successful) / len(results['data']) * 100,
        'mean_time': times.mean(),
        'median_time': times.median(),
        'std_time': times.std(),
        'min_time': times.min(),
        'max_time': times.max(),
        'p90_time': times.quantile(0.9),
        'p95_time': times.quantile(0.95),
        'p99_time': times.quantile(0.99),
        'throughput': len(successful) / times.sum()  # runs per second
    }
    
    return stats, times

def compare_results(results_list, labels):
    """Compare multiple benchmark results."""
    all_stats = []
    all_times = {}
    
    print("=== Performance Comparison ===\n")
    
    for i, (results, label) in enumerate(zip(results_list, labels)):
        stats, times = analyze_single_result(results, label)
        if stats:
            all_stats.append(stats)
            all_times[label] = times
            
            print(f"Results for {label}:")
            print(f"  Architecture: {stats['architecture']}")
            print(f"  CPU: {stats['cpu']}")
            print(f"  Successful runs: {stats['successful_runs']:,} / {stats['total_runs']:,} ({stats['success_rate']:.1f}%)")
            print(f"  Mean execution time: {stats['mean_time']:.4f}s")
            print(f"  Median execution time: {stats['median_time']:.4f}s")
            print(f"  Standard deviation: {stats['std_time']:.4f}s")
            print(f"  Min time: {stats['min_time']:.4f}s")
            print(f"  Max time: {stats['max_time']:.4f}s")
            print(f"  90th percentile: {stats['p90_time']:.4f}s")
            print(f"  95th percentile: {stats['p95_time']:.4f}s")
            print(f"  99th percentile: {stats['p99_time']:.4f}s")
            print(f"  Throughput: {stats['throughput']:.2f} runs/second")
            print()
    
    if len(all_stats) >= 2:
        # Compare the first two results
        stats1, stats2 = all_stats[0], all_stats[1]
        
        print("=== Head-to-Head Comparison ===")
        print(f"Comparing {stats1['label']} vs {stats2['label']}:")
        
        speedup = stats2['mean_time'] / stats1['mean_time']
        if speedup > 1:
            print(f"  {stats1['label']} is {speedup:.2f}x faster on average")
        else:
            print(f"  {stats2['label']} is {1/speedup:.2f}x faster on average")
        
        throughput_ratio = stats1['throughput'] / stats2['throughput']
        print(f"  Throughput ratio: {throughput_ratio:.2f}:1")
        
        # Statistical significance test (simple t-test)
        from scipy import stats as scipy_stats
        times1 = all_times[stats1['label']]
        times2 = all_times[stats2['label']]
        
        # Sample if datasets are too large
        sample_size = min(10000, len(times1), len(times2))
        if len(times1) > sample_size:
            times1 = times1.sample(sample_size)
        if len(times2) > sample_size:
            times2 = times2.sample(sample_size)
        
        t_stat, p_value = scipy_stats.ttest_ind(times1, times2)
        print(f"  T-test p-value: {p_value:.2e}")
        if p_value < 0.001:
            print("  *** Difference is statistically significant (p < 0.001)")
        elif p_value < 0.05:
            print("  ** Difference is statistically significant (p < 0.05)")
        else:
            print("  Difference is not statistically significant")
        print()
    
    return all_stats, all_times

def create_visualizations(all_stats, all_times, output_dir="plots"):
    """Create visualization plots."""
    Path(output_dir).mkdir(exist_ok=True)
    
    if not all_times:
        print("No data available for plotting")
        return
    
    # Set style
    plt.style.use('seaborn-v0_8')
    
    # 1. Box plot comparison
    plt.figure(figsize=(12, 8))
    data_for_box = []
    labels_for_box = []
    
    for label, times in all_times.items():
        # Sample data if too large for plotting
        sample_times = times.sample(min(10000, len(times))) if len(times) > 10000 else times
        data_for_box.append(sample_times)
        labels_for_box.append(label)
    
    plt.boxplot(data_for_box, labels=labels_for_box)
    plt.title('Execution Time Distribution Comparison')
    plt.ylabel('Execution Time (seconds)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/execution_time_boxplot.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 2. Histogram comparison
    plt.figure(figsize=(12, 8))
    for label, times in all_times.items():
        sample_times = times.sample(min(10000, len(times))) if len(times) > 10000 else times
        plt.hist(sample_times, bins=50, alpha=0.7, label=label, density=True)
    
    plt.title('Execution Time Distribution')
    plt.xlabel('Execution Time (seconds)')
    plt.ylabel('Density')
    plt.legend()
    plt.tight_layout()
    plt.savefig(f'{output_dir}/execution_time_histogram.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 3. Performance metrics comparison
    if len(all_stats) >= 2:
        metrics = ['mean_time', 'median_time', 'p90_time', 'p95_time', 'p99_time']
        metric_labels = ['Mean', 'Median', '90th %ile', '95th %ile', '99th %ile']
        
        fig, ax = plt.subplots(figsize=(12, 8))
        x = np.arange(len(metrics))
        width = 0.35
        
        for i, stats in enumerate(all_stats[:2]):  # Compare first two
            values = [stats[metric] for metric in metrics]
            ax.bar(x + i*width, values, width, label=stats['label'])
        
        ax.set_xlabel('Metrics')
        ax.set_ylabel('Time (seconds)')
        ax.set_title('Performance Metrics Comparison')
        ax.set_xticks(x + width/2)
        ax.set_xticklabels(metric_labels)
        ax.legend()
        plt.tight_layout()
        plt.savefig(f'{output_dir}/performance_metrics.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    print(f"Plots saved to {output_dir}/ directory")

def main():
    parser = argparse.ArgumentParser(description='Analyze TeraPCA benchmark results')
    parser.add_argument('files', nargs='+', help='Benchmark result files to analyze')
    parser.add_argument('--labels', nargs='*', help='Labels for each file (optional)')
    parser.add_argument('--output-dir', default='plots', help='Directory for output plots')
    parser.add_argument('--no-plots', action='store_true', help='Skip generating plots')
    
    args = parser.parse_args()
    
    # Check if scipy is available for statistical tests
    try:
        import scipy.stats
    except ImportError:
        print("Warning: scipy not available. Statistical significance tests will be skipped.")
    
    # Load results
    results_list = []
    labels = args.labels if args.labels else [f"Run {i+1}" for i in range(len(args.files))]
    
    if len(labels) != len(args.files):
        print("Error: Number of labels must match number of files")
        sys.exit(1)
    
    for filepath in args.files:
        if not Path(filepath).exists():
            print(f"Error: File not found: {filepath}")
            sys.exit(1)
        
        try:
            results = parse_benchmark_file(filepath)
            results_list.append(results)
        except Exception as e:
            print(f"Error parsing {filepath}: {e}")
            sys.exit(1)
    
    # Analyze and compare
    all_stats, all_times = compare_results(results_list, labels)
    
    # Create visualizations
    if not args.no_plots and all_times:
        try:
            create_visualizations(all_stats, all_times, args.output_dir)
        except Exception as e:
            print(f"Error creating plots: {e}")
    
    print("Analysis complete!")

if __name__ == "__main__":
    main()