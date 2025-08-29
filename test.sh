#!/bin/bash
# Jellyfin Hardware Capability Test Script
# Run on each machine, then compare results

sudo apt install sysbench fio vainfo ffmpeg i965-va-driver-shaders

LOGFILE="jellyfin_benchmark_$(hostname)_$(date +%Y%m%d%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Jellyfin Benchmark on $(hostname) ==="
echo "Date: $(date)"
echo "----------------------------------------"

# 1. System info
echo -e "\n## System Info"
lscpu | grep -E "Model name|Architecture|CPU\(s\)"
free -h | grep Mem
lsblk -o NAME,SIZE,MODEL,TYPE | grep -E "disk|part"
lspci | grep -E "VGA|3D"

# 2. CPU Benchmark
echo -e "\n## CPU Benchmark (sysbench)"
sysbench cpu --cpu-max-prime=20000 run | grep "events per second"

# 3. Memory Benchmark
echo -e "\n## Memory Benchmark (sysbench)"
sysbench memory run | grep "transferred"

# 4. Disk Benchmark (fio)
echo -e "\n## Disk Benchmark (fio)"
fio --name=randread --ioengine=libaio --rw=randread --bs=4k --size=200M --numjobs=1 --runtime=20 --group_reporting | grep -E "IOPS|bw="

# 5. GPU Capabilities (vainfo)
echo -e "\n## GPU Capabilities (vainfo)"
vainfo || echo "vainfo not available (no VAAPI support?)"

# 6. FFmpeg software transcode test (CPU only)
echo -e "\n## FFmpeg CPU Transcode Test"
ffmpeg -y -loglevel info -i /usr/share/example-content/Ubuntu_Free_Culture_Showcase/*.ogv \
  -c:v libx264 -t 10 -f null - 2>&1 | grep -E "fps="

# 7. FFmpeg hardware transcode test (Intel VAAPI, if supported)
echo -e "\n## FFmpeg Hardware Transcode Test (VAAPI)"
ffmpeg -y -hwaccel vaapi -hwaccel_output_format vaapi \
  -i /usr/share/example-content/Ubuntu_Free_Culture_Showcase/*.ogv \
  -c:v h264_vaapi -t 10 -f null - 2>&1 | grep -E "fps="

echo -e "\n=== Benchmark Complete. Results saved to $LOGFILE ==="
