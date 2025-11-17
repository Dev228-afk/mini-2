#!/usr/bin/env python3
"""
Performance Visualization Generator
Creates graphs for "Something Cool" presentation
"""

import matplotlib.pyplot as plt
import numpy as np
import sys
from datetime import datetime

def create_caching_comparison():
    """Show cold vs warm cache performance"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Cold vs Warm comparison
    categories = ['Cold Start', 'Warm Cache']
    times = [1450, 580]  # ms - example values from your tests
    colors = ['#FF6B6B', '#51CF66']
    
    bars = ax1.bar(categories, times, color=colors, alpha=0.7, edgecolor='black', linewidth=2)
    ax1.set_ylabel('Time to First Chunk (ms)', fontsize=12, fontweight='bold')
    ax1.set_title('Caching Impact - 100K Dataset', fontsize=14, fontweight='bold')
    ax1.set_ylim(0, 1600)
    ax1.grid(axis='y', alpha=0.3)
    
    # Add value labels on bars
    for bar, time in zip(bars, times):
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'{time} ms',
                ha='center', va='bottom', fontweight='bold', fontsize=11)
    
    # Speedup annotation
    speedup = times[0] / times[1]
    ax1.text(0.5, 1200, f'{speedup:.1f}x\nFaster!', 
             ha='center', fontsize=16, fontweight='bold',
             bbox=dict(boxstyle='round', facecolor='yellow', alpha=0.5))
    
    # Speedup percentage
    categories2 = ['Dataset\nLoading', 'Memory\nCached']
    percentages = [100, (times[1]/times[0])*100]
    
    bars2 = ax2.bar(categories2, percentages, color=['#FF6B6B', '#51CF66'], 
                    alpha=0.7, edgecolor='black', linewidth=2)
    ax2.set_ylabel('Relative Performance (%)', fontsize=12, fontweight='bold')
    ax2.set_title('Performance Improvement', fontsize=14, fontweight='bold')
    ax2.set_ylim(0, 120)
    ax2.axhline(y=100, color='gray', linestyle='--', alpha=0.5)
    ax2.grid(axis='y', alpha=0.3)
    
    # Add percentage labels
    for bar, pct in zip(bars2, percentages):
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height,
                f'{pct:.0f}%',
                ha='center', va='bottom', fontweight='bold', fontsize=11)
    
    plt.tight_layout()
    plt.savefig('results/caching_performance.png', dpi=300, bbox_inches='tight')
    print("✓ Created: results/caching_performance.png")
    plt.close()

def create_scalability_graph():
    """Show system scales with dataset size"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Dataset sizes
    datasets = ['1K\n(1MB)', '10K\n(1.2MB)', '100K\n(12MB)', '1M\n(122MB)']
    rows = [1000, 10000, 100000, 1000000]
    times = [496, 169, 1607, 13673]  # ms - example from your tests
    sizes_mb = [1.18, 1.17, 11.69, 116.89]
    
    # Time scaling
    color_gradient = ['#4ECDC4', '#44B3C2', '#3A9BA0', '#30837E']
    bars1 = ax1.bar(datasets, times, color=color_gradient, alpha=0.7, 
                    edgecolor='black', linewidth=2)
    ax1.set_ylabel('Total Processing Time (ms)', fontsize=12, fontweight='bold')
    ax1.set_xlabel('Dataset Size', fontsize=12, fontweight='bold')
    ax1.set_title('Scalability - Processing Time', fontsize=14, fontweight='bold')
    ax1.set_yscale('log')
    ax1.grid(axis='y', alpha=0.3, which='both')
    
    # Add value labels
    for bar, time in zip(bars1, times):
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'{time}ms',
                ha='center', va='bottom', fontweight='bold', fontsize=9)
    
    # Throughput
    throughput = [size / (time/1000) for size, time in zip(sizes_mb, times)]
    
    bars2 = ax2.bar(datasets, throughput, color=color_gradient, alpha=0.7,
                    edgecolor='black', linewidth=2)
    ax2.set_ylabel('Throughput (MB/s)', fontsize=12, fontweight='bold')
    ax2.set_xlabel('Dataset Size', fontsize=12, fontweight='bold')
    ax2.set_title('Consistent Throughput', fontsize=14, fontweight='bold')
    ax2.set_ylim(0, max(throughput) * 1.2)
    ax2.grid(axis='y', alpha=0.3)
    
    # Add throughput labels
    for bar, tp in zip(bars2, throughput):
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height,
                f'{tp:.1f}',
                ha='center', va='bottom', fontweight='bold', fontsize=9)
    
    # Average line
    avg_throughput = np.mean(throughput)
    ax2.axhline(y=avg_throughput, color='red', linestyle='--', linewidth=2, 
                label=f'Avg: {avg_throughput:.1f} MB/s')
    ax2.legend(fontsize=10)
    
    plt.tight_layout()
    plt.savefig('results/scalability_analysis.png', dpi=300, bbox_inches='tight')
    print("✓ Created: results/scalability_analysis.png")
    plt.close()

