<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	 xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">

	<xsl:template name="rejectCall">
		<xsl:param name="errorCode" />
		<xsl:param name="errorMessage" />
		<xsl:param name="priority" select="'error'"/>
		

        <xsl:message terminate="yes">
			<xsl:value-of select="concat('ERROR: ', $errorMessage)" />
		</xsl:message>

	</xsl:template>
	
	<xsl:template name="error">
		<xsl:param name="codigo" />
		<!-- <xsl:variable name="descripcionError" select="document('local:///commo_ns/cpe/catalogo/CatalogoErrores.xml')" /> -->
		<xsl:variable name="descripcionError" select="document('../cpe/catalogo/CatalogoErrores.xml')" />
		<xsl:value-of select="$descripcionError/catalogoerrores/error[@numero=$codigo]" />
	</xsl:template>
	
	<!-- genera mensaje de warning -->
	<xsl:template name="addWarning">
	
		<xsl:param name="warningCode" />
		
		<xsl:param name="warningMessage" />
		
		
		<xsl:variable name="newWarning">
			
			<xsl:call-template name="createWarning">
			
				<xsl:with-param name="warningCode" select="$warningCode"/>
			
				<xsl:with-param name="warningMessage" select="$warningMessage"/>
				
			</xsl:call-template>
			
		</xsl:variable>
        
        <xsl:message terminate="no">
			<xsl:value-of select="$newWarning" />
		</xsl:message>
		
	</xsl:template>
	
	
	<!--  Crea un nuevo nodo warning -->
	
	<xsl:template name="createWarning">
		<xsl:param name="warningCode" />
		<xsl:param name="warningMessage" />
		
		<xsl:element name="json:object" namespace="http://www.ibm.com/xmlns/prod/2009/jsonx">
	        
	        <xsl:element name="json:string">
	          <xsl:attribute name="name">codigo</xsl:attribute>
	          <xsl:value-of select="$warningCode"/>
	        </xsl:element>
	        
	        <xsl:element name="json:string">
	          <xsl:attribute name="name">warning</xsl:attribute>
	          <xsl:value-of select="$warningMessage"/>
	        </xsl:element>
	        
	      </xsl:element>
	</xsl:template>
	

</xsl:stylesheet>
