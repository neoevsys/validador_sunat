<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
  xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
  xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp"
  version="1.0">
  <!--xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
  <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
  
  <!-- Ini key Documentos relacionados duplicados -->
	<!-- PaseYYYY -->
	<xsl:key name="by-document-line-id" match="*[local-name()='VoidedDocuments']/sac:VoidedDocumentsLine" use="cbc:LineID"/>
	
	<xsl:key name="by-document-id" match="*[local-name()='VoidedDocuments']/sac:VoidedDocumentsLine" use="concat(cbc:DocumentTypeCode, ' ', sac:DocumentSerialID, ' ', sac:DocumentNumberID)"/>
  <!-- Fin key Documentos relacionados duplicados -->
  
  <xsl:template match="/*">
    <!-- 1.- Tipo Comprobante --> 
    <!--xsl:choose>
      <xsl:when test="not(string(./cbc:InvoiceTypeCode))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="1004" /> <xsl:with-param name="errorMessage" select="'1004 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="not(./cbc:InvoiceTypeCode = 'RA')">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="1003" /> <xsl:with-param name="errorMessage" select="'1003 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose-->
    
    <!-- 2.- Numero del Documento del emisor - Nro RUC --> 
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2217" /> <xsl:with-param name="errorMessage" select="'2217 Error resumen diario de reversiones'" /> </xsl:call-template>
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2217" /> <xsl:with-param name="errorMessage" select="'Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,"^[0-9]{11}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2216" /> <xsl:with-param name="errorMessage" select="'2216 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 3.- Numeracion, conformada por serie y numero correlativo --> <!-- <xsl:value-of select="./cbc:ID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2284" /> <xsl:with-param name="errorMessage" select="'2284 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ID,"[R][R]-[0-9]{8}-[0-9]{1,5}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2673" /> <xsl:with-param name="errorMessage" select="'2673 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
	
	<!-- Ini validacion del nombre del archivo vs el nombre del cbc:ID -->
		
		<xsl:variable name="fileName" select="dp:variable('var://context/cpe/nombreArchivoEnviado')"/>
		<!--<xsl:variable name="fileName" select="'20520485750-RR-20160416-2.xml'"/>-->
		<xsl:variable name="rucFilename" select="substring($fileName,1,11)"/>
		<xsl:variable name="cbcID" select="cbc:ID"/>
		<xsl:variable name="issueDate" select="cbc:IssueDate"/>
		<xsl:variable name="fechaFilename" select="substring($fileName,16,8)"/>
		
		<xsl:if test="substring-before($fileName,'.') != concat($rucFilename, '-', $cbcID)">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2220'" />
				<xsl:with-param name="errorMessage" select="concat('Validation Filename error, name: ', $fileName,'; cbc:ID: ', $cbcID)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$rucFilename != (./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID)">
			<xsl:call-template name="rejectCall">
				<!-- Versión 5 excel -->
        <!--xsl:with-param name="errorCode" select="'0154'" /-->
				<xsl:with-param name="errorCode" select="'1034'" />
        <xsl:with-param name="errorMessage" select="concat('Validation Filename error, ruc file: ', $rucFilename,'; ruc tag: ', (./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))" />
			</xsl:call-template>
		</xsl:if>

	<!-- Fin validacion del nombre del archivo vs el nombre del cbc:ID -->
          
    <!-- 4.- Version de la Estructura del Documento --> <!-- <xsl:value-of select="./cbc:CustomizationID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:CustomizationID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2073" /> <xsl:with-param name="errorMessage" select="'2073 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:CustomizationID="1.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2072" /> <xsl:with-param name="errorMessage" select="'2072 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 5.- Version del UBL --> <!-- <xsl:value-of select="./cbc:UBLVersionID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:UBLVersionID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2075" /> <xsl:with-param name="errorMessage" select="'2075 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:UBLVersionID="2.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2074" /> <xsl:with-param name="errorMessage" select="'2074 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 6.- Tipo de Documento del Emisor - RUC --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cbc:AdditionalAccountID"/> -->
    <xsl:if test="not(string(./cac:AccountingSupplierParty/cbc:AdditionalAccountID))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2288" /> <xsl:with-param name="errorMessage" select="'2288 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:AdditionalAccountID,"^[6]{1}$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2287" /> <xsl:with-param name="errorMessage" select="'2287 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    
    <!-- 7.- Apellidos y nombres o denominacion o razon social Emisor --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2229" /> <xsl:with-param name="errorMessage" select="'2229 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:when test="string-length(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 100 or string-length(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 0 ">
        <xsl:call-template name="rejectCall"> 
           <xsl:with-param name="errorCode" select="2228" /> 
           <xsl:with-param name="errorMessage" select="'2228 Error resumen diario de reversiones'" /> 
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^(.{1,})$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2228" /> <xsl:with-param name="errorMessage" select="'2228 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <!-- 8.- Fecha de emision del documento --> <!-- <xsl:value-of select="./cbc:ReferenceDate"/> --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:ReferenceDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2303" /> <xsl:with-param name="errorMessage" select="'2303 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ReferenceDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2302" /> <xsl:with-param name="errorMessage" select="'2302 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:variable name="fechaEmisionDDMMYYYY" select='concat(substring(./cbc:ReferenceDate,9,2),"-",substring(./cbc:ReferenceDate,6,2),"-",substring(./cbc:ReferenceDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2304" /> <xsl:with-param name="errorMessage" select="'2304 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="fechaRangos" select="./cbc:ReferenceDate"/>
    <xsl:variable name="currentdate" select="date:date()"></xsl:variable>
    <!--xsl:if test="((substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'D') != 'P0') and (substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'P')  != substring-before('-P','P')))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2237" /> <xsl:with-param name="errorMessage" select="'2237 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if-->
    
    <!-- 9.- Fecha de emision de comunicacion --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:IssueDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2299" /> <xsl:with-param name="errorMessage" select="'2299 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:IssueDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2298" /> <xsl:with-param name="errorMessage" select="'2298 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
	
	<!-- Ini validacion del nombre del archivo vs el nombre del cbc:IssueDate -->
		<xsl:if test="translate($issueDate, '-', '') != $fechaFilename">
			<xsl:call-template name="rejectCall">
				<!-- PaseYYY -->
				<!-- <xsl:with-param name="errorCode" select="'2754'" /> -->
				<xsl:with-param name="errorCode" select="'2346'" />
				<xsl:with-param name="errorMessage" select="concat('Validation Filename error, fecha archivo: ', $fechaFilename,'; cbc:IssueDate: ', $issueDate)" />
			</xsl:call-template>
		</xsl:if>
	<!-- Fin validacion del nombre del archivo vs el nombre del cbc:IssueDate -->
    
    <xsl:variable name="fechaEmisionComDDMMYYYY" select='concat(substring(./cbc:IssueDate,9,2),"-",substring(./cbc:IssueDate,6,2),"-",substring(./cbc:IssueDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionComDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2300" /> <xsl:with-param name="errorMessage" select="'2300 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="issuedate" select="./cbc:IssueDate"/>
    <xsl:if test="(date:seconds(date:difference(concat($issuedate,'-00:00'),$currentdate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2301" /> <xsl:with-param name="errorMessage" select="'2301 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test="(date:seconds(date:difference(concat($fechaRangos,'-00:00'),$issuedate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> 
      	<!-- PaseYYY -->
      	<!-- <xsl:with-param name="errorCode" select="4036" /> -->
      	<xsl:with-param name="errorCode" select="2671" />  
      	<xsl:with-param name="errorMessage" select="'2671 Error resumen diario de reversiones'" /> 
      	</xsl:call-template>
    </xsl:if>
    
    
    <!-- 10.- Firma del Documento -->
    <xsl:choose>
      <xsl:when test="not((cac:Signature/cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2076" /> <xsl:with-param name="errorMessage" select="'2076 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cbc:ID,"^(?!\s*$).{1,3000}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2077" /> <xsl:with-param name="errorMessage" select="'2077 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   
    <xsl:if test="not(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2079" /> <xsl:with-param name="errorMessage" select="'2079 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if>
    <!-- xsl:if test="(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2078" /> <xsl:with-param name="errorMessage" select="'2078 Error resumen diario de reversiones'" /> </xsl:call-template>
    </xsl:if-->
   
    <xsl:choose>
      <xsl:when test="not(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name)">
         <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2081" /> <xsl:with-param name="errorMessage" select="'2081 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name,"^[^\s].{1,100}"))'>
           <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2080" /> <xsl:with-param name="errorMessage" select="'2080 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   

      <xsl:if test="not(cac:Signature/cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI)">
         <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2083" /> <xsl:with-param name="errorMessage" select="'2083 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:if>
     
    <xsl:choose>
      <xsl:when test="not((ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id))">
        <!-- Ini PAS20171U210300071 -->
        <!-- <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2085" /> <xsl:with-param name="errorMessage" select="'2085 Error resumen diario de reversiones'" /> </xsl:call-template> -->
        <xsl:call-template name="addWarning"> 
			<xsl:with-param name="warningCode" select="'2085'"/> 
			<xsl:with-param name="warningMessage" select="'2085 Error resumen diario de reversiones'"/>
		</xsl:call-template>
		<!-- Fin PAS20171U210300071 -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2084" /> <xsl:with-param name="errorMessage" select="'2084 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2087" /> <xsl:with-param name="errorMessage" select="'2087 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2086" /> <xsl:with-param name="errorMessage" select="'2086 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2089" /> <xsl:with-param name="errorMessage" select="'2089 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2088" /> <xsl:with-param name="errorMessage" select="'2088 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2091" /> <xsl:with-param name="errorMessage" select="'2091 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='string(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2090" /> <xsl:with-param name="errorMessage" select="'2090 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2093" /> <xsl:with-param name="errorMessage" select="'2093 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2092" /> <xsl:with-param name="errorMessage" select="'2092 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2095" /> <xsl:with-param name="errorMessage" select="'2095 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2094" /> <xsl:with-param name="errorMessage" select="'2094 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2097" /> <xsl:with-param name="errorMessage" select="'2097 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!--
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2096" /> <xsl:with-param name="errorMessage" select="'2096 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
        -->
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2099" /> <xsl:with-param name="errorMessage" select="'2099 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2098" /> <xsl:with-param name="errorMessage" select="'2098 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2101" /> <xsl:with-param name="errorMessage" select="'2101 Error resumen diario de reversiones'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2100" /> <xsl:with-param name="errorMessage" select="'2100 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <!-- Documentos de la Baja -->
    <xsl:for-each select="sac:VoidedDocumentsLine">
      <!-- 11.- Numero de Fila -->
      <xsl:choose>
		<xsl:when test="not(string(cbc:LineID))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2307" /> <xsl:with-param name="errorMessage" select="'2307 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
		<xsl:when test="not(regexp:match(./cbc:LineID,'^[0-9]{1,5}?$'))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2305" /> <xsl:with-param name="errorMessage" select="'2305 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <!-- <xsl:when test="not(string(cbc:LineID))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2307" /> <xsl:with-param name="errorMessage" select="'2307 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when> -->
        <xsl:when test="cbc:LineID &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2306" /> <xsl:with-param name="errorMessage" select="'2306 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      
      <!-- Ini PaseYYY -->
      <xsl:if test="count(key('by-document-line-id', cbc:LineID)) > 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      <!-- Fin PaseYYY -->
      
      <!-- 12.- Tipo de Documento -->
      <xsl:choose>
        <xsl:when test="not(string(./cbc:DocumentTypeCode))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2309" /> <xsl:with-param name="errorMessage" select="'2309 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <!-- <xsl:if test="not(./cbc:DocumentTypeCode = '20' or ./cbc:DocumentTypeCode = '40' or ./cbc:DocumentTypeCode = '41 -->
		  <xsl:if test="not(./cbc:DocumentTypeCode = '20' or ./cbc:DocumentTypeCode = '40' or ./cbc:DocumentTypeCode = '04')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2308" /> <xsl:with-param name="errorMessage" select="'2308 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    
      <!-- 13.- Numero de serie de los documentos --> <!-- ./cbc:DocumentTypeCode = 20: RETENCION y 40: PERCEPCION -->
      <xsl:choose>
        <xsl:when test="not(string(./sac:DocumentSerialID))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2311" /> <xsl:with-param name="errorMessage" select="'2311 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
		
<!--           <xsl:if test='not(regexp:match(./sac:DocumentSerialID,"^[P|R][A-Z0-9]{3}?$"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2310" /> <xsl:with-param name="errorMessage" select="'2310 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if> -->
		  
		  <!-- Ini PAS20181U210300126 -->
		  <!-- <xsl:if test="./cbc:DocumentTypeCode='20' and not(regexp:match(./sac:DocumentSerialID,'^[R][A-Z0-9]{3}?$'))"> -->
		  <xsl:if test="./cbc:DocumentTypeCode='20' and not(regexp:match(./sac:DocumentSerialID,'(^[R][A-Z0-9]{3}|^[\d]{1,4})$'))">
		  <!-- Fin PAS20181U210300126 -->
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2674" /> <xsl:with-param name="errorMessage" select="'2674 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
		  
		  <!-- Ini PAS20181U210300126 -->
		  <!-- <xsl:if test="./cbc:DocumentTypeCode='40' and not(regexp:match(./sac:DocumentSerialID,'^[P][A-Z0-9]{3}?$'))"> -->
		  <xsl:if test="./cbc:DocumentTypeCode='40' and not(regexp:match(./sac:DocumentSerialID,'(^[P][A-Z0-9]{3}|^[\d]{1,4})$'))">
		  <!-- Fin PAS20181U210300126 -->
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2675" /> <xsl:with-param name="errorMessage" select="'2675 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
          
          <xsl:if test="./cbc:DocumentTypeCode='04' and not(regexp:match(./sac:DocumentSerialID,'(^[L][A-Z0-9]{3}|^[\d]{1,4})$'))">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2345" /> <xsl:with-param name="errorMessage" select="'2345 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
		  
<!--           <xsl:if test="./cbc:DocumentTypeCode='20' and not(substring(./sac:DocumentSerialID,1,1)='R')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2671" /> <xsl:with-param name="errorMessage" select="'2671 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test="./cbc:DocumentTypeCode='40' and not(substring(./sac:DocumentSerialID,1,1)='P')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2672" /> <xsl:with-param name="errorMessage" select="'2672 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if> -->
		  
        </xsl:otherwise>
      </xsl:choose>

	  
      
      <!--14.- Numero correlativo del documento dado de baja --> 
      <xsl:choose>
        <xsl:when test="not(string(./sac:DocumentNumberID))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2313" /> <xsl:with-param name="errorMessage" select="'2313 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:DocumentNumberID,"^[0-9]{1,8}?$"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2312" /> <xsl:with-param name="errorMessage" select="'2312 Error resumen diario de reversiones'" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- Ini PaseYYY -->
      <xsl:if test="count(key('by-document-id', concat(cbc:DocumentTypeCode, ' ', sac:DocumentSerialID, ' ', sac:DocumentNumberID))) > 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2348'" /> <xsl:with-param name="errorMessage" select="concat('El documento esta duplicado: ', cbc:DocumentTypeCode, '-', sac:DocumentSerialID, '-', sac:DocumentNumberID)" /> </xsl:call-template>
      </xsl:if>
      <!-- Fin PaseYYY -->
      
      
      <!--15.- Numero correlativo del documento de fin dentro de la serie--> <!--<xsl:value-of select="./sac:StartDocumentNumberID"/>-<xsl:value-of select="./sac:EndDocumentNumberID"/>-->
      <xsl:choose>
        <xsl:when test="not(string(./sac:VoidReasonDescription))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2315" /> <xsl:with-param name="errorMessage" select="'2315 Error resumen diario de reversiones'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
			<xsl:if test='not(regexp:match(./sac:VoidReasonDescription,"^(.{3,100})$"))'>
 				<!-- Versión 5 excel -->
		        <!--xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="2314" /-->
		        <xsl:call-template name="addWarning"> 
					<xsl:with-param name="warningCode" select="'4203'"/> 
					<xsl:with-param name="warningMessage" select="'4203 Error resumen diario de reversiones'"/>
				</xsl:call-template>
				<!-- Versión 5 excel -->
			</xsl:if>
		</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>