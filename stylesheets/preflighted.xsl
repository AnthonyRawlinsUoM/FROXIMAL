<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
    <html>
        <head>
            <title>Prepared SQL</title>
        </head>
    <body>



        <xsl:for-each select="preflighted/relation">
        <div>
            BEGIN TRANSACTION;
            <!-- // -->
            <xsl:apply-templates select="sqlgroup"/>
            <xsl:apply-templates select="meta"/>
            <!-- // -->
            END TRANSACTION;
        </div>
        </xsl:for-each>
    </body>
</html>
</xsl:template>

<xsl:template match="sqlgroup">
<pre>
    WHERE uuid = '<xsl:value-of select="../meta/uuid" type="xs:string"/>'
    <xsl:value-of select="sqlstatement" type="xs:string"/>
</pre>
</xsl:template>

<xsl:template match="meta">
<pre> UUID: <xsl:value-of select="uuid" type="xs:string"/> </pre>
</xsl:template>

</xsl:stylesheet>
