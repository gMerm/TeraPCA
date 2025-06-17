import os
import matplotlib.pyplot as plt

# OMP Threads
threads = [2, 4, 8, 10, 12]

# Execution times in seconds
terapca_intel = [176, 130, 114, 103, 95]
terapca_arm = [81, 70, 64, 64, 64]              # only up to 8 threads
flashpca2 = [104, 104, 104, 104, 104]           # only for 2 threads

# --------- Plot 1: TeraPCA Intel Speedup vs Threads ---------

# Ensure the plots directory exists
os.makedirs("plots", exist_ok=True)

speedup_intel = [terapca_intel[0] / t for t in terapca_intel]

plt.figure(figsize=(8, 5))
plt.plot(threads, speedup_intel, marker='o', color='green', label='TeraPCA Intel Speedup')
plt.title("TeraPCA Intel Speedup vs Threads")
plt.xlabel("OMP Threads")
plt.ylabel("Speedup")
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.savefig("plots/terapca_intel_speedup_vs_threads.png", dpi=300)
plt.show()

# --------- Plot 2: Execution Time vs Threads ---------
plt.figure(figsize=(10, 6))

# TeraPCA Intel
plt.plot(threads, terapca_intel, marker='o', color='green', label='TeraPCA Intel')

# TeraPCA ARM (only up to 8 threads)
plt.plot(threads, terapca_arm, marker='s', linestyle='--', color='red', label='TeraPCA ARM')

# FlashPCA2 (only at 2 threads)
plt.plot(threads, flashpca2, marker='^', linestyle='--', color='blue', label='FlashPCA2')

plt.title("Execution Time vs Threads")
plt.xlabel("OMP Threads")
plt.ylabel("Execution Time (seconds)")
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.savefig("plots/execution_time_vs_threads.png", dpi=300)
plt.show()

# --------- Plot 3: Speedup for ARM --------------------
speedup_arm = [terapca_arm[0] / t for t in terapca_arm]

plt.figure(figsize=(8, 5))
plt.plot(threads, speedup_intel, marker='o', color='green', label='TeraPCA Intel')
plt.plot(threads, speedup_arm, marker='s', linestyle='--', color='red', label='TeraPCA ARM')

plt.title("TeraPCA Speedup Comparison")
plt.xlabel("OMP Threads")
plt.ylabel("Speedup")
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.savefig("plots/terapca_speedup_comparison.png", dpi=300)
plt.show()