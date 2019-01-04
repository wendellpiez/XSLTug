#!/bin/bash

# SAXON=/mnt/c/Users/wap1/Downloads/Saxon/saxon.jar
SAXON=/home/wendell/Saxon/saxon9he.jar
TUGXSLT=XSLTug.xsl
ARGS="$*"
SAFEARGS=${ARGS//[ ]/&}
RUNTUG="java -jar $SAXON -xsl:$TUGXSLT -it:go wd=$(pwd) argstring=$SAFEARGS"

echo $RUNTUG
$RUNTUG
