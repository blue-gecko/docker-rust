#!/bin/bash

dirname=${PWD##*/}

/usr/local/bin/docker run -e USER=$USER -it --security-opt seccomp=unconfined -v $PWD:/usr/src/rust --name=$dirname --hostname=$dirname --rm bluegecko/rust

