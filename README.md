<!--
Copyright (c) 2015 YCSB contributors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You
may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License. See accompanying
LICENSE file.
-->

## Quick Start

This section describes how to run YCSB on Aerospike. 

### 1. Start Aerospike

### 2. Install Java and Maven

### 3. Set Up YCSB

Git clone YCSB and compile:

    git clone http://github.com/brianfrankcooper/YCSB.git
    cd YCSB
    mvn -pl com.yahoo.ycsb:aerospike-binding -am clean package

### 4. Provide Aerospike Connection Parameters

The following connection parameters are available.

  * `as.host` - The Aerospike cluster to connect to (default: `localhost`)
  * `as.port` - The port to connect to (default: `3000`)
  * `as.user` - The user to connect as (no default)
  * `as.password` - The password for the user (no default)
  * `as.timeout` - The transaction and connection timeout (in ms, default: `10000`)
  * `as.namespace` - The namespace to be used for the benchmark (default: `ycsb`)

Add them to the workload or set them with the shell command, as in:

    ./bin/ycsb load aerospike -s -P workloads/workloada -p as.timeout=5000 >outputLoad.txt

### 5. Load Data and Run Tests

Load the data:

    ./bin/ycsb load aerospike -s -P workloads/workloada >outputLoad.txt

Run the workload test:

    ./bin/ycsb run aerospike -s -P workloads/workloada >outputRun.txt


steps:
mkdir -p /opt/app/benchmark/aerospike/
sudo mkdir -p /opt/app/benchmark
pushd /opt/app/benchmark
git clone xxxx
cp ./compress /opt/app/benchmark/aerospike/

scp -r tcn@192.168.10.202:/home/tcn/driver/aerospike-server-community-4.5.2.2-el7.tgz .
tar -zvxf aerospike-server-community-4.5.2.2-el7.tgz
sudo ./asinstall
sudo rpm -ivh aerospike-tools-3.18.1-1.el7.x86_64.rpm
./bin/ycsb load aerospike -s -P workloads/workloada -p as.namespace=test
lspci -d cc5


yum install nvmetcli.noarch
sudo yum install nvme-cli.x86_64
