<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="configuration" >
    <configuration>
    <xsl:apply-templates/>
    </configuration>
  </xsl:template>
  <xsl:template match="property">
    <xsl:choose>
      <xsl:when test="starts-with(name, 'cdh')"></xsl:when>
      <xsl:otherwise>
        <xsl:element name = "{name}">
          <xsl:value-of select="value"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
