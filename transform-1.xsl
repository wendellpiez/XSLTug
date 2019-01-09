<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <!--<xsl:template match="/">
        <xsl:comment expand-text="true"> transformation 1 sees { if (count(//*)=1) then 'element' else 'elements' }</xsl:comment>
        <xsl:apply-templates/>
    </xsl:template>-->
    
    <xsl:template match="*[.='transform-1.xsl']">
        <xsl:copy copy-namespaces="no">transform-2.xsl</xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>