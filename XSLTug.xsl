<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    xmlns="http://github.com/wendellpiez/XSLTug"
    xpath-default-namespace="http://github.com/wendellpiez/XSLTug"
    
    xmlns:t="http://github.com/wendellpiez/XSLTug"
    xmlns:c="http://github.com/wendellpiez/XSLTug/configure"
    version="3.0">
    
    <!--<xsl:output indent="yes" omit-xml-declaration="yes"/>-->
    <xsl:output method="text"/>
    
<!-- $argstring is all command-line arguments together
     spliced with \s or '&' -->
    <xsl:param name="argstring" as="xs:string"/>
    
<!-- All args tokenizes around spaces and punctuation -->
    <!--<xsl:variable name="all-args" select="tokenize($argstring,'\p{P}*(&amp;|\s)+')"/>-->
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
    
    <xsl:function name="t:resolved-path">
        <xsl:param name="path"/>
        <xsl:value-of select="resolve-uri($path,$request/request/base_dir)"/>
    </xsl:function>
    
    <xsl:template mode="processtree" match="*[@v castable as xs:anyURI]
        [matches(@v,'\.[a-z]+$')]" priority="2">
        <xsl:variable name="href" select="t:resolved-path(@v)"/>
        <file href="{ $href }" xmlns="http://github.com/wendellpiez/XSLTug/configure">
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
        <xsl:element name="{@v}" namespace="http://github.com/wendellpiez/XSLTug/configure">
            <xsl:apply-templates mode="processtree"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template mode="processtree" match="*[@v=('-h','--help')]">
        <help xmlns="http://github.com/wendellpiez/XSLTug/configure">
            <xsl:apply-templates mode="processtree"/>
        </help>
    </xsl:template>
    
    <xsl:template mode="processtree" match="*">
        <arg xmlns="http://github.com/wendellpiez/XSLTug/configure">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="processtree"/>
        </arg>
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

