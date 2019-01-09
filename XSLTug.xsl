<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs a"
    xmlns="http://github.com/wendellpiez/XSLTug"
    xpath-default-namespace="http://github.com/wendellpiez/XSLTug"
    
    xmlns:t="http://github.com/wendellpiez/XSLTug"
    xmlns:a="http://github.com/wendellpiez/XSLTug/arguments"
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
        <xsl:text>file:</xsl:text>
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
        <request>
            <processor>
                <xsl:value-of select="system-property('xsl:product-name')"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="system-property('xsl:product-version')"/>
                <xsl:text> from </xsl:text>
                <xsl:value-of select="system-property('xsl:vendor')"/>
            </processor>
            
            <base_dir>
                <xsl:value-of select="$dir"/>
            </base_dir>
            <xsl:copy-of select="$argtree"/>
        </request>
    </xsl:variable>

    <xsl:variable name="processtree">
        <!-- everything always in xsltug ns -->
        <xsl:apply-templates select="$argtree" mode="processtree"/>
    </xsl:variable>
    
    <xsl:mode name="processtree" on-no-match="shallow-copy"/>
    
    <xsl:template mode="processtree" match="*[@v castable as xs:anyURI]
        [matches(@v,'\.[a-z]+$')]" priority="2">
        <xsl:variable name="href" select="resolve-uri(@v,$request/request/base_dir)"/>
        <file href="{ $href }" xmlns="http://github.com/wendellpiez/XSLTug/arguments">
            <xsl:if test="doc-available($href)">
            <xsl:for-each select="document($href)/*">
                <xsl:attribute name="root"><xsl:value-of select="local-name()"/></xsl:attribute>
                <xsl:if test="document($href)/*/namespace-uri()">
                    <xsl:attribute name="ns"><xsl:value-of select="namespace-uri(document($href)/*)"/></xsl:attribute>
                </xsl:if>
            </xsl:for-each>
            </xsl:if>
            <xsl:apply-templates mode="processtree"/>
        </file>
    </xsl:template>
    
    <xsl:template mode="processtree" match="*[matches(@v,'^\i\c*$')]">
        <xsl:element name="{@v}" namespace="http://github.com/wendellpiez/XSLTug/arguments">
            <xsl:apply-templates mode="processtree"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template mode="processtree" match="*[@v=('-h','--help')]">
        <help xmlns="http://github.com/wendellpiez/XSLTug/arguments">
            <xsl:apply-templates mode="processtree"/>
        </help>
    </xsl:template>
    
    <xsl:template name="go">
        <!--<xsl:copy-of select="$processtree"/>-->
        <xsl:apply-templates select="$go/tug"/>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    
    
   <xsl:key name="argument-by-signature" match="*"
       use="t:signature(.)"/>
    
<!-- designed to return the same string for an element in the argument
     tree ($processtree) and the corresponding element in the configuration tree ($go) 
    this happens because elements in the 't' namespace are invisible in the latter
    -->
    <xsl:function name="t:signature" as="xs:string">
        <xsl:param name="who" as="node()"/>
        <xsl:value-of select="string-join( 
            ($who/(ancestor-or-self::* except ancestor-or-self::t:*) ! local-name()),'/')"/>
    </xsl:function>
    
<!--<!-\- Matching any argument string in default traversal, we jump to the configuration
      at the same point. -\->
    <xsl:template match="a:*">
        <xsl:apply-templates mode="execute" select="key('argument-by-signature',t:signature(.),$go)">
            <xsl:with-param name="caller" tunnel="yes" select="."/>
        </xsl:apply-templates>
    </xsl:template>-->
    
