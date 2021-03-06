## Introduction of the Open-Source EDA ASIC Design Flow

Here is the guideline for environment setup<br>

The following guidelines are for Ubuntu 20.04 LTS <br>

The implementation of the system should following some simple instructions according to the guidelines.<br>

OpenEDA Ubuntu 20.04 (LTS) Installation<br>

Required tools:<br>
- Yosys + ABC (synthesis)<br>
- OpenROAD (APR)<br>
- Klayout (DRC + Extract)<br>
- Netgen (LVS)<br>

<br><br>

======== Installation Guide ========<br>

Required basic packages:<br>
```
$ sudo apt install build-essential git python3
```

<br>

### Yosys+ABC<br>
```
$ sudo apt install bison flex \
libreadline-dev gawk tcl-dev libffi-dev git \
graphviz xdot pkg-config python3 libboost-system-dev \
libboost-python-dev libboost-filesystem-dev zlib1g-dev
$ git clone https://github.com/cliffordwolf/yosys.git
$ make config-gcc
$ make
$ sudo make install
```

<br>

### OpenROAD <br>
```
$ sudo apt install cmake bison flex swig \
libboost-dev tcl-dev libspdlog-dev zlib1g-dev \
libboost-test-dev libeigen3-dev qt5-default cimg-dev
```
> ##### Lemon 1.3.1 (not on ubuntu 20.04)<br>
> <sub>Download: Lemon 1.3.1 https://lemon.cs.elte.hu/trac/lemon/wiki/Downloads<br>
or <br></sub>
```
$ wget http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.tar.gz
```
> <sub>then install Lemon</sub>
```
$ tar xvf lemon-1.3.1.tar.gz
$ cd lemon-x.y.z
$ mkdir build
$ cd build
$ cmake ..
$ make
$ sudo make install
```

> <sub>then install OpenROAD</sub>
```
$ git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
$ cd OpenROAD
$ mkdir build
$ cd build
$ cmake ..
$ make
$ sudo make install
```

<br>

### Klayout<br>
```
$ sudo apt install python3 python3-dev \ 
zlib1g-dev qt5-default qtmultimedia5-dev \
qttools5-dev libqt5xmlpatterns5-dev libqt5svg5-dev \
ruby ruby-dev
```
Download: klayout ubuntu https://www.klayout.de/build.html<br>
or <br>
```
$ wget https://www.klayout.org/downloads/Ubuntu-20/klayout_0.26.11-1_amd64.deb
```
> <sub>then install Klayout</sub>
```
$ sudo apt install ./klayout_0.26.10-1_amd64.deb
```

<br>

### Netgen<br>
```
$ git clone https://github.com/RTimothyEdwards/netgen
$ ./configure
$ make
$ sudo make install
```











