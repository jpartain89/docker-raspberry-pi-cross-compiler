#!/bin/bash

: ${RPXC_IMAGE:=jpartain89/raspberry-pi-cross-compiler}

docker build -t $RPXC_IMAGE .
