# Slimmed Vs not


## When using the full schema - ie basically all the XML

```sh
Operating System: macOS
CPU Information: Apple M1 Max
Number of Available Cores: 10
Available memory: 64 GB
Elixir 1.13.4
Erlang 24.0.6

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 5 s
reduction time: 5 s
parallel: 5
inputs: none specified
Estimated total run time: 34 s

Benchmarking Slimmed down simpleform ...
Benchmarking normal simpleform ...

Name                              ips        average  deviation         median         99th %
Slimmed down simpleform          1.65      606.16 ms     ±1.01%      605.97 ms      617.05 ms
normal simpleform                1.56      640.25 ms     ±1.51%      642.53 ms      656.15 ms

Comparison:
Slimmed down simpleform          1.65
normal simpleform                1.56 - 1.06x slower +34.08 ms

Memory usage statistics:

Name                       Memory usage
Slimmed down simpleform       250.81 MB
normal simpleform             259.65 MB - 1.04x memory usage +8.84 MB

**All measurements for memory usage were the same**

Reduction count statistics:

Name                            average  deviation         median         99th %
Slimmed down simpleform         27.29 M     ±0.03%        27.29 M        27.31 M
normal simpleform               27.89 M     ±0.06%        27.89 M        27.94 M

Comparison:
Slimmed down simpleform         27.29 M
normal simpleform               27.89 M - 1.02x reduction count +0.60 M
```


## When using a small subset of the xml

Here we skipped like loads of bits:

```sh

Benchmarking Slimmed down simpleform ...
Benchmarking normal simpleform ...

Name                              ips        average  deviation         median         99th %
Slimmed down simpleform          4.58      218.45 ms     ±2.73%      215.90 ms      229.49 ms
normal simpleform                2.52      396.57 ms     ±2.39%      396.85 ms      420.64 ms

Comparison:
Slimmed down simpleform          4.58
normal simpleform                2.52 - 1.82x slower +178.12 ms

Memory usage statistics:

Name                            average  deviation         median         99th %
Slimmed down simpleform        85.60 MB     ±0.00%       85.60 MB       85.60 MB
normal simpleform             171.28 MB     ±0.00%      171.28 MB      171.28 MB

Comparison:
Slimmed down simpleform        85.60 MB
normal simpleform             171.28 MB - 2.00x memory usage +85.69 MB

Reduction count statistics:

Name                            average  deviation         median         99th %
Slimmed down simpleform         14.79 M     ±0.00%        14.79 M        14.79 M
normal simpleform               15.25 M     ±0.07%        15.25 M        15.27 M

Comparison:
Slimmed down simpleform         14.79 M
normal simpleform               15.25 M - 1.03x reduction count +0.46 M
```

### Skipping even more

We only parse response sid and warnings:

```sh

Name                              ips        average  deviation         median         99th %
Slimmed down simpleform          4.74      210.76 ms     ±0.72%      211.12 ms      213.63 ms
normal simpleform                2.52      397.50 ms     ±2.01%      396.63 ms      412.78 ms

Comparison:
Slimmed down simpleform          4.74
normal simpleform                2.52 - 1.89x slower +186.74 ms

Memory usage statistics:

Name                            average  deviation         median         99th %
Slimmed down simpleform        85.40 MB     ±0.00%       85.40 MB       85.40 MB
normal simpleform             171.20 MB     ±0.00%      171.20 MB      171.20 MB

Comparison:
Slimmed down simpleform        85.40 MB
normal simpleform             171.20 MB - 2.00x memory usage +85.80 MB

Reduction count statistics:

Name                            average  deviation         median         99th %
Slimmed down simpleform         14.78 M     ±0.00%        14.78 M        14.78 M
normal simpleform               15.24 M     ±0.07%        15.24 M        15.26 M

Comparison:
Slimmed down simpleform         14.78 M
normal simpleform               15.24 M - 1.03x reduction count +0.46 M
```