<!-- Execution traversal happens inside the configuration model.
    It executes by delivering results in default traversal,
    
    Note that we only descend the model if the argument string
    (represented as $processtree) tracks our signature.
    
    We also use the opportunity to test and see what isn't caught.
    
    -->
    
    <!-- when asked to mock up, skip the exception handling -->
    <xsl:template match="c:mockup">
        <xsl:variable name="invocation" select="key('argument-by-signature',t:signature(.),$processtree)"/>
        <xsl:if test="exists($invocation)">
            <xsl:apply-templates/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="c:*">
        <xsl:variable name="invocation" select="key('argument-by-signature',t:signature(.),$processtree)"/>
            <xsl:if test="exists($invocation)">
                <xsl:apply-templates/>
                <xsl:variable name="config" select="."/>
                <xsl:for-each select="$invocation">
                    <xsl:if test="exists(*) and
                        not(*/local-name() = $config//c:*/local-name() )">
                        <xsl:text expand-text="true">&#xA;XSLTug WARNING: Not finding pattern for '{ */ancestor-or-self::*/name() }'&#xA;</xsl:text>
                        <xsl:call-template name="trace-configuration"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>        
    </xsl:template>
       
<!-- Top level element of an argument configuration -->
    <xsl:template match="/tug[not(c:*/local-name() = $processtree/c:*/local-name())]">
        <xsl:text expand-text="true">&#xA;XSLTug WARNING: No configuration for '{ $processtree/*/(@v,local-name())[1] }'</xsl:text>
        <xsl:call-template name="trace-configuration"/>
    </xsl:template>
    
    <xsl:template match="tug">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template name="trace-configuration">
        <xsl:variable as="element()" name="tracer">
            <t:trace/>
        </xsl:variable>
        <xsl:text>&#xA;Current configuration (argument tree):</xsl:text>
        <xsl:apply-templates select="$tracer"/>
    </xsl:template>
    
    <xsl:template match="apply-sequence[source]">
      <xsl:apply-templates select="sequence">
          <xsl:with-param name="source">
              <xsl:copy-of select="source/child::node()"/>
          </xsl:with-param>
      </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="apply-sequence[c:file]">
        <xsl:variable name="arg-signature" select="t:signature(c:file)"/>
        <xsl:variable name="arg" select="key('argument-by-signature',$arg-signature,$processtree)"/>
        <!-- could have more robust exception trapping here -->
        <xsl:apply-templates select="sequence">
            <xsl:with-param name="source" select="document($arg/@href)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!--<xsl:template match="source">
        <xsl:apply-templates/>
    </xsl:template>-->
    
    <xsl:template match="sequence[*]">
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
    
    <xsl:template match="sequence/transform">
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:variable name="xslt-spec" select="."/>
        <xsl:variable name="runtime"
            select="map { 'xslt-version': if (empty($xslt-spec/@version)) then 3.0 else xs:decimal($xslt-spec/@version),
            'stylesheet-location': string($xslt-spec),
            'source-node': $sourcedoc
            }"/>
        <!-- The function returns a map; primary results are under 'output'          unless a base output URI is given          https://www.w3.org/TR/xpath-functions-31/#func-transform -->
        <xsl:sequence select="transform($runtime)?output"/>
    </xsl:template>
    <!-- Not knowing any better, we simply pass along. -->

    <xsl:template match="sequence/make-markdown">
        <!-- Expects html! -->
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:variable name="runtime"
            select="map { 'xslt-version': 3.0,
            'stylesheet-location': 'html-to-markdown.xsl',
            'source-node': $sourcedoc,
            'initial-mode': QName('','md')
            }"/>
        <!-- The function returns a map; primary results are under 'output'          unless a base output URI is given          https://www.w3.org/TR/xpath-functions-31/#func-transform -->
        <xsl:sequence select="transform($runtime)?output"/>
    </xsl:template>
    
    <xsl:template match="source">
        <xsl:apply-templates mode="acquire"/>
    </xsl:template>
    
    <xsl:template match="trace">
        
        <xsl:apply-templates select="$go/t:tug" mode="spill"/>
        <xsl:text>&#xA;&#x200b;</xsl:text>
    </xsl:template>
    
    <xsl:mode name="acquire" on-no-match="shallow-copy"/>
    
