<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="#all"
    version="3.0"
    xmlns:t="http://github.com/wendellpiez/XSLTug"
    expand-text="true"
    xmlns="http://www.w3.org/1999/xhtml">
    
<!--  Reports some basic facts about an XML document.
    Results are emitted in HTML, to be passed to a markdown serializer. -->
    
    <xsl:template match="/">
        <html>
            <head>
                <title>XSLTug Document Synopsis: { document-uri(/) }</title>
            </head>
            <body>
                <h1>XSLTug Document Synopsis: { document-uri(/) }</h1>
               <xsl:call-template name="synopsis"/> 
            </body>
        </html>
    </xsl:template>
    
    <xsl:template name="synopsis">
        <ul>
            <li>The document is parsed from { document-uri(/) }</li>
            <li>It contains { t:element-count(//*) }</li>
            <li>The document element is '{ name(/*) }'{ if (matches(namespace-uri(/*),'\S')) then
                (' in namespace ''' ||  namespace-uri(/*) || '''' )
                else '' }</li>
        </ul>
        
    </xsl:template>
    
    <xsl:function name="t:element-count" as="xs:string">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:value-of select="count($nodes) || (if (count($nodes) eq 1) then ' element' else ' elements')"/>
    </xsl:function>
    
        
</xsl:stylesheet>