<!-- Execution traversal happens inside the configuration model.
    It executes by delivering results in default traversal,
    
    Note that we only descend the model if the argument string
    (represented as $processtree) tracks our signature.
    
    We also use the opportunity to test and see what isn't caught.
    
    -->
    <xsl:template match="a:*">
        <xsl:variable name="invocation" select="key('argument-by-signature',t:signature(.),$processtree)"/>
            <xsl:if test="exists($invocation)">
                <xsl:apply-templates/>
        
                <!--<xsl:variable name="nextdown" select="distinct-values( (descendant::a:* except descendant::a:*//a:*)/local-name() )"/>-->
                <!--<xsl:if test="not($invocation/a:*/local-name() = $nextdown )">
                    <xsl:text expand-text="true">Not finding pattern for '{ $invocation/a:*/ancestor-or-self::*/name() }'&#xA;</xsl:text>
                    <xsl:text expand-text="true">Try{ if (count($nextdown) gt 1) then ' (one of)' else ' ' }{ string-join(
                        ($nextdown ! '''' ||  string-join(($invocation/ancestor-or-self::a:*/local-name(),.),' ') || ''''),', ') }&#xA;</xsl:text>
            </xsl:if>-->
            </xsl:if>        
    </xsl:template>
       
<!-- Top level element of an argument configuration -->
   <xsl:template match="tug">
       <xsl:if expand-text="true" test="empty(ancestor::*) and not(a:*/local-name() = $processtree/a:*/local-name() )">Warning: no spec for { $processtree/*/local-name() }&#xA;</xsl:if>
       <xsl:apply-templates/>
   </xsl:template>
    
    
    
    <!--<xsl:variable name="dummy-sequence">
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
    </xsl:variable>--> 
    
    <xsl:template match="apply-sequence">
       
      <xsl:apply-templates select="sequence">
          <xsl:with-param name="source">
              <xsl:apply-templates select="source"/>
          </xsl:with-param>
      </xsl:apply-templates>
    </xsl:template>
    
    <!--<xsl:template match="source">
        <xsl:apply-templates/>
    </xsl:template>-->
    
    <xsl:template match="sequence[transform]">
        <xsl:param name="source" as="document-node()?"/>
        <!--<xsl:text expand-text="yes">Matched { count($source) }</xsl:text>-->
        
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

    <xsl:template match="source">
        <xsl:apply-templates mode="acquire"/>
    </xsl:template>
    
    <xsl:mode name="acquire" on-no-match="shallow-copy"/>
    
    <xsl:template mode="acquire" match="file[@href='file-href']">
        <xsl:variable name="proxy-signature" select="t:signature(parent::a:file)"/>
        <xsl:variable name="path" select="key('argument-by-signature',$proxy-signature,$processtree)/@href"/>
        <!-- could have more robust exception trapping here -->
        <xsl:sequence select="document($path)"/>
    </xsl:template>
    
    <xsl:template match="sequence/*" priority="-0.1">
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:sequence select="$sourcedoc"/>
    </xsl:template>
    
    <xsl:template mode="echo" match="*">
        <xsl:element name="{local-name()}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:variable name="go" xmlns="http://github.com/wendellpiez/XSLTug/arguments"
        xmlns:t="http://github.com/wendellpiez/XSLTug">
        <t:tug>
            <help>
                <xsl:text> XSLTug running in </xsl:text>
                <xsl:value-of select="$request/*/processor"/>
                <xsl:text>&#xA; for more help see readme ... &#xA;</xsl:text>
            </help>
            <request>
                <xsl:copy-of select="$request"/>
            </request>
            <mockup>
                <xsl:apply-templates mode="echo" select="$processtree"/>
            </mockup>
            <test>
                <t:apply-sequence>
                    <t:source>
                        <okay>transform-2.xsl</okay>
                    </t:source>
                    <t:sequence>
                        <t:transform>transform-1.xsl</t:transform>
                        <t:transform>transform-2.xsl</t:transform>
                    </t:sequence>
                </t:apply-sequence>
                <!-- side effects go here ... -->
            </test>

            <XSweet>
                <test/>
                <docx-extract>
                    <file href="*.html">
                        <t:make-file method="html" href="file-href">
                            <from>
                                <t:apply-sequence>
                                    <t:source>
                                        <file href="*.xml">
                                            <t:file href="file-href"/>
                                        </file>
                                    </t:source>
                                    <t:sequence>
                                        <!-- xsweet sequence -->
                                    </t:sequence>
                                </t:apply-sequence>
                                <!--<file href="source.xml"> </file>-->
                            </from>
                        </t:make-file>
                    </file>
                </docx-extract>
            </XSweet>
        </t:tug>
    </xsl:variable>
</xsl:stylesheet>