<!-- In mode 'acquire', when t:acquire is encountered, we don't want to copy further. -->
    <xsl:template match="c:*[exists(../t:acquire)]" mode="acquire">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template mode="acquire" match="acquire">
        <xsl:variable name="proxy-signature" select="t:signature(parent::c:file)"/>
        <xsl:variable name="path" select="key('argument-by-signature',$proxy-signature,$processtree)/@href"/>
        <!-- could have more robust exception trapping here -->
        <xsl:sequence select="document($path)"/>
    </xsl:template>
    
    <xsl:template match="sequence/*" priority="-0.1">
        <xsl:param name="sourcedoc" as="document-node()"/>
        <xsl:sequence select="$sourcedoc"/>
    </xsl:template>
    
    <xsl:template match="xsl:* | text()" mode="spill"/>
    
    <xsl:template match="t:*" mode="spill">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="c:*" mode="spill">
        <xsl:text expand-text="true">&#xA; { ancestor-or-self::c:*/' ' }{ local-name() }</xsl:text>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="c:file" mode="spill">
        <xsl:text expand-text="true">&#xA; { ancestor-or-self::c:*/' ' }file {{{ @href }}}</xsl:text>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!--<xsl:template match="t:source//*" mode="spill">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>-->
    
    <xsl:variable name="serialization" as="element()">
        <!--see https://www.w3.org/TR/xpath-functions-30/#func-serialize-->
        <serialization-parameters xmlns="http://www.w3.org/2010/xslt-xquery-serialization">
            <omit-xml-declaration value="yes"/>
            <indent value="yes"/>
        </serialization-parameters>
    </xsl:variable>
    
    <xsl:variable name="go" xmlns="http://github.com/wendellpiez/XSLTug/configure"
        xmlns:t="http://github.com/wendellpiez/XSLTug">
        <t:tug>
            <help>
                <xsl:text>XSLTug running in </xsl:text>
                <xsl:value-of select="$request/*/processor"/>
                <xsl:text>&#xA;  for more help see readme ...</xsl:text>
                <xsl:text>&#xA;Current configuration (command tree):</xsl:text>
                <t:trace/>
            </help>
            <show>
                <xsl:value-of select="serialize($request,$serialization)"/>
            </show>
            <mockup>
                <xsl:value-of select="serialize($processtree,$serialization)"/>
            </mockup>
            <test>
               <xsl:variable name="test">
                <t:apply-sequence>
                    <t:source>
                        <okay>
                            <a1>transform-1.xsl</a1>
                            <a2>transform-2.xsl</a2>
                        </okay>
                    </t:source>
                    <t:sequence>
                        <t:transform>transform-1.xsl</t:transform>
                        <t:transform>transform-2.xsl</t:transform>
                    </t:sequence>
                </t:apply-sequence>
                </xsl:variable>
                <xsl:variable name="test-results">
                    <xsl:apply-templates select="$test"/>
                </xsl:variable>
                <xsl:value-of select="serialize($test-results,$serialization)"/>
                <!-- side effects go here ... -->
            </test>

            <XSweet>
                <test><xsl:text>XSweet test successful&#xA;</xsl:text></test>
                <docx-extract>
                    <file href="*.html">
                        <t:make-file method="html">
                            <from>
                                <t:apply-sequence>
                                    <file href="*.xml"/>
                                    <t:sequence>
                                        <t:transform>docx-html-extract.xsl</t:transform>
                                        <t:transform>handle-notes.xsl</t:transform>
                                        <t:transform>scrub.xsl</t:transform>
                                        <t:transform>join-elements.xsl</t:transform>
                                        <t:transform>collapse-paragraphs.xsl</t:transform>
                                        <!-- xsweet sequence -->
                                    </t:sequence>
                                </t:apply-sequence>
                                <!--<file href="source.xml"> </file>-->
                            </from>
                        </t:make-file>
                    </file>
                </docx-extract>
            </XSweet>
            <inspect>
                <t:apply-sequence>
                    <file href="*.xml"/>
                    <t:sequence>
                        <t:transform>xml-diagnostic.xsl</t:transform>
                        <t:make-markdown/>
                    </t:sequence>
                </t:apply-sequence>
            </inspect>
            
            <make-with-xslt>
                <t:make-file>
                    <file href="*.*">
                        <from>
                            <t:apply-transform>
                                <file href="*.xml">
                                    <with>
                                        <xslt>
                                            <t:transform>
                                                <file href="*.xsl"/>
                                            </t:transform>
                                        </xslt>
                                    </with>
                                </file>
                            </t:apply-transform>
                        </from>
                    </file>
                </t:make-file>
            </make-with-xslt>            
        </t:tug>
    </xsl:variable>
    
    <!--
        
        <t:apply-sequence>
        <t:source>
            <file href="*.xml">
                <t:file href="file-href"/>
            </file>
        </t:source>
        <t:sequence>
            <t:transform> ... </t:transform>
            
        </t:sequence>
    </t:apply-sequence>

    
    <t:apply-transform>
        <t:source>
            <file href="*.xml">
                <t:file href="file-href"/>
            <with>
                <t:stylesheet>
              <file href="*.xsl">
                <t:file href="file-href">
                <set>
                <paramvalue>
                <to>
                  <t:with-param>
                <t:any/>
                </t:with-param>
                </to></paramvalue></set>
                </with>

            </file>
        </t:source>

</t:apply-transform>-->
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
</xsl:stylesheet>