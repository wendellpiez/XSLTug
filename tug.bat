echo off

set SAXON=C:\Users\wap1\Downloads\Saxon\saxon.jar

set TUGXSLT=XSLTug.xsl

set RUNTUG=java -jar %SAXON% -xsl:%TUGXSLT% -it:go wd="%cd%" argstring="%*"

echo %RUNTUG%
echo.
%RUNTUG%