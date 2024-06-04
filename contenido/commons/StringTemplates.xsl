<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template name="escapeQuote">
		<xsl:param name="pText" select="." />

		<xsl:if test="string-length($pText) >0">
			<xsl:value-of select="substring-before(concat($pText, '&quot;'), '&quot;')" />

			<xsl:if test="contains($pText, '&quot;')">
				<xsl:text>\"</xsl:text>

				<xsl:call-template name="escapeQuote">
					<xsl:with-param name="pText"
						select="substring-after($pText, '&quot;')" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template name="remove-leading-zeros">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="starts-with($text,'0')">
            <xsl:call-template name="remove-leading-zeros">
                <xsl:with-param name="text"
                    select="substring-after($text,'0')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
</xsl:stylesheet>
