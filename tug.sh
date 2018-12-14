#!/bin/bash

SAXON=/mnt/c/Users/wap1/Downloads/Saxon/saxon.jar
TUGXSLT=XSLTtug.xsl
ARGS="$*"
SAFEARGS=${ARGS//[ ]/&}
RUNTUG="java -jar $SAXON -xsl:$TUGXSLT -it:go wd=$(pwd) argstring=$SAFEARGS"

echo $RUNTUG
$RUNTUG