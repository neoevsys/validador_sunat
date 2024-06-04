<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
    xmlns:func="http://exslt.org/functions"
    xmlns="urn:sunat:names:specification:ubl:peru:schema:xsd:Perception-1"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
    xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
    xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
    <!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->
    <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
    <xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
    
    <!-- Ini key Documentos relacionados duplicados -->
    <!-- PaseYYYY -->
    <xsl:key name="by-document-payment-id" match="*[local-name()='Perception']/sac:SUNATPerceptionDocumentReference" use="concat(cbc:ID/@schemeID, ' ', cbc:ID, ' ', cac:Payment/cbc:ID)"/>
    <!-- Fin key Documentos relacionados duplicados -->
    
    <xsl:template match="/*">
        
        <!-- Variables -->
                
        <xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>

        <xsl:variable name="cbcCustomizationID"    select="cbc:CustomizationID"/>
        
        <xsl:variable name="cbcID" select="cbc:ID"/>
        
        <xsl:variable name="cbcIssueDate" select="cbc:IssueDate"/>

        <!-- Datos del Emisor Electrónico -->
            <xsl:variable name="cacAgentParty" select="cac:AgentParty"/>
            
            <!-- Mandatorio -->
            <xsl:variable name="cacAgentPartyIdentificationID" select="$cacAgentParty/cac:PartyIdentification/cbc:ID"/>
            
            <!-- Mandatorio -->
            <xsl:variable name="cacAgentPartyIdentificationSchemeID" select="$cacAgentParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacAgentPartyNameName" select="$cacAgentParty/cac:PartyName/cbc:Name"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacAgentPartyPostalAddressID" select="$cacAgentParty/cac:PostalAddress/cbc:ID"/>
            <xsl:variable name="cacAgentPartyPostalAddressStreetName" select="$cacAgentParty/cac:PostalAddress/cbc:StreetName"/>
            <xsl:variable name="cacAgentPartyPostalAddressCitySubdivisionName" select="$cacAgentParty/cac:PostalAddress/cbc:CitySubdivisionName"/>
            <xsl:variable name="cacAgentPartyPostalAddressCityName" select="$cacAgentParty/cac:PostalAddress/cbc:CityName"/>
            <xsl:variable name="cacAgentPartyPostalAddressCountrySubentity" select="$cacAgentParty/cac:PostalAddress/cbc:CountrySubentity"/>
            <xsl:variable name="cacAgentPartyPostalAddressDistrict" select="$cacAgentParty/cac:PostalAddress/cbc:District"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacAgentPartyLegalEntityName" select="$cacAgentParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
            
            <!-- Mandatorio -->
            <xsl:variable name="cacAgentPartyCountryCode" select="$cacAgentParty/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
        <!-- Fin Datos del Emisor Electrónico -->
        
        
        <!-- Datos del Cliente -->
            <xsl:variable name="cacReceiverParty" select="cac:ReceiverParty"/>
            
            <!-- Mandatorio -->
            <xsl:variable name="cacReceiverPartyIdentificationID" select="$cacReceiverParty/cac:PartyIdentification/cbc:ID"/>
            
            <!-- Mandatorio -->
            <xsl:variable name="cacReceiverPartyIdentificationSchemeID" select="$cacReceiverParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacReceiverPartyNameName" select="$cacReceiverParty/cac:PartyName/cbc:Name"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacReceiverPartyPostalAddressID" select="$cacReceiverParty/cac:PostalAddress/cbc:ID"/>
            <xsl:variable name="cacReceiverPartyPostalAddressStreetName" select="$cacReceiverParty/cac:PostalAddress/cbc:StreetName"/>
            <xsl:variable name="cacReceiverPartyPostalAddressCitySubdivisionName" select="$cacReceiverParty/cac:PostalAddress/cbc:CitySubdivisionName"/>
            <xsl:variable name="cacReceiverPartyPostalAddressCityName" select="$cacReceiverParty/cac:PostalAddress/cbc:CityName"/>
            <xsl:variable name="cacReceiverPartyPostalAddressCountrySubentity" select="$cacReceiverParty/cac:PostalAddress/cbc:CountrySubentity"/>
            <xsl:variable name="cacReceiverPartyPostalAddressDistrict" select="$cacReceiverParty/cac:PostalAddress/cbc:District"/>
            
            <!-- Opcional -->
            <xsl:variable name="cacReceiverPartyLegalEntityName" select="$cacReceiverParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
            
            <xsl:variable name="cacReceiverPartyCountryCode" select="$cacReceiverParty/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
        <!-- Fin Datos del Cliente -->

        
        <xsl:variable name="sacSUNATPerceptionSystemCode" select="sac:SUNATPerceptionSystemCode"/>
        
        <xsl:variable name="sacSUNATPerceptionPercent" select="sac:SUNATPerceptionPercent"/>
        
        <xsl:variable name="cbcNote" select="cbc:Note"/>

        <xsl:variable name="cbcTotalInvoiceAmount" select="cbc:TotalInvoiceAmount"/>
        <xsl:variable name="cbcTotalInvoiceAmountCurrencyID" select="cbc:TotalInvoiceAmount/@currencyID"/>
        
        <xsl:variable name="sacSUNATTotalCashed" select="sac:SUNATTotalCashed"/>
        <xsl:variable name="sacSUNATTotalCashedCurrencyID" select="sac:SUNATTotalCashed/@currencyID"/>
		<!-- PAS20211U210700124 Variables agregadas por PROSTGREZ-->
        <xsl:variable name="sacExceptionalIndicator" select="sac:ExceptionalIndicator"/>
        <!-- Fin Variables -->
        
        
        
        <!-- Fin Variables -->
        
        
        <!-- Ini validacion del nombre del archivo vs el nombre del cbc:ID -->
        
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
        
        <xsl:variable name="fileName" select="dp:variable('var://context/cpe/nombreArchivoEnviado')"/>
        <!-- <xsl:variable name="fileName" select="'20520485750-40-P001-20.xml'"/> -->
        <xsl:variable name="rucFilename" select="substring($fileName,1,11)"/>
        
        <!-- Ini PAS20181U210300126 -->
        <!-- <xsl:if test="substring-before($fileName,'.') != concat($rucFilename,'-40-',$cbcID)"> -->
        <xsl:if test="$numeroComprobante != substring(cbc:ID, 6)">
        <!-- Fin PAS20181U210300126 -->
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="'1049'" />
                <xsl:with-param name="errorMessage" select="concat('Validation Filename error name: ', $fileName,'; cbc:ID: ', $cbcID)" />
            </xsl:call-template>
        </xsl:if>
        
        <!-- Fin validacion del nombre del archivo vs el nombre del cbc:ID -->

        
        <!-- Validaciones -->
	
        <!-- Version del UBL -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2111'"/>
            <xsl:with-param name="errorCodeValidate" select="'2110'"/>
            <xsl:with-param name="node" select="$cbcUBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
        
        <!-- Version de la Estructura del Documento -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2113'"/>
            <xsl:with-param name="errorCodeValidate" select="'2112'"/>
            <xsl:with-param name="node" select="$cbcCustomizationID"/>
            <xsl:with-param name="regexp" select="'^(1.0)$'"/>
        </xsl:call-template>
        
        <!-- Numeracion, conformada por serie y numero correlativo -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1002'"/>
            <xsl:with-param name="errorCodeValidate" select="'1001'"/>
            <xsl:with-param name="node" select="$cbcID"/>
            <!-- Ini PAS20181U210300126 -->
            <!-- <xsl:with-param name="regexp" select="'^[P][A-Z0-9]{3}-[0-9]{1,8}?$'"/> -->
            <xsl:with-param name="regexp" select="'(^[P][A-Z0-9]{3}|^[\d]{4})-[0-9]{1,8}?$'"/>
            <!-- Fin PAS20181U210300126 -->
        </xsl:call-template>
        
        <!-- Fecha de emision, patron YYYY-MM-DD -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1010'"/>
            <xsl:with-param name="errorCodeValidate" select="'1009'"/>
            <xsl:with-param name="node" select="$cbcIssueDate"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
        </xsl:call-template>
        
        <!-- PAS20211U210700124 validacion de Postgrez-->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3322'"/>
            <xsl:with-param name="node" select="$sacExceptionalIndicator"/>
            <xsl:with-param name="regexp" select="'^(01)$'"/>
        </xsl:call-template>
        <!--Fin postgrez-->

        <!-- INI PAS20175E210300035 Receptor OSE -->
        <!-- Hora de emision del comprobante 
        <xsl:variable name="cbcIssueTime" select="cbc:IssueTime"/>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4197'"/>
            <xsl:with-param name="node" select="$cbcIssueTime"/>
            <xsl:with-param name="isError" select="false"/>
            <xsl:with-param name="regexp" select="'^[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,5})?$'"/>
        </xsl:call-template>
         FIN PAS20175E210300035 Receptor OSE -->
        
        
        <!-- Datos del Emisor Electrónico -->
        
            <!-- Numero de documento de identidad - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2676'"/>
                <!-- Ini PAS20181U210300134 -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'2677'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'0154'"/>
                <!-- Fin PAS20181U210300134 -->
                <xsl:with-param name="node" select="$cacAgentPartyIdentificationID"/>
                <xsl:with-param name="regexp" select="'^[0-9]{11}$'"/>
            </xsl:call-template>
            
            <!-- Ini PAS20181U210300134 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'1034'" />
                <xsl:with-param name="node" select="$cacAgentPartyIdentificationID" />
                <xsl:with-param name="expresion" select="$rucFilename != $cacAgentPartyIdentificationID" />
            </xsl:call-template>
            <!-- Fin PAS20181U210300134 -->
            
            <!-- Tipo de documento de Identidad, por default 6-RUC - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2678'"/>
                <xsl:with-param name="errorCodeValidate" select="'2511'"/>
                <xsl:with-param name="node" select="$cacAgentPartyIdentificationSchemeID"/>
                <xsl:with-param name="regexp" select="'^(6)$'"/>
            </xsl:call-template>
            
            <!-- Nombre comercial - Opcional -->
            <!-- $$cacAgentPartyNameName No existe el Tag UBL -->
	        <!-- ERR-1038 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyNameName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyNameName) &gt; 1500 or string-length($cacAgentPartyNameName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2901'" />
		               <xsl:with-param name="node" select="$cacAgentPartyNameName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2901'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyNameName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Ini PaseYYY -->
            <!-- Ubigeo, debe de pertenecer al catalogo 13 (Ubigeo)-->
            <xsl:if test="$cacAgentPartyPostalAddressID">
                <xsl:call-template name="findElementInCatalog">
                    <xsl:with-param name="catalogo" select="'13'"/>
                    <xsl:with-param name="idCatalogo" select="$cacAgentPartyPostalAddressID"/>
                    <xsl:with-param name="errorCodeValidate" select="'2917'"/>
                    <!-- Ini PAS20171U210300077 -->
                    <xsl:with-param name="isError" select ="false()"/>
                    <!-- Fin PAS20171U210300077 -->
                </xsl:call-template>
            </xsl:if>
            <!-- Fin PaseYYY -->
        
            <!-- Direccion completa y detallada - Opcional -->
            <!-- $cacAgentPartyPostalAddressStreetName No existe el Tag UBL -->
	        <!-- OBS-2916 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyPostalAddressStreetName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyPostalAddressStreetName) &gt; 100 or string-length($cacAgentPartyPostalAddressStreetName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2916'" />
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressStreetName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2916'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressStreetName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Urbanizacion - Opcional -->
            <!-- $cacAgentPartyPostalAddressCitySubdivisionName No existe el Tag UBL -->
	        <!-- OBS-2902 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyPostalAddressCitySubdivisionName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyPostalAddressCitySubdivisionName) &gt; 30 or string-length($cacAgentPartyPostalAddressCitySubdivisionName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2902'" />
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCitySubdivisionName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2902'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCitySubdivisionName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Provincia - Opcional -->
            <!-- $cacAgentPartyPostalAddressCityName No existe el Tag UBL -->
	        <!-- OBS-2903 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyPostalAddressCityName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyPostalAddressCityName) &gt; 30 or string-length($cacAgentPartyPostalAddressCityName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2903'" />
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCityName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2903'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCityName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Departamento - Opcional -->
            <!-- $cacAgentPartyPostalAddressDistrict No existe el Tag UBL -->
	        <!-- OBS-2904 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyPostalAddressCountrySubentity">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyPostalAddressCountrySubentity) &gt; 30 or string-length($cacAgentPartyPostalAddressCountrySubentity) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2904'" />
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCountrySubentity" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2904'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCountrySubentity"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Distrito - Opcional -->
            <!-- $cacAgentPartyPostalAddressDistrict No existe el Tag UBL -->
	        <!-- OBS-2905 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacAgentPartyPostalAddressDistrict">
	            <xsl:choose>
			       <xsl:when test="string-length($cacAgentPartyPostalAddressDistrict) &gt; 30 or string-length($cacAgentPartyPostalAddressDistrict) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2905'" />
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressDistrict" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2905'"/>
		               <xsl:with-param name="node" select="$cacAgentPartyPostalAddressDistrict"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Codigo del pais de la direccion - Opcional, debe ser PE -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4041'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2548'"/>
                <xsl:with-param name="node" select="$cacAgentPartyCountryCode"/>
                <xsl:with-param name="regexp" select="'^(PE)$'"/>
            </xsl:call-template>
            
            <!-- Apellidos y nombres, denominacion o razon social - Mandatorio -->
            <!-- $cacAgentPartyLegalEntityName No existe el Tag UBL -->
	        <!-- ERR-1038 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
	        <!-- ERR-1037 No existe el Tag UBL o es vacio -->
	        <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
	            <xsl:with-param name="node" select="$cacAgentPartyLegalEntityName"/>
	        </xsl:call-template>
            
            <xsl:choose>
		       <xsl:when test="string-length($cacAgentPartyLegalEntityName) &gt; 1500 or string-length($cacAgentPartyLegalEntityName) &lt; 1 ">
		            <xsl:call-template name="isTrueExpresionIfExist">
	               <xsl:with-param name="errorCodeValidate" select="'1038'" />
	               <xsl:with-param name="node" select="$cacAgentPartyLegalEntityName" />
	               <xsl:with-param name="expresion" select="true()" />
	            </xsl:call-template>
		       </xsl:when>
		       <xsl:otherwise>
	            <xsl:call-template name="regexpValidateElementIfExist">
	               <xsl:with-param name="errorCodeValidate" select="'1038'"/>
	               <xsl:with-param name="node" select="$cacAgentPartyLegalEntityName"/>
	               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/> 
	            </xsl:call-template>
		       </xsl:otherwise>
	        </xsl:choose>
            <!-- Fin Datos del Cliente -->
            
        <!-- Fin Datos del Emisor Electrónico -->
        
        
        <!-- Datos del Cliente -->

            <!-- Numero de documento de identidad - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2679'"/>
                <xsl:with-param name="errorCodeValidate" select="'2680'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyIdentificationID"/>
                <xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,15}$'"/>
            </xsl:call-template>
            
            <!-- Tipo de documento -->
	        <xsl:call-template name="existElementNoVacio">
	            <xsl:with-param name="errorCodeNotExist" select="'2516'"/>
	            <xsl:with-param name="node" select="$cacReceiverPartyIdentificationSchemeID"/>
	        </xsl:call-template>
        
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'06'"/>
                <xsl:with-param name="idCatalogo" select="$cacReceiverPartyIdentificationSchemeID"/>
                <xsl:with-param name="errorCodeValidate" select="'2511'"/>
            </xsl:call-template>
            
            <!-- Nombre comercial - Opcional -->
            <!-- $cacReceiverPartyNameName No existe el Tag UBL -->
	        <!-- OBS-2911 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyNameName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyNameName) &gt; 1500 or string-length($cacReceiverPartyNameName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2911'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyNameName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2911'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyNameName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Ini PaseYYY -->
            <!-- Ubigeo, debe de pertenecer al catalogo 13 (Ubigeo)-->
            <xsl:if test="$cacReceiverPartyPostalAddressID">
                <xsl:call-template name="findElementInCatalog">
                    <xsl:with-param name="catalogo" select="'13'"/>
                    <xsl:with-param name="idCatalogo" select="$cacReceiverPartyPostalAddressID"/>
                    <xsl:with-param name="errorCodeValidate" select="'2917'"/>
                    <!-- Ini PAS20171U210300077 -->
                    <xsl:with-param name="isError" select ="false()"/>
                    <!-- Fin PAS20171U210300077 -->
                </xsl:call-template>
            </xsl:if>
            <!-- Fin PaseYYY -->
        
            <!-- Direccion completa y detallada - Opcional -->
            <!-- $cacReceiverPartyPostalAddressStreetName No existe el Tag UBL -->
	        <!-- OBS-2919 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyPostalAddressStreetName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyPostalAddressStreetName) &gt; 100 or string-length($cacReceiverPartyPostalAddressStreetName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2919'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressStreetName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2919'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressStreetName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Urbanizacion - Opcional -->
            <!-- $cacReceiverPartyPostalAddressCitySubdivisionName No existe el Tag UBL -->
	        <!-- OBS-2912 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyPostalAddressCitySubdivisionName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyPostalAddressCitySubdivisionName) &gt; 30 or string-length($cacReceiverPartyPostalAddressCitySubdivisionName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2912'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCitySubdivisionName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2912'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCitySubdivisionName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Provincia - Opcional -->
            <!-- $cacReceiverPartyPostalAddressCityName No existe el Tag UBL -->
	        <!-- OBS-2913 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyPostalAddressCityName">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyPostalAddressCityName) &gt; 30 or string-length($cacReceiverPartyPostalAddressCityName) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2913'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCityName" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2913'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCityName"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Departamento - Opcional -->
            <!-- $cacReceiverPartyPostalAddressCountrySubentity No existe el Tag UBL -->
	        <!-- OBS-2914 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyPostalAddressCountrySubentity">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyPostalAddressCountrySubentity) &gt; 30 or string-length($cacReceiverPartyPostalAddressCountrySubentity) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2914'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCountrySubentity" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2914'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCountrySubentity"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Distrito - Opcional -->
            <!-- $cacReceiverPartyPostalAddressDistrict No existe el Tag UBL -->
	        <!-- OBS-2915 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
            <xsl:if test="$cacReceiverPartyPostalAddressDistrict">
	            <xsl:choose>
			       <xsl:when test="string-length($cacReceiverPartyPostalAddressDistrict) &gt; 30 or string-length($cacReceiverPartyPostalAddressDistrict) &lt; 1 ">
			            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2915'" />
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressDistrict" />
		               <xsl:with-param name="expresion" select="true()" />
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2915'"/>
		               <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressDistrict"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/>
		               <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
			       </xsl:otherwise>
		        </xsl:choose>
            </xsl:if>
            
            <!-- Codigo del pais de la direccion - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4041'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2548'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyCountryCode"/>
                <xsl:with-param name="regexp" select="'^(PE)$'"/>
            </xsl:call-template>
            
            <!-- Apellidos y nombres, denominacion o razon social - Mandatorio -->
            <!-- $cacReceiverPartyLegalEntityName No existe el Tag UBL -->
	        <!-- ERR-2133 Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres (se considera cualquier carácter incluido espacio, no se permite ningún otro "whitespace character": salto de línea, tab, fin de línea, etc.) -->
	        <!-- ERR-2134 No existe el Tag UBL o es vacio -->
	        <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'2134'"/>
	            <xsl:with-param name="node" select="$cacReceiverPartyLegalEntityName"/>
	        </xsl:call-template>
            
            <xsl:choose>
		       <xsl:when test="string-length($cacReceiverPartyLegalEntityName) &gt; 1500 or string-length($cacReceiverPartyLegalEntityName) &lt; 1 ">
		            <xsl:call-template name="isTrueExpresionIfExist">
	               <xsl:with-param name="errorCodeValidate" select="'2133'" />
	               <xsl:with-param name="node" select="$cacReceiverPartyLegalEntityName" />
	               <xsl:with-param name="expresion" select="true()" />
	            </xsl:call-template>
		       </xsl:when>
		       <xsl:otherwise>
	            <xsl:call-template name="regexpValidateElementIfExist">
	               <xsl:with-param name="errorCodeValidate" select="'2133'"/>
	               <xsl:with-param name="node" select="$cacReceiverPartyLegalEntityName"/>
	               <xsl:with-param name="regexp" select="'^(?!\s*$)[ \S]{0,}$'"/> 
	            </xsl:call-template>
		       </xsl:otherwise>
	      </xsl:choose>
		  <!-- Fin Datos del Cliente -->
        

        
        <!-- Ini Datos de Percepcion y otros -->
        
            <!-- catalogo 22 
            01    PERCEPCION VENTA INTERNA    TASA 2%
            02    PERCEPCION A LA ADQUISICION DE COMBUSTIBLE    TASA 1%
            03    PERCEPCION REALIZADA AL AGENTE DE PERCEPCION CON TASA ESPECIAL    TASA 0.5%
            -->    
            <!-- Regimen de percepcion, debe de pertenecer al catalogo 22-->
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'22'"/>
                <xsl:with-param name="idCatalogo" select="$sacSUNATPerceptionSystemCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2602'"/>
            </xsl:call-template>

            <!-- Tasa de percepción, debe de pertenecer al catalogo 22-->
            <xsl:call-template name="findElementInCatalogProperty">
                <xsl:with-param name="catalogo" select="'22'"/>
                <xsl:with-param name="propiedad" select="'tasa'"/>
                <xsl:with-param name="idCatalogo" select="$sacSUNATPerceptionSystemCode"/>
                <xsl:with-param name="valorPropiedad" select="number($sacSUNATPerceptionPercent)"/>
                <xsl:with-param name="errorCodeValidate" select="'2603'"/>
            </xsl:call-template>
            
            <!-- Importe total Percibido, tiene que ser mayor que cero -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2683'"/>
                <xsl:with-param name="errorCodeValidate" select="'2669'"/>
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmount"/>
                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
            </xsl:call-template>
            
            
            <!-- Ini PAS20181U210300134 Ajustes -->
            <!-- Se quito validacion de java y se puso en DP -->
            <!-- <xsl:variable name="sumatoriaTotalPercibido" select="(round(sum((sac:SUNATPerceptionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '40']/sac:SUNATPerceptionInformation/sac:SUNATPerceptionAmount)) * 100) div 100)"/>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2667'" />
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmount" />
                <xsl:with-param name="expresion" select="$cbcTotalInvoiceAmount != $sumatoriaTotalPercibido" />
            </xsl:call-template> -->
            <!-- Fin PAS20181U210300134 Ajustes -->
            
            
            <!-- Moneda del Importe total Percibido, debe ser PEN -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2684'"/>
                <xsl:with-param name="errorCodeValidate" select="'2685'"/>
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmountCurrencyID"/>
                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
            </xsl:call-template>
            
            <!-- Importe total Cobrado, tiene que ser mayor que cero -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2686'"/>
                <xsl:with-param name="errorCodeValidate" select="'2687'"/>
                <xsl:with-param name="node" select="$sacSUNATTotalCashed"/>
                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
            </xsl:call-template>
            
            
            <!-- Ini PAS20181U210300134 Ajustes por redondeo -->
            
            <!-- Ajuste por redondeo - Opcional -->
            <!-- <xsl:variable name="cbcPayableRoundingAmount" select="cbc:PayableRoundingAmount"/>
            <xsl:variable name="cbcPayableRoundingAmountCurrencyID" select="cbc:PayableRoundingAmount/@currencyID"/>
            
            <xsl:variable name="sumatoriaTotalACobrar" select="(round(sum((sac:SUNATPerceptionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '40']/sac:SUNATPerceptionInformation/sac:SUNATNetTotalCashed)) * 100) div 100)"/>
            <xsl:variable name="sumaTotalCobradoMasRedondeo" select="(round(number($sumatoriaTotalACobrar + $cbcPayableRoundingAmount) * 100) div 100)"/>
            
            <xsl:choose>
                        
                <xsl:when test="$cbcPayableRoundingAmount">

	                <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'4314'" />
		                <xsl:with-param name="node" select="$cbcPayableRoundingAmount" />
		                <xsl:with-param name="expresion" select="number($cbcPayableRoundingAmount) &gt; number('1.00') or number($cbcPayableRoundingAmount) &lt; number('-1.00')" />
		                <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>

	                <xsl:call-template name="regexpValidateElementIfExist">
	                    <xsl:with-param name="errorCodeValidate" select="'4316'"/>
	                    <xsl:with-param name="node" select="$cbcPayableRoundingAmountCurrencyID"/>
	                    <xsl:with-param name="regexp" select="'^(PEN)$'"/>
	                    <xsl:with-param name="isError" select ="false()"/>
	                </xsl:call-template>

		            <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2668'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalCashed" />
                        <xsl:with-param name="expresion" select="$sumaTotalCobradoMasRedondeo != $sacSUNATTotalCashed" />
                    </xsl:call-template>
            
                </xsl:when>
                <xsl:otherwise>
                
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2668'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalCashed" />
                        <xsl:with-param name="expresion" select="$sumatoriaTotalACobrar != $sacSUNATTotalCashed" />
                    </xsl:call-template>

                </xsl:otherwise>
            </xsl:choose> -->
            
            <!-- Fin PAS20181U210300134 Ajustes por redondeo -->
            
            
            <!-- Moneda del Importe total Cobrado, debe ser PEN -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2689'"/>
                <xsl:with-param name="errorCodeValidate" select="'2690'"/>
                <xsl:with-param name="node" select="$sacSUNATTotalCashedCurrencyID"/>
                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
            </xsl:call-template>
        
        <!-- Fin Datos de Percepcion y otros -->
        
        
	       	<!-- PAS20211U210700124 validacion de Postgrez-->
	        <xsl:if test="$sacExceptionalIndicator = '01'">
	            
	         	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3323'" />
	                <xsl:with-param name="node" select="$sacExceptionalIndicator" />
	                <xsl:with-param name="expresion" select="count(sac:SUNATPerceptionDocumentReference) &gt; 1" />
	            </xsl:call-template>
	            
	        </xsl:if>
	        <!--Fin postgrez-->
	        
        <!-- Ini Validaciones de Documentos relacionados -->
        
            <xsl:apply-templates select="sac:SUNATPerceptionDocumentReference">
	            <xsl:with-param name="sacExceptionalIndicator" select="$sacExceptionalIndicator"/>
		    </xsl:apply-templates>
        
        <!-- Ini Validaciones de Documentos relacionados -->
        

        <!-- Ini PAS20181U210300134 Ajustes -->
            <!-- Se quito validacion de java y se puso en DP -->
            <xsl:variable name="sumatoriaTotalPercibido" select="(round(sum((sac:SUNATPerceptionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '40']/sac:SUNATPerceptionInformation/sac:SUNATPerceptionAmount)) * 100) div 100)"/>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2667'" />
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmount" />
                <xsl:with-param name="expresion" select="$cbcTotalInvoiceAmount != $sumatoriaTotalPercibido" />
            </xsl:call-template>
        <!-- Fin PAS20181U210300134 Ajustes -->


        <!-- Ini PAS20181U210300134 Ajustes por redondeo -->
            
            <!-- Ajuste por redondeo - Opcional -->
            <xsl:variable name="cbcPayableRoundingAmount" select="cbc:PayableRoundingAmount"/>
            <xsl:variable name="cbcPayableRoundingAmountCurrencyID" select="cbc:PayableRoundingAmount/@currencyID"/>
            
            <xsl:variable name="sumatoriaTotalACobrar" select="(round(sum((sac:SUNATPerceptionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '40']/sac:SUNATPerceptionInformation/sac:SUNATNetTotalCashed)) * 100) div 100)"/>
            <xsl:variable name="sumaTotalCobradoMasRedondeo" select="(round(number($sumatoriaTotalACobrar + $cbcPayableRoundingAmount) * 100) div 100)"/>
            
            <xsl:choose>
                        
                <xsl:when test="$cbcPayableRoundingAmount">

                    <!-- El valor para el ajuste por redondeo debe ser +- S/. 1.00 -->
                    <!-- PAS20211U210700059 - Excel v7 - OBS-4314 pasa a ERR-3303 -->
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'3303'" />
                        <xsl:with-param name="node" select="$cbcPayableRoundingAmount" />
                        <xsl:with-param name="expresion" select="number($cbcPayableRoundingAmount) &gt; number('1.00') or number($cbcPayableRoundingAmount) &lt; number('-1.00')" />
                        <!--xsl:with-param name="isError" select ="false()"/-->
                    </xsl:call-template>
                    
                    <!-- Moneda del Ajuste por redondeo, debe ser PEN -->
                    <!-- PAS20211U210700059 - Excel v7 - OBS-4316 pasa a ERR-3304 -->
                    <xsl:call-template name="regexpValidateElementIfExist">
                        <xsl:with-param name="errorCodeValidate" select="'3304'"/>
                        <xsl:with-param name="node" select="$cbcPayableRoundingAmountCurrencyID"/>
                        <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                        <!--xsl:with-param name="isError" select ="false()"/-->
                    </xsl:call-template>
                    <!-- Importe total cobrado debe ser igual a la suma de los importes cobrados por cada documento relacionado, sin considerar los tipos de documentos "07" y "40" -->
                    <!-- Validacion en java, se paso a DP -->
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2668'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalCashed" />
                        <xsl:with-param name="expresion" select="$sumaTotalCobradoMasRedondeo != $sacSUNATTotalCashed" />
                    </xsl:call-template>
            
                </xsl:when>
                <xsl:otherwise>
                
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2668'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalCashed" />
                        <xsl:with-param name="expresion" select="$sumatoriaTotalACobrar != $sacSUNATTotalCashed" />
                    </xsl:call-template>

                </xsl:otherwise>
            </xsl:choose>
            
        <!-- Fin PAS20181U210300134 Ajustes por redondeo -->


        
        <!-- Fin Validaciones -->
        
        <xsl:copy-of select="." />
        
    </xsl:template>
    
    
    <!-- Ini Validaciones documentos relacionados -->
        
        <xsl:template match="sac:SUNATPerceptionDocumentReference">
			<xsl:param name="sacExceptionalIndicator" select = "'-'" />
            <!-- Ini Datos del Comprobante Relacionado -->
        
                <!-- Tipo de documento Relacionado, Pueden de ser: 01 Factura, 03 Boleta, 12 ticket, 07 nota de credito o 08 Nota de debito-->
                <!-- Tambien puede aceptar un documento 40 (Comprobante de percepcion) solo si el mismo es electrónico, fué revertido, y el Comprobante de Percepción Electrónico a ser emitido es en reemplazo del revertido. -->
                <xsl:variable name="tipoDocumentoRel" select="cbc:ID/@schemeID"/>
                
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2691'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2692'"/>
                    <xsl:with-param name="node" select="$tipoDocumentoRel"/>
                    <!-- Ini PAS20181U210300126 -->
                    <!-- <xsl:with-param name="regexp" select="'^(01|03|12|07|08|40)$'"/> -->
                    <xsl:with-param name="regexp" select="'^(01|03|12|07|08|40|41)$'"/>
                    <!-- Fin PAS20181U210300126 -->
                    <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                </xsl:call-template>
                
                <!-- Numero de documento Relacionado, conformado por la serie y numero -->
                <xsl:variable name="numeroDocumentoRel" select="cbc:ID"/>

				<!-- PAS20211U210700124 validacion de Postgrez-->
		        <xsl:if test="$sacExceptionalIndicator = '01'">
		            <xsl:call-template name="regexpValidateElementIfExist">
			            <xsl:with-param name="errorCodeValidate" select="'3324'" />
			            <xsl:with-param name="node" select="$tipoDocumentoRel" />
			            <xsl:with-param name="regexp" select="'^(01)$'" />
			        </xsl:call-template>        
		        </xsl:if>
		        <!--Fin postgrez-->
                <!--
                Validaciones para la serie:
                    - Si es electrónico con series E001, EB01, FNNN o BNNN debe ser válido, donde N es alfanumérico.
                    - Si es serie numérica NNNN (comprobante físico) debe estar autorizado por SUNAT.
                    - Si es ticket, debe ser alfanumérico hasta 20 posiciones.
                
                    Si es un Comprobante de Percepción Revertido.
                    - Series E001 o PNNN debe ser válido, donde N es alfanumérico.
                    
                Validaciones para la numeración:
                    - Hasta 8 dígitos si tipo de comprobante relacionado es 01, 03, 07, 08, 40.
                    - Hasta 20 dígitos si tipo de comprobante relacionado es 12.
                -->
                <xsl:choose>
                    <xsl:when test="$tipoDocumentoRel = '12'">
                        <!-- 20 caracteres alfanumericos incluido el guion opcional el correlativo de 20 numeros -->
                        <xsl:call-template name="existAndRegexpValidateElement">
                            <xsl:with-param name="errorCodeNotExist" select="'2693'"/>
                            <xsl:with-param name="errorCodeValidate" select="'2694'"/>
                            <xsl:with-param name="node" select="$numeroDocumentoRel"/>
                            <!--xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,20}(-[0-9]{1,20})$'"/-->
                            <xsl:with-param name="regexp" select="'^[a-zA-Z0-9-]{1,20}(-[0-9]{1,20})$'"/>
                            <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Validaciones de serie y numero  -->
                        <xsl:call-template name="existAndRegexpValidateElement">
                            <xsl:with-param name="errorCodeNotExist" select="'2693'"/>
                            <xsl:with-param name="errorCodeValidate" select="'2694'"/>
                            <xsl:with-param name="node" select="$numeroDocumentoRel"/>
                            <!-- Ini PAS20181U210300134 -->
                            <!-- <xsl:with-param name="regexp" select="'^(E001|EB01|((F|B|P)[A-Z0-9]{3})|((?!(^0{4}))\d{4}))-(?!0+$)([0-9]{1,8})$'"/> -->
                            <xsl:with-param name="regexp" select="'^(E001|EB01|((F|B|P)[A-Z0-9]{3})|(\d{4}))-(?!0+$)([0-9]{1,8})$'"/>
                            <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            <!-- Fin PAS20181U210300134 -->
                        </xsl:call-template>    
                    </xsl:otherwise>
                </xsl:choose>
                
                <!-- Fecha emision documento Relacionado -->
                <xsl:variable name="fechaEmisionDocumentoRel" select="cbc:IssueDate"/>
                
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'1010'"/>
                    <xsl:with-param name="errorCodeValidate" select="'1009'"/>
                    <xsl:with-param name="node" select="$fechaEmisionDocumentoRel"/>
                    <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                </xsl:call-template>
                
                <!-- Importe total documento Relacionado -->
                <xsl:variable name="importeTotalDocumentoRel" select="cbc:TotalInvoiceAmount"/>
                
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2695'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2696'"/>
                    <xsl:with-param name="node" select="$importeTotalDocumentoRel"/>
                    <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                </xsl:call-template>
                
                <!-- Tipo de moneda documento Relacionado, el tipo de moneda lo valida el squema XSD -->
                <xsl:variable name="monedaImporteTotalDocumentoRel" select="cbc:TotalInvoiceAmount/@currencyID"/>
                
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2701'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2718'"/>
                    <xsl:with-param name="node" select="$monedaImporteTotalDocumentoRel"/>
                    <xsl:with-param name="regexp" select="'^[A-Z]{3}$'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                </xsl:call-template>
            
            <!-- Fin Datos del Comprobante Relacionado -->

            <!-- Los tags de los datos de cobro y datos de la percepción serán C cuando el tag $tipoDocumentoRel sea igual a 07 (Nota de crédito) -->
            <xsl:if test="$tipoDocumentoRel != '07'">
                
                <!-- Ini Datos del Cobro -->
            
                    <!-- Numero de cobro -->
                    <xsl:variable name="numeroCobro" select="cac:Payment/cbc:ID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2697'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2698'"/>
                        <xsl:with-param name="node" select="$numeroCobro"/>
                        <xsl:with-param name="regexp" select="'^[0-9]{1,9}$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Ini PaseYYY -->
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2626'" />
                        <xsl:with-param name="node" select="cac:Payment/cbc:ID" />
                        <xsl:with-param name="expresion" select="count(key('by-document-payment-id', concat(cbc:ID/@schemeID, ' ', cbc:ID, ' ', cac:Payment/cbc:ID))) > 1" />
                    </xsl:call-template>
                    <!-- Fin PaseYYY -->
                
                    <!-- Importe del cobro -->
                    <xsl:variable name="importeCobro" select="cac:Payment/cbc:PaidAmount"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2699'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2700'"/>
                        <xsl:with-param name="node" select="$importeCobro"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda de cobro, debe ser la misma que la del documento relacionado -->
                    <xsl:variable name="monedaImporteCobro" select="cac:Payment/cbc:PaidAmount/@currencyID"/>
                    
                    <xsl:if test="$monedaImporteTotalDocumentoRel != $monedaImporteCobro">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="'2607'" />
                            <xsl:with-param name="errorMessage" select="concat('Error en la linea', position())" />
                        </xsl:call-template>
                    </xsl:if>
                    
                    <!-- Fecha de cobro -->
                    <xsl:variable name="fechaCobro" select="cac:Payment/cbc:PaidDate"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2702'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2703'"/>
                        <xsl:with-param name="node" select="$fechaCobro"/>
                        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>

                <!-- Fin Datos del Cobro -->

                
                <!-- Ini Datos de la Percepcion -->
                
                    <!-- Importe percibido -->
                    <xsl:variable name="importePercibido" select="sac:SUNATPerceptionInformation/sac:SUNATPerceptionAmount"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2704'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2705'"/>
                        <xsl:with-param name="node" select="$importePercibido"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda de importe percibido -->
                    <xsl:variable name="monedaImportePercibido" select="sac:SUNATPerceptionInformation/sac:SUNATPerceptionAmount/@currencyID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2706'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2707'"/>
                        <xsl:with-param name="node" select="$monedaImportePercibido"/>
                        <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>
                
                    <!-- Fecha de Percepcion -->
                    <xsl:variable name="fechaPercepcion" select="sac:SUNATPerceptionInformation/sac:SUNATPerceptionDate"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2708'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2709'"/>
                        <xsl:with-param name="node" select="$fechaPercepcion"/>
                        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>
                    
                    <!-- Monto total a cobrar -->
                    <xsl:variable name="importeTotalACobrar" select="sac:SUNATPerceptionInformation/sac:SUNATNetTotalCashed"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2710'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2711'"/>
                        <xsl:with-param name="node" select="$importeTotalACobrar"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda del monto total a cobrar -->
                    <xsl:variable name="monedaImporteTotalACobrar" select="sac:SUNATPerceptionInformation/sac:SUNATNetTotalCashed/@currencyID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2712'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2713'"/>
                        <xsl:with-param name="node" select="$monedaImporteTotalACobrar"/>
                        <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>

                <!-- Fin Datos de la Percepcion -->

                
                <!-- Ini Tipo de cambio -->
                    
                    <xsl:choose>
                        
                        <xsl:when test="$monedaImporteTotalDocumentoRel = 'PEN'">
                        
                            <!-- La moneda de referencia para el Tipo de Cambio -->
                            <xsl:variable name="monedaReferenciaTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:SourceCurrencyCode"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2714'"/>
                                <xsl:with-param name="node" select="$monedaReferenciaTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^[A-Z]{3}$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- La moneda de referencia para el tipo de cambio debe ser la misma que la del documento relacionado -->
                            <xsl:if test="$monedaReferenciaTipoCambio != $monedaImporteTotalDocumentoRel">
                                <xsl:call-template name="rejectCall">
                                    <xsl:with-param name="errorCode" select="'2749'" />
                                    <xsl:with-param name="errorMessage" select="concat('Error en la linea', position())" />
                                </xsl:call-template>
                            </xsl:if>
                            
                            <!-- La moneda objetivo para la Tasa de Cambio, debe ser PEN -->
                            <xsl:variable name="monedaPENTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:TargetCurrencyCode"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2715'"/>
                                <xsl:with-param name="node" select="$monedaPENTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                        
                            <!-- Tipo de cambio -->
                            <xsl:variable name="importeTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:CalculationRate"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2716'"/>
                                <xsl:with-param name="node" select="$importeTipoCambio"/>
                                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,4}(\.\d{1,6})?$)'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- Fecha de cambio -->
                            <xsl:variable name="fechaTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:Date"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2717'"/>
                                <xsl:with-param name="node" select="$fechaTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                        </xsl:when>
                        <xsl:otherwise>
                        
                            <!-- La moneda de referencia para el Tipo de Cambio -->
                            <xsl:variable name="monedaReferenciaTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:SourceCurrencyCode"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2719'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2714'"/>
                                <xsl:with-param name="node" select="$monedaReferenciaTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^[A-Z]{3}$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- La moneda de referencia para el tipo de cambio debe ser la misma que la del documento relacionado -->
                            <xsl:if test="$monedaReferenciaTipoCambio != $monedaImporteTotalDocumentoRel">
                                <xsl:call-template name="rejectCall">
                                    <xsl:with-param name="errorCode" select="'2749'" />
                                    <xsl:with-param name="errorMessage" select="concat('Error en la linea', position())" />
                                </xsl:call-template>
                            </xsl:if>
                            
                            <!-- La moneda objetivo para la Tasa de Cambio, debe ser PEN -->
                            <xsl:variable name="monedaPENTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:TargetCurrencyCode"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2720'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2715'"/>
                                <xsl:with-param name="node" select="$monedaPENTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                        
                            <!-- Tipo de cambio -->
                            <xsl:variable name="importeTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:CalculationRate"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2721'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2716'"/>
                                <xsl:with-param name="node" select="$importeTipoCambio"/>
                                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,4}(\.\d{1,6})?$)'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- Fecha de cambio -->
                            <xsl:variable name="fechaTipoCambio" select="sac:SUNATPerceptionInformation/cac:ExchangeRate/cbc:Date"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2722'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2717'"/>
                                <xsl:with-param name="node" select="$fechaTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
        
                        </xsl:otherwise>
                    </xsl:choose>

                <!-- Fin Tipo de cambio -->
                
                
            </xsl:if>


        </xsl:template>

    <!-- Fin Validaciones documentos relacionados -->
    
    
</xsl:stylesheet>