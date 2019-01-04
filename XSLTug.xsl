<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns="http://github.com/wendellpiez/XSLTug"
    xpath-default-namespace="http://github.com/wendellpiez/XSLTug"
    version="3.0">
    
    <xsl:output indent="yes" omit-xml-declaration="yes"/>
    <!--<xsl:output method="text"/>-->
    
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

    <xsl:variable name="request">
        <result>
            <processor>
                <xsl:value-of select="system-property('xsl:product-name')"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="system-property('xsl:product-version')"/>
                <xsl:text> from </xsl:text>
                <xsl:value-of select="system-property('xsl:vendor')"/>
            </processor>
            
            <where>
                <xsl:value-of select="$dir"/>
            </where>
            <xsl:copy-of select="$argtree"/>
        </result>
        
    </xsl:variable>
    
    <xsl:template name="go">
        <xsl:if test="empty($argtree/*)">
          <xsl:copy-of select="$request"/>
        </xsl:if>
        <xsl:apply-templates select="$argtree"/>
    </xsl:template>
    
    <!-- expecting to match an $argtree root -->
    <xsl:template match="/">
        <xsl:apply-templates/>
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>
    
    <xsl:template match="/arg[@v=('-h','--help')]">
        <xsl:text> XSLTug running in </xsl:text>
        <xsl:value-of select="$request/*/processor"/>
    </xsl:template>
    
    <xsl:template match="/arg[@v='Demo']">
        <xsl:apply-templates select="$dummy-sequence/sequence">
            <xsl:with-param name="source" select="$dummy-sequence"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
    <xsl:template match="/arg[@v='XSweet']">
        <!-- for now, supporting only this pathway -->
        <xsl:apply-templates select="arg[@v='html']/*/arg[@v='from']"/>
    </xsl:template>
    
    <xsl:template match="/arg[@v='XSweet']/arg[@v='html']/*/arg[@v='from']">
        <xsl:variable name="nominal-source" select="child::arg[@v castable as xs:anyURI]/string(@v)"/>
        <xsl:variable name="nominal-target" select="parent::arg[@v castable as xs:anyURI]/string(@v)"/>
        <xsl:variable name="source-loc" select="resolve-uri($nominal-source,$dir)"/>
        <xsl:variable name="target-loc" select="resolve-uri($nominal-target,$dir)"/>
        
        <xsl:text> Producing </xsl:text>
        <xsl:value-of select="$nominal-target"/>
        <xsl:text> from </xsl:text>
        <xsl:value-of select="$source-loc"/>
        
        <!--<xsl:apply-templates select="$xsweet-sequence/sequence">
            <xsl:with-param name="source" select="$source-doc"/>
        </xsl:apply-templates>-->
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:text> ... </xsl:text>
        <xsl:value-of select="@*"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:variable name="dummy-sequence">
        <sequence>
            <transform>transform-1.xsl</transform>
            <transform>transform-2.xsl</transform>
        </sequence>
    </xsl:variable>
    
    <xsl:variable name="xsweet-sequence">
        <sequence>
            <transform>docx-html-extract.xsl</transform>
            <transform>handle-notes.xsl</transform>
            <transform>scrub.xsl</transform>
            <transform>join-elements.xsl</transform>
            <transform>collapse-paragraphs.xsl</transform>
        </sequence>
    </xsl:variable> 
    
    <xsl:template match="sequence[transform]">
        <xsl:param name="source" as="document-node()" required="true"/>
        <xsl:iterate select="*">
            <xsl:param name="sourcedoc" select="$source" as="document-node()"/>
            <xsl:on-completion select="$sourcedoc"/>
            <xsl:next-iteration>
                <xsl:with-param name="sourcedoc">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="sourcedoc" select="$sourcedoc"/>
                    </xsl:apply-templates>
                </xsl:with-param>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:template>
    
    <xsl:template match="transform">
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:variable name="xslt-spec" select="."/>
        <xsl:variable name="runtime"
            select="map { 'xslt-version': if (empty($xslt-spec/@version)) then 2.0 else xs:decimal($xslt-spec/@version),
            'stylesheet-location': string($xslt-spec),
            'source-node': $sourcedoc
            }"/>
        <!-- The function returns a map; primary results are under 'output'          unless a base output URI is given          https://www.w3.org/TR/xpath-functions-31/#func-transform -->
        <xsl:sequence select="transform($runtime)?output"/>
    </xsl:template>
    <!-- Not knowing any better, we simply pass along. -->

    <xsl:template match="sequence/*" priority="-0.1">
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:sequence select="$sourcedoc"/>
    </xsl:template>
</xsl:stylesheet>