<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
	extension-element-prefixes="dp" exclude-result-prefixes="dp json regexp">

	<xsl:template name="generaRestError">
		<xsl:param name="errorCode" />
		<xsl:param name="errorMessage" />
		<xsl:param name="exceptionMessage" />

		<json:object>
			<json:string name="cod">
				<xsl:value-of select="$errorCode" />
			</json:string>
			<json:string name="msg">
				<xsl:value-of select="$errorMessage" />
			</json:string>
			<json:string name="exc">
				<xsl:value-of select="$exceptionMessage" />
			</json:string>
			<json:null name="errors" />
		</json:object>
	</xsl:template>

	<xsl:template name="rejectCall">
		<xsl:param name="errorCode" />
		<xsl:param name="errorMessage" />
		<xsl:param name="priority" select="'error'"/>
		
		<dp:set-variable name="'var://service/error-protocol-response'"	value="'200'" />
		<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="$errorMessage" />
		<dp:set-variable name="'var://context/cpe/codError'" value="$errorCode" />
		<dp:set-variable name="'var://context/cpe/rest_error'" value="'1'" />
		
		<dp:reject/>
        <xsl:message dp:priority="error" dp:type="{$priority}" terminate="yes" >
			
		</xsl:message>

	</xsl:template>
	
	
	<xsl:template name="generaSoapError">
		<xsl:param name="errorCode" />
		<xsl:param name="isClienteError" />
		
		<dp:set-variable name="'var://context/cpe/codError'" value="$errorCode" />
		<dp:set-variable name="'var://context/cpe/rest_error'" value="'1'" />
		
		 <xsl:variable name="errorMessage">
         	<xsl:call-template name="error">
            	<xsl:with-param name="codigo" select="$errorCode"/>
			</xsl:call-template>
            
         </xsl:variable>
         
         
         <xsl:variable name="soap-env" >
         	<xsl:choose>
         		<xsl:when test="$isClienteError = 'true'">Client</xsl:when>
         		<xsl:otherwise>Server</xsl:otherwise>
         	</xsl:choose>
         </xsl:variable>
         
         
	     <soap-env:Fault>
	        <faultcode>soap-env:<xsl:value-of select="$soap-env" /></faultcode>
	        <faultstring><xsl:value-of select="$errorCode" /></faultstring>

	         <detail>
	            <message><xsl:value-of select="$errorMessage" /></message>
	         </detail>
	     </soap-env:Fault>
	</xsl:template>
	

	<!-- Forma EN QUE SE GENERA EL ERROR en factura electronica -->
	<xsl:template name="generaSoapErrorFactura">
		<xsl:param name="errorCode" />
		<xsl:param name="isClienteError" />
        
        <dp:set-variable name="'var://context/cpe/codError'" value="$errorCode" />
		
		<dp:set-variable name="'var://context/cpe/rest_error'" value="'1'" />
         
         <xsl:variable name="errorMessage">
         	<xsl:call-template name="error">
            	<xsl:with-param name="codigo" select="$errorCode"/>
			</xsl:call-template>
            
         </xsl:variable>

         
         <xsl:variable name="soap-env" >
         	<xsl:choose>
         		<xsl:when test="$isClienteError = 'true'">Client</xsl:when>
         		<xsl:otherwise>Server</xsl:otherwise>
         	</xsl:choose>
         </xsl:variable>
                  
	     <soap-env:Fault>
	        <faultcode>soap-env:<xsl:value-of select="concat($soap-env,'.',$errorCode)" /></faultcode>
	        <faultstring><xsl:value-of select="$errorMessage" /></faultstring>
	     </soap-env:Fault>
	</xsl:template>

	<xsl:template name="error">
		<xsl:param name="codigo" />
		<xsl:variable name="descripcionError" select="document('../../../VALI/commons/cpe/catalogo/CatalogoErrores.xml')" />
		<xsl:value-of select="$descripcionError/catalogoerrores/error[@numero=$codigo]" />
	</xsl:template>
	
	<!--  Acumula los warning generados -->
	<xsl:template name="addWarning">
	
		<xsl:param name="warningCode" />
		
		<xsl:param name="warningMessage" />
		
		<xsl:variable name="oldWarning">
		
			
		</xsl:variable>
		
		
		<xsl:variable name="newWarning">
			
			<xsl:call-template name="createWarning">
			
				<xsl:with-param name="warningCode" select="$warningCode"/>
			
				<xsl:with-param name="warningMessage" select="$warningMessage"/>
				
			</xsl:call-template>
			
		</xsl:variable>
		
	</xsl:template>
	
	<!-- Obtenemos los warnings obtenidos en el proceso -->
	<xsl:template name="getWarnings">
	
		
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
