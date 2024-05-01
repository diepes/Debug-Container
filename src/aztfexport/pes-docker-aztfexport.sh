#!/usr/bin/env bash


docker run -it  -v $PWD:/root/tf:ro -v $PWD/aztf_out:/root/tf/aztf_out diepes/debug
