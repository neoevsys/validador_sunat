<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
    xmlns:func="http://exslt.org/functions"
    xmlns="urn:sunat:names:specification:ubl:peru:schema:xsd:Retention-1"
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
    <xsl:key name="by-document-payment-id" match="*[local-name()='Retention']/sac:SUNATRetentionDocumentReference" use="concat(cbc:ID/@schemeID, ' ', cbc:ID, ' ', cac:Payment/cbc:ID)"/>
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

        
        <xsl:variable name="sacSUNATRetentionSystemCode" select="sac:SUNATRetentionSystemCode"/>
        
        <xsl:variable name="sacSUNATRetentionPercent" select="sac:SUNATRetentionPercent"/>
        
        <xsl:variable name="cbcNote" select="cbc:Note"/>

        <xsl:variable name="cbcTotalInvoiceAmount" select="cbc:TotalInvoiceAmount"/>
        <xsl:variable name="cbcTotalInvoiceAmountCurrencyID" select="cbc:TotalInvoiceAmount/@currencyID"/>
        
        <xsl:variable name="sacSUNATTotalPaid" select="sac:SUNATTotalPaid"/>
        <xsl:variable name="sacSUNATTotalPaidCurrencyID" select="sac:SUNATTotalPaid/@currencyID"/>
        

        <!-- Fin Variables -->
        
        
        <!-- Ini validacion del nombre del archivo vs el nombre del cbc:ID -->
        
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
        
        <xsl:variable name="fileName" select="dp:variable('var://context/cpe/nombreArchivoEnviado')"/>
        <!-- <xsl:variable name="fileName" select="'20520485750-20-R001-20.xml'"/> -->
        <xsl:variable name="rucFilename" select="substring($fileName,1,11)"/>
        
        <!-- Ini PAS20181U210300126 -->
        <!-- <xsl:if test="substring-before($fileName,'.') != concat($rucFilename,'-20-',$cbcID)"> -->
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
            <!-- <xsl:with-param name="regexp" select="'^[R][A-Z0-9]{3}-[0-9]{1,8}?$'"/> -->
            <xsl:with-param name="regexp" select="'(^[R][A-Z0-9]{3}|^[\d]{4})-[0-9]{1,8}?$'"/>
            <!-- Fin PAS20181U210300126 -->
        </xsl:call-template>
        
        <!-- Fecha de emision, patron YYYY-MM-DD -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1010'"/>
            <xsl:with-param name="errorCodeValidate" select="'1009'"/>
            <xsl:with-param name="node" select="$cbcIssueDate"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
        </xsl:call-template>
        
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
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4092'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2901'"/>
                <xsl:with-param name="node" select="$cacAgentPartyNameName"/>
                <!-- Ini PAS20181U210300134 -->
                <!-- <xsl:with-param name="regexp" select="'^(.{1,100})$'"/> -->
                <xsl:with-param name="regexp" select="'^(.{1,1500})$'"/>
                <!-- Fin PAS20181U210300134 -->
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
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
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4094'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2916'"/>
                <!--<xsl:with-param name="isError" select="true"/>-->
                <xsl:with-param name="node" select="$cacAgentPartyPostalAddressStreetName"/>
                <xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Urbanizacion - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4095'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2902'"/>
                <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCitySubdivisionName"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Provincia - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4096'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2903'"/>
                <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCityName"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Departamento - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4097'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2904'"/>
                <xsl:with-param name="node" select="$cacAgentPartyPostalAddressCountrySubentity"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Distrito - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4098'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2905'"/>
                <xsl:with-param name="node" select="$cacAgentPartyPostalAddressDistrict"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Codigo del pais de la direccion - Opcional, debe ser PE -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4041'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2548'"/>
                <xsl:with-param name="node" select="$cacAgentPartyCountryCode"/>
                <xsl:with-param name="regexp" select="'^(PE)$'"/>
            </xsl:call-template>
            
            <!-- Apellidos y nombres, denominacion o razon social - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
                <xsl:with-param name="errorCodeValidate" select="'1038'"/>
                <xsl:with-param name="node" select="$cacAgentPartyLegalEntityName"/>
                <!-- Ini PAS20181U210300134 -->
                <!-- <xsl:with-param name="regexp" select="'^(.{1,100})$'"/> -->
                <xsl:with-param name="regexp" select="'^(.{1,1500})$'"/>
                <!-- Fin PAS20181U210300134 -->
            </xsl:call-template>
            
        <!-- Fin Datos del Emisor Electrónico -->
        
        
        <!-- Ini Datos del Proveedor -->

            <!-- Numero de documento de identidad - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2723'"/>
                <xsl:with-param name="errorCodeValidate" select="'2724'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyIdentificationID"/>
                <xsl:with-param name="regexp" select="'^[0-9]{11}$'"/>
            </xsl:call-template>
            
            <!-- Tipo de documento de Identidad, 6=RUC - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2516'"/>
                <xsl:with-param name="errorCodeValidate" select="'2511'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyIdentificationSchemeID"/>
                <xsl:with-param name="regexp" select="'^(6)$'"/>
            </xsl:call-template>
            
            <!-- Nombre comercial - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4106'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2906'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyNameName"/>
                <!-- Ini PAS20181U210300134 -->
                <!-- <xsl:with-param name="regexp" select="'^(.{1,100})$'"/> -->
                <xsl:with-param name="regexp" select="'^(.{1,1500})$'"/>
                <!-- Fin PAS20181U210300134 -->
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
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
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4108'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2918'"/>
                <!--<xsl:with-param name="isError" select="true"/>-->
                <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressStreetName"/>
                <xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Urbanizacion - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4109'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2907'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCitySubdivisionName"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Provincia - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4110'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2908'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCityName"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Departamento - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4111'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2909'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressCountrySubentity"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Distrito - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4112'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2910'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyPostalAddressDistrict"/>
                <xsl:with-param name="regexp" select="'^(.{1,30})$'"/>
                <!-- Ini PAS20171U210300077 -->
                <xsl:with-param name="isError" select ="false()"/>
                <!-- Fin PAS20171U210300077 -->
            </xsl:call-template>
            
            <!-- Codigo del pais de la direccion - Opcional -->
            <xsl:call-template name="regexpValidateElementIfExist">
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'4041'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2548'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyCountryCode"/>
                <xsl:with-param name="regexp" select="'^(PE)$'"/>
            </xsl:call-template>
            
            <!-- Apellidos y nombres, denominacion o razon social - Mandatorio -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2134'"/>
                <xsl:with-param name="errorCodeValidate" select="'2133'"/>
                <xsl:with-param name="node" select="$cacReceiverPartyLegalEntityName"/>
                <!-- Ini PAS20181U210300134 -->
                <!-- <xsl:with-param name="regexp" select="'^(.{1,100})$'"/> -->
                <xsl:with-param name="regexp" select="'^(.{1,1500})$'"/>
                <!-- Fin PAS20181U210300134 -->
            </xsl:call-template>
            
        <!-- Fin Datos del Proveedor -->
        
        
        <!-- Ini Datos de Retencion y otros -->
        
            <!-- catalogo 23 
            01  TASA 3%
            --> 
	    <!-- Ini PAS20171U210300071 CRE aceptar tasa 6%, sea agrego el cat_23.xml -->
            <!-- Regimen de retencion, debe de 01-->
            <!--<xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2618'"/>
                <xsl:with-param name="errorCodeValidate" select="'2618'"/>
                <xsl:with-param name="node" select="$sacSUNATRetentionSystemCode"/>
                <xsl:with-param name="regexp" select="'^(01)$'"/>
            </xsl:call-template>-->

            <!-- Tasa de retencion, debe der 3.00-->
            <!--<xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2619'"/>
                <xsl:with-param name="errorCodeValidate" select="'2619'"/>
                <xsl:with-param name="node" select="$sacSUNATRetentionPercent"/>
                <xsl:with-param name="regexp" select="'^(3|3.0|3.00)$'"/>
            </xsl:call-template>-->
            
            <!-- Regimen de retencion, debe de pertenecer al catalogo 23-->
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'23'"/>
                <xsl:with-param name="idCatalogo" select="$sacSUNATRetentionSystemCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2618'"/>
            </xsl:call-template>

            <!-- Tasa de retencion, debe de pertenecer al catalogo 23-->
            <xsl:call-template name="findElementInCatalogProperty">
                <xsl:with-param name="catalogo" select="'23'"/>
                <xsl:with-param name="propiedad" select="'tasa'"/>
                <xsl:with-param name="idCatalogo" select="$sacSUNATRetentionSystemCode"/>
                <xsl:with-param name="valorPropiedad" select="number($sacSUNATRetentionPercent)"/>
                <xsl:with-param name="errorCodeValidate" select="'2619'"/>
            </xsl:call-template>

            <!-- Fin PAS20171U210300071 CRE aceptar tasa 6% -->
            <!-- Importe total Retenido, tiene que ser mayor que cero -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2725'"/>
                <!-- PaseYYY -->
                <!-- <xsl:with-param name="errorCodeValidate" select="'2726'"/> -->
                <xsl:with-param name="errorCodeValidate" select="'2669'"/>
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmount"/>
                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
            </xsl:call-template>


            <!-- Ini PAS20181U210300134 Ajustes -->
            <!-- Se quito validacion de java y se puso en DP -->
            <!-- <xsl:variable name="sumatoriaTotalRetenido" select="(round(sum((sac:SUNATRetentionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '20']/sac:SUNATRetentionInformation/sac:SUNATRetentionAmount)) * 100) div 100)"/>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2628'" />
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmount" />
                <xsl:with-param name="expresion" select="$cbcTotalInvoiceAmount != $sumatoriaTotalRetenido" />
            </xsl:call-template> -->
            <!-- Fin PAS20181U210300134 Ajustes -->
            
            
            <!-- Moneda del Importe total Retenido, debe ser PEN -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2727'"/>
                <xsl:with-param name="errorCodeValidate" select="'2728'"/>
                <xsl:with-param name="node" select="$cbcTotalInvoiceAmountCurrencyID"/>
                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
            </xsl:call-template>
            
            <!-- Importe total Pagado, tiene que ser mayor que cero -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2729'"/>
                <xsl:with-param name="errorCodeValidate" select="'2730'"/>
                <xsl:with-param name="node" select="$sacSUNATTotalPaid"/>
                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
            </xsl:call-template>
            
            
            <!-- Ini PAS20181U210300134 Ajustes por redondeo -->
            
            <!-- Ajuste por redondeo - Opcional -->
            <!-- <xsl:variable name="cbcPayableRoundingAmount" select="cbc:PayableRoundingAmount"/>
            <xsl:variable name="cbcPayableRoundingAmountCurrencyID" select="cbc:PayableRoundingAmount/@currencyID"/>
            
            <xsl:variable name="sumatoriaTotalAPagar" select="(round(sum((sac:SUNATRetentionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '20']/sac:SUNATRetentionInformation/sac:SUNATNetTotalPaid)) * 100) div 100)"/>
            <xsl:variable name="sumaTotalPagadoMasRedondeo" select="(round(number($sumatoriaTotalAPagar + $cbcPayableRoundingAmount) * 100) div 100)"/>
            
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
                        <xsl:with-param name="errorCodeValidate" select="'2629'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalPaid" />
                        <xsl:with-param name="expresion" select="$sumaTotalPagadoMasRedondeo != $sacSUNATTotalPaid" />
                    </xsl:call-template>
            
                </xsl:when>
                <xsl:otherwise>
                
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2629'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalPaid" />
                        <xsl:with-param name="expresion" select="$sumatoriaTotalAPagar != $sacSUNATTotalPaid" />
                    </xsl:call-template>

                </xsl:otherwise>
            </xsl:choose> -->
            
            <!-- Fin PAS20181U210300134 Ajustes por redondeo -->
            
            
            <!-- Moneda del Importe total Pagado, debe ser PEN -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2731'"/>
                <xsl:with-param name="errorCodeValidate" select="'2732'"/>
                <xsl:with-param name="node" select="$sacSUNATTotalPaidCurrencyID"/>
                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
            </xsl:call-template>
        
        <!-- Fin Datos de Percepcion y otros -->
        
        
        <!-- Ini Validaciones de Documentos relacionados -->
        
            <xsl:apply-templates select="sac:SUNATRetentionDocumentReference"/>
        
        <!-- Ini Validaciones de Documentos relacionados -->
        
        
        <!-- Ini PAS20181U210300134 Ajustes -->
        <!-- Se quito validacion de java y se puso en DP -->
	        <xsl:variable name="sumatoriaTotalRetenido" select="(round(sum((sac:SUNATRetentionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '20']/sac:SUNATRetentionInformation/sac:SUNATRetentionAmount)) * 100) div 100)"/>
	
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2628'" />
	            <xsl:with-param name="node" select="$cbcTotalInvoiceAmount" />
	            <xsl:with-param name="expresion" select="$cbcTotalInvoiceAmount != $sumatoriaTotalRetenido" />
	        </xsl:call-template>
        <!-- Fin PAS20181U210300134 Ajustes -->
        
        
        <!-- Ini PAS20181U210300134 Ajustes por redondeo -->
            
            <!-- Ajuste por redondeo - Opcional -->
            <xsl:variable name="cbcPayableRoundingAmount" select="cbc:PayableRoundingAmount"/>
            <xsl:variable name="cbcPayableRoundingAmountCurrencyID" select="cbc:PayableRoundingAmount/@currencyID"/>
            
            <xsl:variable name="sumatoriaTotalAPagar" select="(round(sum((sac:SUNATRetentionDocumentReference[cbc:ID/@schemeID != '07' and cbc:ID/@schemeID != '20']/sac:SUNATRetentionInformation/sac:SUNATNetTotalPaid)) * 100) div 100)"/>
            <xsl:variable name="sumaTotalPagadoMasRedondeo" select="(round(number($sumatoriaTotalAPagar + $cbcPayableRoundingAmount) * 100) div 100)"/>
            
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
                        <xsl:with-param name="errorCodeValidate" select="'2629'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalPaid" />
                        <xsl:with-param name="expresion" select="$sumaTotalPagadoMasRedondeo != $sacSUNATTotalPaid" />
                    </xsl:call-template>
            
                </xsl:when>
                <xsl:otherwise>
                
                    <xsl:call-template name="isTrueExpresion">
                        <xsl:with-param name="errorCodeValidate" select="'2629'" />
                        <xsl:with-param name="node" select="$sacSUNATTotalPaid" />
                        <xsl:with-param name="expresion" select="$sumatoriaTotalAPagar != $sacSUNATTotalPaid" />
                    </xsl:call-template>

                </xsl:otherwise>
            </xsl:choose>
            
        <!-- Fin PAS20181U210300134 Ajustes por redondeo -->
        
        
        <!-- Fin Validaciones -->
        
        <xsl:copy-of select="." />
        
    </xsl:template>
    
    
    <!-- Ini Validaciones documentos relacionados -->
        
        <xsl:template match="sac:SUNATRetentionDocumentReference">

            <!-- Ini Datos del Comprobante Relacionado -->
        
                <!-- Tipo de documento Relacionado, Pueden de ser: 01 Factura, 12 ticket, 07 nota de credito o 08 Nota de debito-->
                <!-- Tambien puede aceptar un documento 20 (Comprobante de retencion) solo si el mismo es electrónico, fué revertido, y el Comprobante de Retención Electrónico a ser emitido es en reemplazo del revertido. -->
                <xsl:variable name="tipoDocumentoRel" select="cbc:ID/@schemeID"/>
                
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2691'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2692'"/>
                    <xsl:with-param name="node" select="$tipoDocumentoRel"/>
                    <xsl:with-param name="regexp" select="'^(01|12|07|08|20)$'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                </xsl:call-template>
                
                <!-- Numero de documento Relacionado, conformado por la serie y numero -->
                <xsl:variable name="numeroDocumentoRel" select="cbc:ID"/>

                <!--
                Validaciones para la serie:
                    - Si es electrónico con series E001, FNNN debe ser válido, donde N es alfanumérico.
                    - Si es serie numérica NNNN (comprobante físico) debe estar autorizado por SUNAT.
                    - Si es ticket, debe ser alfanumérico hasta 20 posiciones.
                
                    Si es un Comprobante de Percepción Revertido.
                    - Series E001 o RNNN debe ser válido, donde N es alfanumérico.
                    
                Validaciones para la numeración:
                    - Hasta 8 dígitos si tipo de comprobante relacionado es 01, 07, 08, 40.
                    - Hasta 20 dígitos si tipo de comprobante relacionado es 12.
                -->
                <xsl:choose>
                    <xsl:when test="$tipoDocumentoRel = '12'">
                        <!-- 20 caracteres alfanumericos incluido el guion opcional el correlativo de 20 numeros -->
                        <xsl:call-template name="existAndRegexpValidateElement">
                            <xsl:with-param name="errorCodeNotExist" select="'2693'"/>
                            <xsl:with-param name="errorCodeValidate" select="'2694'"/>
                            <xsl:with-param name="node" select="$numeroDocumentoRel"/>
                            <!-- Versión 5 excel-->
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
                            <!-- <xsl:with-param name="regexp" select="'^(E001|((F|R)[A-Z0-9]{3})|((?!(^0{4}))\d{4}))-(?!0+$)([0-9]{1,8})$'"/> -->
                            <xsl:with-param name="regexp" select="'^(E001|((F|R)[A-Z0-9]{3})|(\d{4}))-(?!0+$)([0-9]{1,8})$'"/>
                            <!-- Fin PAS20181U210300134 -->
                            <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
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

            <!-- Los tags de los datos de pago y datos de la retención serán C cuando el tag $tipoDocumentoRel sea igual a 07 (Nota de crédito) -->
            <xsl:if test="$tipoDocumentoRel != '07'">
                
                <!-- Ini Datos del Pago -->
            
                    <!-- Numero de pago -->
                    <xsl:variable name="numeroPago" select="cac:Payment/cbc:ID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2733'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2734'"/>
                        <xsl:with-param name="node" select="$numeroPago"/>
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
                
                    <!-- Importe del pago -->
                    <xsl:variable name="importePago" select="cac:Payment/cbc:PaidAmount"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2735'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2736'"/>
                        <xsl:with-param name="node" select="$importePago"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda de pago, debe ser la misma que la del documento relacionado -->
                    <xsl:variable name="monedaImportePago" select="cac:Payment/cbc:PaidAmount/@currencyID"/>
                    
                    <xsl:if test="$monedaImporteTotalDocumentoRel != $monedaImportePago">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="'2622'" />
                            <xsl:with-param name="errorMessage" select="concat('Error en la linea', position())" />
                        </xsl:call-template>
                    </xsl:if>
                    
                    <!-- Fecha de pago -->
                    <xsl:variable name="fechaPago" select="cac:Payment/cbc:PaidDate"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2737'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2738'"/>
                        <xsl:with-param name="node" select="$fechaPago"/>
                        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>

                <!-- Fin Datos del Pago -->

                
                <!-- Ini Datos de la Retencion -->
                
                    <!-- Importe retenido -->
                    <xsl:variable name="importeRetenido" select="sac:SUNATRetentionInformation/sac:SUNATRetentionAmount"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2739'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2740'"/>
                        <xsl:with-param name="node" select="$importeRetenido"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda de importe retenido -->
                    <xsl:variable name="monedaImporteRetenido" select="sac:SUNATRetentionInformation/sac:SUNATRetentionAmount/@currencyID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2741'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2742'"/>
                        <xsl:with-param name="node" select="$monedaImporteRetenido"/>
                        <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>
                
                    <!-- Fecha de Retencion -->
                    <xsl:variable name="fechaRetencion" select="sac:SUNATRetentionInformation/sac:SUNATRetentionDate"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2743'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2744'"/>
                        <xsl:with-param name="node" select="$fechaRetencion"/>
                        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea ', position())"/>
                    </xsl:call-template>
                    
                    <!-- Importe total a pagar (neto) -->
                    <xsl:variable name="importeTotalACobrar" select="sac:SUNATRetentionInformation/sac:SUNATNetTotalPaid"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2745'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2746'"/>
                        <xsl:with-param name="node" select="$importeTotalACobrar"/>
                        <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,2})?$)'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>
                    
                    <!-- Moneda del monto neto pagado -->
                    <xsl:variable name="monedaImporteTotalACobrar" select="sac:SUNATRetentionInformation/sac:SUNATNetTotalPaid/@currencyID"/>
                    
                    <xsl:call-template name="existAndRegexpValidateElement">
                        <xsl:with-param name="errorCodeNotExist" select="'2747'"/>
                        <xsl:with-param name="errorCodeValidate" select="'2748'"/>
                        <xsl:with-param name="node" select="$monedaImporteTotalACobrar"/>
                        <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                        <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                    </xsl:call-template>

                <!-- Fin Datos de la Retencion -->

                
                <!-- Ini Tipo de cambio -->
                    
                    <xsl:choose>
                        
                        <xsl:when test="$monedaImporteTotalDocumentoRel = 'PEN'">
                        
                            <!-- La moneda de referencia para el Tipo de Cambio -->
                            <xsl:variable name="monedaReferenciaTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:SourceCurrencyCode"/>
                            
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
                            <xsl:variable name="monedaPENTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:TargetCurrencyCode"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2715'"/>
                                <xsl:with-param name="node" select="$monedaPENTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                        
                            <!-- Tipo de cambio -->
                            <xsl:variable name="importeTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:CalculationRate"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2716'"/>
                                <xsl:with-param name="node" select="$importeTipoCambio"/>
                                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,4}(\.\d{1,6})?$)'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- Fecha de cambio -->
                            <xsl:variable name="fechaTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:Date"/>
                            
                            <xsl:call-template name="regexpValidateElementIfExist">
                                <xsl:with-param name="errorCodeValidate" select="'2717'"/>
                                <xsl:with-param name="node" select="$fechaTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                        </xsl:when>
                        <xsl:otherwise>
                        
                            <!-- La moneda de referencia para el Tipo de Cambio -->
                            <xsl:variable name="monedaReferenciaTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:SourceCurrencyCode"/>
                            
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
                            <xsl:variable name="monedaPENTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:TargetCurrencyCode"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2720'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2715'"/>
                                <xsl:with-param name="node" select="$monedaPENTipoCambio"/>
                                <xsl:with-param name="regexp" select="'^(PEN)$'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                        
                            <!-- Tipo de cambio -->
                            <xsl:variable name="importeTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:CalculationRate"/>
                            
                            <xsl:call-template name="existAndRegexpValidateElement">
                                <xsl:with-param name="errorCodeNotExist" select="'2721'"/>
                                <xsl:with-param name="errorCodeValidate" select="'2716'"/>
                                <xsl:with-param name="node" select="$importeTipoCambio"/>
                                <xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,4}(\.\d{1,6})?$)'"/>
                                <xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
                            </xsl:call-template>
                            
                            <!-- Fecha de cambio -->
                            <xsl:variable name="fechaTipoCambio" select="sac:SUNATRetentionInformation/cac:ExchangeRate/cbc:Date"/>
                            
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