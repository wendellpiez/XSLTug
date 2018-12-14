<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0"
    expand-text="true">
    
    <xsl:output indent="yes"/>
    
<!-- $argstring is all command-line arguments together
     spliced with \s or '&' -->
    <xsl:param name="argstring" as="xs:string"/>
    
<!-- All args tokenizes around spaces and punctuation -->
    <xsl:variable name="all-args" select="tokenize($argstring,'(&amp;|\s)+')"/>
    
<!-- $wd is the home (working) directory -->
    <xsl:param name="wd"    as="xs:string"/>
    
<!-- $dir converts wd into a URI; note trailing slash   -->
    <xsl:variable name="dir">
        <xsl:text>file:/</xsl:text>
        <xsl:for-each select="tokenize($wd,'/|\\')">
            <xsl:value-of select="replace(.,':$','') ! encode-for-uri(.)"/>
            <xsl:if test="ends-with(.,':')">:</xsl:if>
            <xsl:text>/</xsl:text>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="argtree">
        <xsl:call-template name="build-arg-tree">
            <xsl:with-param name="args" select="$all-args"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:template name="build-arg-tree">
        <xsl:param name="args" as="xs:string*"/>
        <xsl:if test="exists($args)">
            <arg v="{$args[1]}">
                <xsl:call-template name="build-arg-tree">
                    <xsl:with-param name="args" select="remove($args,1)"/>
                </xsl:call-template>
            </arg>
        </xsl:if>
    </xsl:template>

    <xsl:template name="go">
        <result>
            <where>{ $dir }</where>
        <xsl:copy-of select="$argtree"/>
        </result>
        
    </xsl:template>
    
</xsl:stylesheet>