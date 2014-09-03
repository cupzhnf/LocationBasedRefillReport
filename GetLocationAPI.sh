#!/bin/bash

WORKING_DIR=/home/notroot/crs_script/
MTV=$($WORKING_DIR/ctrai.exp $1 | grep MTV | awk '{print $2}' | awk -F"-" '{print $2}')
LACHEX=$($WORKING_DIR/mtvststest.exp $MTV | grep = | awk -F"'" '{print $4}' | tail -1)

echo "ibase=16; $LACHEX" | tr -d $'\r' | bc
