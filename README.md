# Instance Variable Table Benchmark for mruby

## Current report

[Current report](https://shuujii.github.io/mruby-iv-benchmark) is as of the time of [*Reduce memory usage of instance variable table (#5317)*](https://github.com/mruby/mruby/pull/5317) pull request to mruby.

## How to execute benchmark

### Install

```console
$ git clone https://github.com/shuujii/mruby-iv-benchmark
```

### Download mruby and build benchmarker

```console
$ rake
```

### Execute benchmark

```console
$ rake benchmark
```

### Create benchmark report

```console
$ rake report
```

### View benchmark report

```console
$ rake server
```

And, open with browser [http://localhost:8080/mruby-iv-benchmark](http://localhost:8080/mruby-iv-benchmark)