def create_distributed_architecture():
    """Visualize the distributed system architecture"""
    fig, ax = plt.subplots(figsize=(12, 8))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 10)
    ax.axis('off')
    
    # Title
    ax.text(5, 9.5, 'Distributed Processing Architecture', 
            ha='center', fontsize=18, fontweight='bold')
    
    # PC-1 Box
    pc1_box = plt.Rectangle((0.5, 5), 4, 3.5, 
                            linewidth=3, edgecolor='#3498DB', 
                            facecolor='#E8F4F8', alpha=0.3)
    ax.add_patch(pc1_box)
    ax.text(2.5, 8.2, 'PC-1 (169.254.239.138)', 
            ha='center', fontsize=12, fontweight='bold', color='#3498DB')
    
    # PC-2 Box
    pc2_box = plt.Rectangle((5.5, 5), 4, 3.5, 
                            linewidth=3, edgecolor='#E74C3C', 
                            facecolor='#FADBD8', alpha=0.3)
    ax.add_patch(pc2_box)
    ax.text(7.5, 8.2, 'PC-2 (169.254.206.255)', 
            ha='center', fontsize=12, fontweight='bold', color='#E74C3C')
    
    # Nodes - PC-1
    # Node A (Leader)
    circle_a = plt.Circle((2.5, 7.5), 0.4, color='#FFD700', ec='black', linewidth=2)
    ax.add_patch(circle_a)
    ax.text(2.5, 7.5, 'A\nLeader', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Node B (Team Leader)
    circle_b = plt.Circle((1.5, 6.2), 0.4, color='#51CF66', ec='black', linewidth=2)
    ax.add_patch(circle_b)
    ax.text(1.5, 6.2, 'B\nTeam', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Node D (Worker)
    circle_d = plt.Circle((3.5, 6.2), 0.4, color='#A8DADC', ec='black', linewidth=2)
    ax.add_patch(circle_d)
    ax.text(3.5, 6.2, 'D\nWork', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Nodes - PC-2
    # Node C (Worker)
    circle_c = plt.Circle((6.5, 7.5), 0.4, color='#A8DADC', ec='black', linewidth=2)
    ax.add_patch(circle_c)
    ax.text(6.5, 7.5, 'C\nWork', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Node E (Team Leader)
    circle_e = plt.Circle((7.5, 6.2), 0.4, color='#F48FB1', ec='black', linewidth=2)
    ax.add_patch(circle_e)
    ax.text(7.5, 6.2, 'E\nTeam', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Node F (Worker)
    circle_f = plt.Circle((8.5, 6.2), 0.4, color='#A8DADC', ec='black', linewidth=2)
    ax.add_patch(circle_f)
    ax.text(8.5, 6.2, 'F\nWork', ha='center', va='center', 
            fontweight='bold', fontsize=9)
    
    # Connections (arrows)
    # A -> B
    ax.annotate('', xy=(1.9, 6.5), xytext=(2.3, 7.2),
                arrowprops=dict(arrowstyle='->', lw=2, color='green'))
    
    # A -> E
    ax.annotate('', xy=(7.1, 6.4), xytext=(2.9, 7.3),
                arrowprops=dict(arrowstyle='->', lw=2, color='red'))
    
    # B -> C
    ax.annotate('', xy=(6.1, 7.4), xytext=(1.9, 6.3),
                arrowprops=dict(arrowstyle='->', lw=2, color='gray', linestyle='dashed'))
    
    # B -> D
    ax.annotate('', xy=(3.1, 6.3), xytext=(1.9, 6.2),
                arrowprops=dict(arrowstyle='->', lw=2, color='gray'))
    
    # E -> D
    ax.annotate('', xy=(3.9, 6.3), xytext=(7.1, 6.3),
                arrowprops=dict(arrowstyle='->', lw=2, color='gray', linestyle='dashed'))
    
    # E -> F
    ax.annotate('', xy=(8.1, 6.2), xytext=(7.9, 6.2),
                arrowprops=dict(arrowstyle='->', lw=2, color='gray'))
    
    # Client
    client_box = plt.Rectangle((4, 1.5), 2, 1.2, 
                               linewidth=2, edgecolor='black', 
                               facecolor='#95E1D3')
    ax.add_patch(client_box)
    ax.text(5, 2.1, 'Client', ha='center', fontsize=12, fontweight='bold')
    
    # Client -> A
    ax.annotate('', xy=(4.7, 7.1), xytext=(5, 2.7),
                arrowprops=dict(arrowstyle='<->', lw=3, color='purple'))
    ax.text(4.5, 4.5, 'gRPC\nRequests', ha='center', fontsize=9, 
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    # Legend
    ax.text(1, 4.2, 'Legend:', fontsize=11, fontweight='bold')
    ax.text(1, 3.8, '● Leader (A): Orchestrates requests', fontsize=9)
    ax.text(1, 3.5, '● Team Leaders (B, E): Coordinate workers', fontsize=9)
    ax.text(1, 3.2, '● Workers (C, D, F): Process data', fontsize=9)
    ax.text(1, 2.9, '→ Request flow', fontsize=9)
    ax.text(1, 2.6, '⇢ Cross-machine communication', fontsize=9)
    
    # Stats box
    stats_box = plt.Rectangle((6, 2), 3.5, 2.5, 
                              linewidth=2, edgecolor='black', 
                              facecolor='#FFF9C4', alpha=0.5)
    ax.add_patch(stats_box)
    ax.text(7.75, 4.2, 'Performance Stats', ha='center', 
            fontsize=11, fontweight='bold')
    ax.text(6.3, 3.8, '• 2 Computers', fontsize=9)
    ax.text(6.3, 3.5, '• 6 Nodes total', fontsize=9)
    ax.text(6.3, 3.2, '• ~2.5ms cross-machine RTT', fontsize=9)
    ax.text(6.3, 2.9, '• 3 workers in parallel', fontsize=9)
    ax.text(6.3, 2.6, '• 122 MB in 13 seconds', fontsize=9)
    ax.text(6.3, 2.3, '• ~9 MB/s throughput', fontsize=9)
    
    plt.tight_layout()
    plt.savefig('results/distributed_architecture.png', dpi=300, bbox_inches='tight')
    print("✓ Created: results/distributed_architecture.png")
    plt.close()

def create_memory_efficiency():
    """Show memory usage comparison"""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Memory usage scenarios
    scenarios = ['Traditional\n(All at Once)', 'Chunked\nStreaming\n(Ours)']
    memory_usage = [122, 40]  # MB - max memory needed
    colors = ['#FF6B6B', '#51CF66']
    
    bars = ax.bar(scenarios, memory_usage, color=colors, alpha=0.7,
                  edgecolor='black', linewidth=2, width=0.5)
    ax.set_ylabel('Peak Client Memory (MB)', fontsize=12, fontweight='bold')
    ax.set_title('Memory Efficiency - 1M Row Dataset', fontsize=14, fontweight='bold')
    ax.set_ylim(0, 140)
    ax.grid(axis='y', alpha=0.3)
    
    # Add value labels
    for bar, mem in zip(bars, memory_usage):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{mem} MB',
                ha='center', va='bottom', fontweight='bold', fontsize=12)
    
    # Savings annotation
    savings = ((memory_usage[0] - memory_usage[1]) / memory_usage[0]) * 100
    ax.text(0.5, 80, f'{savings:.0f}% Memory\nSavings!', 
            ha='center', fontsize=16, fontweight='bold',
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.7))
    
    # Add explanation
    ax.text(0.5, 10, '3 chunks × 40MB each\nrequire full allocation',
            ha='center', fontsize=9, style='italic')
    ax.text(1.5, 10, 'Process one chunk\nat a time',
            ha='center', fontsize=9, style='italic')
    
    plt.tight_layout()
    plt.savefig('results/memory_efficiency.png', dpi=300, bbox_inches='tight')
    print("✓ Created: results/memory_efficiency.png")
    plt.close()

def main():
    print("\n" + "="*60)
    print("🎨 Generating Performance Visualizations")
    print("="*60 + "\n")
    
    # Create results directory if it doesn't exist
    import os
    os.makedirs('results', exist_ok=True)
    
    # Generate all graphs
    create_caching_comparison()
    create_scalability_graph()
    create_distributed_architecture()
    create_memory_efficiency()
    
    print("\n" + "="*60)
    print("✅ All visualizations created in results/ directory")
    print("="*60)
    print("\nFiles created:")
    print("  • results/caching_performance.png")
    print("  • results/scalability_analysis.png")
    print("  • results/distributed_architecture.png")
    print("  • results/memory_efficiency.png")
    print("\nUse these in your presentation! 🚀\n")

if __name__ == "__main__":
    main()
