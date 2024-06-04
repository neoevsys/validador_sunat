<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:regexp="http://exslt.org/regular-expressions" 
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions" 
	xmlns:func="http://exslt.org/functions" 
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2" 
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#" 
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" 
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" 
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" 
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
    <!-- <xsl:include href="../../../../commons/error/validate_utils.xsl" dp:ignore-multiple="yes" /> -->
	<!-- <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />  -->
	
	<!-- <xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" /> -->
	<xsl:include href="sunat_archivos/sfs/VALI/commons/error/validate_utils.xsl"
               dp:ignore-multiple="yes"/>
			   
    <!-- key de Datos del documento que se modifica  -->
    <xsl:key name="by-Billingreference" match="cac:BillingReference/cac:InvoiceDocumentReference" use="concat(cbc:DocumentTypeCode, cbc:ID)"/>
	
	<!--Excel v6 PAS20211U210400011 JRGS-->
	<!-- key para controlar que todos los documentos modificados sean del mismo tipo -->
    <xsl:key name="by-Billingreference-tipodoc" match="cac:BillingReference/cac:InvoiceDocumentReference" use="cbc:DocumentTypeCode"/>
	
	<!-- key Tipo y número de la guía de remisión relacionada -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='CreditNote']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode, ' ', cbc:ID)"/>
	
	<!-- key Tipo y número de otro documento relacionado -->
	<xsl:key name="by-document-additional-reference" match="*[local-name()='CreditNote']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode, ' ', cbc:ID)"/>
	
	<!-- key Código de tributo - cabecera -->
	<xsl:key name="by-codigo-tributo-cabecera-reference" match="*[local-name()='CreditNote']/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-')"/>
	
	<!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-creditNoteLine-id" match="*[local-name()='CreditNote']/cac:CreditNoteLine" use="number(cbc:ID)"/>
	
	<!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>

	<!-- MIGE-Factoring JRGS-->
	<!-- key identificador de forma de pago duplicadas -->
	<xsl:key name="by-cuotas-in-root" match="*[local-name()='CreditNote']/cac:PaymentTerms[cbc:ID[text() = 'FormaPago']]" use="cbc:PaymentMeansID"/>
	
	<xsl:param name="nombreArchivoEnviado"/>
	<xsl:template match="/*">
    
        <!-- 
        ===========================================================================================================================================
        Ini Variables  
        ===========================================================================================================================================
        -->
        
		<!-- INI SOLO_PRUEBAS -->
		<!-- <xsl:variable name="fileName" select="'20480072872-07-FG99-3061.xml'"/>
		<xsl:variable name="numeroRuc" select="substring($fileName, 1, 11)"/>
		<xsl:variable name="numeroSerie" select="substring($fileName, 16, 4)"/>
		<xsl:variable name="numeroComprobante" select="substring($fileName, 21, string-length($fileName) - 24)"/> -->
		
		<!-- <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
		
		<xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/> -->
		
		<!-- INICIO SFS -->
    <xsl:variable name="numeroRuc"
                  select="substring($nombreArchivoEnviado, 1, 11)"/>
    <xsl:variable name="tipoComprobante"
                  select="substring($nombreArchivoEnviado, 13, 2)"/>
    <xsl:variable name="numeroSerie"
                  select="substring($nombreArchivoEnviado, 16, 4)"/>
    <xsl:variable name="numeroComprobante"
                  select="substring($nombreArchivoEnviado, 21, string-length($nombreArchivoEnviado) - 24)"/>
    <!-- FIN SFS -->
		
		<!-- FIN SOLO_PRUEBAS -->
        
        <xsl:variable name="tipoComprobante">
            <xsl:choose>
                <xsl:when test="substring($numeroSerie, 1, 1) = 'F' ">
                    <xsl:value-of select="'01'"/>
                </xsl:when>
                <xsl:when test="substring($numeroSerie, 1, 1) = 'S' ">
                    <xsl:value-of select="'14'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'03'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		<xsl:variable name="monedaComprobante" select="cbc:DocumentCurrencyCode/text()"/>
		
		
        <xsl:variable name="sumatoriaIGV">
            <xsl:choose>
				<xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="sumatoriaIVAP">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="sumatoriaISC">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="sumMontoTotalImpuestos" select="number($sumatoriaIGV) + number($sumatoriaIVAP) + number($sumatoriaISC)"/>
		
		<!-- Excel v6 PAS20211U210400011 JRGS-->
		<xsl:variable name="tipdocAfectado" select="cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/text()"/>
		
		<!-- 
        ===========================================================================================================================================
        Fin Variables  
        ===========================================================================================================================================
        -->
		
        
		<!-- 
        ===========================================================================================================================================
        Ini Datos de la Nota de credito  
        ===========================================================================================================================================
        -->
        
        <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template>
        
        <!-- Numero de Serie del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1035'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroSerie != substring(cbc:ID, 1, 4)" />
        </xsl:call-template>
        
        <!-- Numero de documento en el nombre del archivo no coincide con el consignado en el contenido del XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1036'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroComprobante != substring(cbc:ID, 6)" />
        </xsl:call-template>
    
        <!-- /CreditNote/cbc:UBLVersionID No existe el Tag UBL o es vacío
        ERROR 2075 -->
        
        <!-- /CreditNote/cbc:UBLVersionID El valor del Tag UBL es diferente de "2.1"
        ERROR 2074 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.1)$'"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cbc:CustomizationID No existe el Tag UBL o es vacío
        ERROR 2073 -->
        
        <!-- /CreditNote/cbc:CustomizationID El valor del Tag UBL es diferente de "2.0"
        ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2073'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4250'"/>
			<xsl:with-param name="node" select="cbc:CustomizationID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        
        <!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<!-- Pase126 Contingencia js 260718 <xsl:with-param name="regexp" select="'^[FBS][A-Z0-9]{3}-[0-9]{1,8}?$'"/> -->
			<xsl:with-param name="regexp" select="'^([FBS][A-Z0-9]{3}|[0-9]{4})-[0-9]{1,8}?$'"/>			
		</xsl:call-template>
		
		<!-- /CreditNote/cac:DiscrepancyResponse Existe más de un Tag UBL en el /CreditNote
        ERROR 2415 -->
        <!-- TODO para confirmar
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2415'" />
            <xsl:with-param name="node" select="cac:DiscrepancyResponse" />
            <xsl:with-param name="expresion" select="count(cac:DiscrepancyResponse)>1" />
        </xsl:call-template>
		-->
        
        <!-- /CreditNote/cac:DiscrepancyResponse/cbc:ResponseCode No existe el Tag UBL o es vacío
        ERROR 2128 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2128'"/>
            <xsl:with-param name="errorCodeValidate" select="'2128'"/>
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[^\s].*)$'"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:DiscrepancyResponse/cbc:ResponseCode El Tag UBL no existe en el listado
        ERROR 2172 -->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'09'"/>
            <xsl:with-param name="idCatalogo" select="cac:DiscrepancyResponse/cbc:ResponseCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2172'"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3203'" />
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode" />
            <xsl:with-param name="expresion" select="count(cac:DiscrepancyResponse/cbc:ResponseCode) &gt; 1" />
        </xsl:call-template>
		
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de nota de credito)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <!-- /CreditNote/cac:DiscrepancyResponse/cbc:Description No existe el Tag UBL o es vacío
        ERROR 2136 -->
        
        <!-- /CreditNote/cac:DiscrepancyResponse/cbc:Description El formato del Tag UBL es diferente a alfanumérico de 1 hasta 500 caracteres (se considera cualquier carácter excepto salto de línea.)
        ERROR 2135 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2136'"/>
            <xsl:with-param name="errorCodeValidate" select="'2135'"/>
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:Description"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,499}$'"/>
        </xsl:call-template>
        
		<!-- /CreditNote/cbc:DocumentCurrencyCode No existe el Tag UBL o es vacío
        ERROR 2070 -->
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode"/>
		</xsl:call-template>
        
        <!-- /CreditNote/cbc:DocumentCurrencyCode Si el Tag UBL existe, el valor del Tag UBL no existe en el listado
        ERROR 3088 -->
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cbc:DocumentCurrencyCode"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
        
        <!-- /CreditNote/cbc:DocumentCurrencyCode La moneda de los totales de línea y totales de comprobantes es diferente al valor del Tag UBL
        ERROR 2071 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)]" />
        </xsl:call-template>
		
		<!--Versión 5 excel -->
		<!-- /CreditNote/cac:DiscrepancyResponse/cbc:ResponseCode Si tipo de nota de credito es diferente de 10-Otros, y NO existe un tag /CreditNote/cac:BillingReference/
		ERROR 2524 -->
		<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode != '10'">
			<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'2524'"/>
				<xsl:with-param name="node" select="cac:BillingReference"/>
			</xsl:call-template>
		</xsl:if>
		<!-- MIGE-Factoring JRGS-->
		<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode = '13'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3261'" />
				<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:BillingReference/cac:InvoiceDocumentReference) &gt; 1" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3257'" />
				<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:PaymentTerms/cbc:ID[text() = 'FormaPago']) &lt; 1" />
			</xsl:call-template>
		</xsl:if>
        
		<!-- 
        ===========================================================================================================================================
        Fin Datos de la Nota de credito  
        ===========================================================================================================================================
        -->
		
        
		
		<!-- Ini Datos del Emisor -->        
        <xsl:apply-templates select="cac:AccountingSupplierParty">
			<!-- Excel v6 PAS20211U210400011 - Se agregan parametros-->
			<xsl:with-param name="tipdocAfectado" select="$tipdocAfectado"/>
			<xsl:with-param name="root" select="."/>
        </xsl:apply-templates> 
        <!-- Fin Datos del Emisor --> 
        
		<!-- Ini Datos del ciente o receptor -->
        
        <xsl:apply-templates select="cac:AccountingCustomerParty"/>
        
        <!-- Fin Datos del ciente o receptor --> 
		
		
		<!-- Ini Datos del documento que se modifica  -->
        <xsl:apply-templates select="cac:BillingReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del documento que se modifica  --> 
		
		
		<!-- Ini Datos del Tipo y número de la guía de remisión relacionada  -->
        <xsl:apply-templates select="cac:DespatchDocumentReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del Tipo y número de la guía de remisión relacionada  --> 
	   
		
		<!-- Ini Datos del Tipo y número de otro documento relacionado  -->
        <xsl:apply-templates select="cac:AdditionalDocumentReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del Tipo y número de otro documento relacionado  -->
		
		<!-- MIGE JRGS- Ini Datos de cuotas -->
		<xsl:apply-templates select="cac:PaymentTerms">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
		<!-- Fin Datos cuotas  -->
		 
	   	<xsl:call-template name="existElement">
	        <xsl:with-param name="errorCodeNotExist" select="'2956'" />
	        <xsl:with-param name="node" select="cac:TaxTotal" />
	    </xsl:call-template>
	   
		<!-- Ini Totales de la Nota de Crédito -->
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
			<xsl:with-param name="sumMontoTotalImpuestos" select="$sumMontoTotalImpuestos"/>
        </xsl:apply-templates>
		
		<!-- Fin Totales de la Nota de Crédito -->
		
		
		<!-- Ini Totales/subTotales de la Nota de Crédito -->
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
			<!--<xsl:with-param name="sumMontoTotalImpuestos" select="$sumMontoTotalImpuestos"/>-->
        </xsl:apply-templates>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4314'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &gt; 1 or cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &lt; -1" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4315'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID != $monedaComprobante" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- Fin Totales/subTotales de la Nota de Crédito -->
		
		<!--PAS20221U210700304 - MSD INICIO - 3462 y 4438-->
        <xsl:variable name="igv10" select="count(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[
		cac:TaxCategory/cbc:Percent = 10.0 and 
		((cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'] and cbc:TaxableAmount &gt; 0) or
		(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0 and 
		cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16']))
		])"/>
        
        <xsl:variable name="igv18" select="count(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[
		cac:TaxCategory/cbc:Percent = 18.0 and
		((cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'] and cbc:TaxableAmount &gt; 0) or 
		(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0 and 
		cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16']))
		])"/>
		
		<xsl:variable name="igvX" select="count(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[
		cac:TaxCategory/cbc:Percent != 18.0 and cac:TaxCategory/cbc:Percent != 10.0 and
		((cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'] and cbc:TaxableAmount &gt; 0) or 
		(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0 and 
		cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16']))
		])"/>
		
		<xsl:variable name="sumatoriaIndicador1" select="sum(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
		<xsl:variable name="sumatoriaIndicador2" select="sum(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16']]/cbc:TaxableAmount)"/>

        <xsl:if test="($sumatoriaIndicador1 > 0) or ($sumatoriaIndicador2 > 0)">
	        <xsl:choose>
	          <xsl:when test="cac:BillingReference/cac:InvoiceDocumentReference[cbc:DocumentTypeCode[text() = '01']]">        
	             <xsl:call-template name="isTrueExpresionEmptyNode">
		            <xsl:with-param name="errorCodeValidate" select="'3462'" />
		            <xsl:with-param name="expresion" select="(($igv10 > 0) and ($igv18 > 0)) or (($igv10 = 0) and ($igv18 = 0)) or ($igvX > 0)" />
		        </xsl:call-template>
	          </xsl:when>
	          <xsl:otherwise>
	             <xsl:call-template name="isTrueExpresionEmptyNode">
		            <xsl:with-param name="errorCodeValidate" select="'3462'" />
		            <xsl:with-param name="expresion" select="(($igv10 > 0) and ($igv18 > 0)) or (($igv10 = 0) and ($igv18 = 0)) or ($igvX > 0)" />
		        </xsl:call-template>
	          </xsl:otherwise>
	       </xsl:choose>
        </xsl:if>
        <!--PAS20221U210700304 - MSD FIN-->
		
        <xsl:variable name="totalCargos" select="sum(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount)"/>
       	
       	<xsl:variable name="totalPrecioVenta" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]/cbc:TaxableAmount)"/>
        
        <xsl:variable name="totalImporte" select="sum(cac:LegalMonetaryTotal/cbc:PayableAmount)"/>
        <xsl:variable name="totalRedondeo" select="sum(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)"/>        
        
        <xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
		
		<!--Antonio-->
        <xsl:variable name="SumatoriaICBPER" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount)"/>
        <xsl:variable name="MontoBaseICBPER" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount"/>		
        <xsl:variable name="MontoBaseICBPERLinea" select="sum(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount)"/>	
		
        <xsl:variable name="SumatoriaIVAP" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount)" />
        <xsl:variable name="SumatoriaISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
        
        
        <xsl:variable name="MontoBaseIGVLinea" select="sum(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoBaseIVAPLinea" select="sum(cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
               	
       	<!--PAS20221U210700304 - MSD INICIO - Comentamos la operación de restas-->	
       	<!-- <xsl:variable name="SumatoriaIGVCalculado" select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18"/>-->
       	<!--PAS20221U210700304 - MSD FIN-->
		
		<!--PAS20221U210700304 - MSD INICIO - Incorporación de tasas IGV 10% y 18%-->
       	<xsl:variable name="TasaPercent">
            <xsl:choose>
               <xsl:when test="cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:Percent and cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000']/cbc:TaxableAmount &gt; 0">
                 <xsl:value-of select="cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:Percent div 100" />
               </xsl:when>
               <xsl:otherwise>
                 <xsl:text>0</xsl:text>
               </xsl:otherwise>
             </xsl:choose>
        </xsl:variable>
       	
        <xsl:variable name="sumatoriaIGVCalculado18" select="$MontoBaseIGVLinea * 0.18"/>
        <xsl:variable name="sumatoriaIGVCalculado10" select="$MontoBaseIGVLinea * 0.10"/>
		
		<xsl:variable name="sumatoriaFinal">
			<xsl:choose>
				<xsl:when test="$TasaPercent = 0.18">
					<xsl:value-of select="$sumatoriaIGVCalculado18"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$sumatoriaIGVCalculado10"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="indicadorError18">
		    <xsl:choose>
		        <xsl:when test="($SumatoriaIGV + 1 ) &lt; $sumatoriaIGVCalculado18 or ($SumatoriaIGV - 1) &gt; $sumatoriaIGVCalculado18">
		            <xsl:value-of select="1"/>
		        </xsl:when>
		        <xsl:otherwise>
		            <xsl:value-of select="'0'"/>
		        </xsl:otherwise>
		    </xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="indicadorError10">
			<xsl:choose>
				<xsl:when test="($SumatoriaIGV + 1 ) &lt; $sumatoriaIGVCalculado10 or ($SumatoriaIGV - 1) &gt; $sumatoriaIGVCalculado10">
					<xsl:value-of select="1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'0'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>	       	
        <!--PAS20221U210700304 - MSD FIN-->
			
       	<!--PAS20221U210700304 - MSD INICIO - Comentamos la operación de restas a operación vigente para 3295 y 4302-->
       	<!-- <xsl:variable name="SumatoriaIVAPCalculado" select="($MontoBaseIVAPLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.04"/>-->
       	<xsl:variable name="SumatoriaIVAPCalculado" select="$MontoBaseIVAPLinea * 0.04"/>
       	<!--PAS20221U210700304 - MSD FIN-->
       	
		<!-- Antonio -->
		<xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta + $SumatoriaIGV + $SumatoriaICBPER + $SumatoriaISC + $SumatoriaIVAP +$SumatoriaOtrosTributos + $totalCargos + $totalRedondeo"/>
     
		<!-- Antonio -->
		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4321'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="$MontoBaseICBPER != $MontoBaseICBPERLinea" />
				<xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
		
		<!--PAS20221U210700304 - MSD INICIO - Se incorpora 3291 y se actualiza 4290 para validar tasas 18% y 10%-->
		<xsl:variable name="validacionIndicadores" select="not($indicadorError18 &gt; 0 and $indicadorError10 = 0) and not($indicadorError18 = 0 and $indicadorError10 &gt; 0) and not($indicadorError18 = 0 and $indicadorError10 = 0)"/>
		
		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
		   <xsl:choose>
			  <xsl:when test="cac:BillingReference/cac:InvoiceDocumentReference[cbc:DocumentTypeCode[text() = '01']]">        
				   <xsl:call-template name="isTrueExpresion">
					  <xsl:with-param name="errorCodeValidate" select="'3291'" />
					  <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
					  <xsl:with-param name="expresion" select="$validacionIndicadores ='true'" />
				   </xsl:call-template>
				   <xsl:call-template name="isTrueExpresion">
					  <xsl:with-param name="errorCodeValidate" select="'3291'" />
					  <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
					  <xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $sumatoriaFinal or ($SumatoriaIGV - 1) &gt; $sumatoriaFinal" />
				   </xsl:call-template>
			  </xsl:when>
			  <xsl:otherwise>
				  <xsl:if test="$validacionIndicadores ='true'">
						<xsl:call-template name="isTrueExpresion">
						   <xsl:with-param name="errorCodeValidate" select="'4290'" />
						   <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
						   <xsl:with-param name="expresion" select="$validacionIndicadores ='true'" />
						   <xsl:with-param name="isError" select ="false()"/>
						</xsl:call-template>
					</xsl:if>
			  </xsl:otherwise>
		   </xsl:choose>
		</xsl:if>
		<!--PAS20221U210700304 - MSD FIN-->
     
       	<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]">
			   <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4302'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($SumatoriaIVAP + 1 ) &lt; $SumatoriaIVAPCalculado or ($SumatoriaIVAP - 1) &gt; $SumatoriaIVAPCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4312'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="($totalImporte + 1 ) &lt; $totalImporteCalculado or ($totalImporte - 1) &gt; $totalImporteCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode = '13'">
     	 <xsl:call-template name="isTrueExpresion">
		      <xsl:with-param name="errorCodeValidate" select="'3315'" />
		      <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
		      <xsl:with-param name="expresion" select="$totalImporte != 0" />
       </xsl:call-template>
	  </xsl:if>	
		
		<!-- /CreditNote/cac:LegalMonetaryTotal/cbc:ChargeTotalAmount  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR   2065
        -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <!-- <xsl:with-param name="errorCodeNotExist" select="'2065'"/> -->
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:RequestedMonetaryTotal/cbc:AllowanceTotalAmount  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR   2064
        -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <!-- <xsl:with-param name="errorCodeNotExist" select="'2064'"/> -->
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR   2064
        -->
        <!-- Ini PAS20181U210300115 --> 
        <!-- <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2064'"/>
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template> -->
        <!-- Fin PAS20181U210300115 --> 
        
        <!-- /CreditNote/cac:LegalMonetaryTotal/cbc:PayableAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR   2062
         -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/> 
        </xsl:call-template>
        
		

		<xsl:apply-templates select="cbc:Note"/>

		<!-- Ini Datos del detalle o Ítem de la Nota de Crédito  -->
		
		<xsl:apply-templates select="cac:CreditNoteLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
		
		<!-- Fin Datos del detalle o Ítem de la Nota de Crédito  -->
 
 
        <!-- Retornamos el comprobante al flujo necesario para lotes -->
        <xsl:copy-of select="."/>
        
    </xsl:template>
        
		
	<!-- 
    ===========================================================================================================================================
    *******************************************************************************************************************************************
                                                       TEMPLATES
    *******************************************************************************************************************************************
    ===========================================================================================================================================
    -->
	
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cbc:Note =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cbc:Note">
		
		<xsl:if test="@languageLocaleID">    
            <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'"/>
				<xsl:with-param name="idCatalogo" select="@languageLocaleID"/>
				<xsl:with-param name="catalogo" select="'52'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="existAndRegexpValidateElement">
        	<xsl:with-param name="errorCodeNotExist" select="'3006'"/>
			<xsl:with-param name="errorCodeValidate" select="'3006'"/>
			<xsl:with-param name="node" select="text()"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,199}$'"/>
			<xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
		</xsl:call-template>
       
	</xsl:template>
    
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AccountingSupplierParty
	===========================================================================================================================================
	--> 
	
    <xsl:template match="cac:AccountingSupplierParty">
    
        <!-- Excel v6 PAS20211U210400011 JRGS - Se agregan parametros-->
    	<xsl:param name="tipdocAfectado" select = "'-'" />
		<xsl:param name="root"/>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID No existe el Tag UBL o es vacío
        ERROR 2676 -->
        <!-- Ini PAS20181U210300115 --> 
		<!-- <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2676'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		</xsl:call-template> -->
		<!-- Fin PAS20181U210300115 --> 
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeID No existe el Tag UBL o es vacío
        ERROR 3029 -->
		<!-- CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeID El Tag UBL es diferente a "6"
        ERROR 2511 -->
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'3029'"/>
            <xsl:with-param name="errorCodeValidate" select="'2511'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeName Si existe el tag, el valor ingresado es diferente a 'Documento de Identidad' 
		OBSERVACION 4255 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT'
		OBSERVACION 4256 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06' 
		OBSERVACION 4257 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name El valor del tag es mayor al formato establecido 
		OBSERVACION 4092 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4092'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 1037 -->
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres  (se considera cualquier carácter excepto salto de línea)
        ERROR 1038 -->
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'1037'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4338'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4338'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 1500 or string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 2 " />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:RegistrationName ', cbc:RegistrationName)"/>
        </xsl:call-template>
		
		
        <!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line El formato del Tag UBL es diferente a alfanumérico de 3 a 200 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea) 
		OBSERVACION 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName El formato del Tag UBL es diferente a alfanumérico de 1 a 25 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,24}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID Si el Tag UBL existe, el valor del Tag UBL debe estar en el listado 
		OBSERVACION 4093 -->
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4093'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:INEI' 
		OBSERVACION 4256 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName Si existe el atributo, el valor ingresado es diferente a 'Ubigeos' 
		OBSERVACION 4255 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:Distric El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4098 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode Si el Tag UBL existe, el valor del Tag UBL es diferente a PE
		OBSERVACION 4041 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID Si existe el tag, el valor ingresado es diferente a 'ISO 3166-1'
		OBSERVACION 4254 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName Si existe el tag, el valor ingresado es diferente a 'United Nations Economic Commission for Europe'
		OBSERVACION 4251 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName Si existe el tag, el valor ingresado es diferente a 'Country'
		OBSERVACION 4252 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- Excel v6 PAS20211U210400011 JRGS - Validaciones de codigo de establecimiento Anexo -->
		<xsl:if test="substring($root/cbc:ID, 1, 1) = 'F' and $tipdocAfectado = '01'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3030'"/>
				<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
				<!-- PAS115 Se cambio a observación a solicitud de MICHAEL RUIZ  -->
				<!-- Excel v6 vuelve a pasar a error -->
				<!--xsl:with-param name="isError" select ="false()"/-->
			</xsl:call-template>
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3239'"/>
				<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
				<xsl:with-param name="regexp" select="'^[0-9]{1,}$'"/> <!-- numerico de hasta 4 dígitos -->
			</xsl:call-template>        
		</xsl:if>

		<xsl:if test="substring($root/cbc:ID, 1, 1) != 'F' or $tipdocAfectado != '01' ">
			<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4198'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
			<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

			<xsl:if test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode != ''">
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4199'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
					<xsl:with-param name="regexp" select="'^[0-9]{1,}$'"/> <!-- numerico -->
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
			</xsl:if>            
		</xsl:if>	
		
		<xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4242'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}$'"/> <!-- de 4 dígitoso -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Establecimientos anexos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
    </xsl:template>
    
    <!-- 
	===========================================================================================================================================
	Fin Template cac:AccountingSupplierParty
	===========================================================================================================================================
	--> 
    
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AccountingCustomerParty
	===========================================================================================================================================
	--> 
   
	<xsl:template match="cac:AccountingCustomerParty">
        
        <!-- numero de documento -->
        <!--<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>-->
        
        <!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID No existe el Tag UBL o es vacío
        ERROR 2679 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2679'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID Si "Tipo de documento de identidad del adquiriente" es RUC (6), el formato del Tag UBL es diferente a numérico de 11 dígitos
        ERROR 2017 -->
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">
            <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
         </xsl:call-template>
        </xsl:if>
		
		<!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID No existe el Tag UBL o es vacío
        ERROR 2679 -->
        <!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID El Tag UBL es diferente al listado
        ERROR 2016 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2679'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
	
		<!--<xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">-->
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'2016'"/>
				<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
				<xsl:with-param name="catalogo" select="'06'"/>
			</xsl:call-template>
		<!--</xsl:if>-->
		
		<!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName
		OBSERVACION 4255 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName
		OBSERVACION 4256 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI
		OBSERVACION 4257 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 2021 -->
        <!-- /CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres (se considera cualquier carácter excepto salto de línea)
        ERROR 2022 --> 
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,999}$'"/>
        </xsl:call-template>
        
    </xsl:template>
	<!-- 
	===========================================================================================================================================
	Fin Template cac:AccountingCustomerParty
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:BillingReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:BillingReference">
		<xsl:param name="root" select = "'-'" />
		
		<!-- /CreditNote/cac:DiscrepancyResponse/cbc:ResponseCode Si tipo de nota de credito es 11 Ajustes de operaciones de exportación, y existe mas de un tag /CreditNote/cac:BillingReference/
        ERROR 3194 -->
        <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3194'" />
				<xsl:with-param name="node" select="$root/cac:BillingReference" />
				<xsl:with-param name="expresion" select="count($root/cac:BillingReference) &gt; 1" />
			</xsl:call-template>
        </xsl:if>
		
		<!--Versión 5 excel -->
		<!-- /CreditNote/cac:DiscrepancyResponse/cbc:ResponseCode Si tipo de nota de credito es diferente de 10-Otros, y NO existe un tag /CreditNote/cac:BillingReference/
		ERROR 2524 -->
		<xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode != '10'">
			<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'2524'"/>
				<xsl:with-param name="node" select="cac:InvoiceDocumentReference"/>
			</xsl:call-template>
		</xsl:if>	

		<!-- MIGE-Factoring JRGS-->
		<xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '13'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3259'" />
				<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
				<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '01'" />
			</xsl:call-template>
		</xsl:if>		
        <!--<xsl:choose>-->
		
			<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de crédito" es "10" (Otros conceptos) el formato del tag UBL puede ser, vacío ó:
			- [F][A-Z0-9]{3}-[0-9]{1,8}
			- (E001)-[0-9]{1,8}
			- [0-9]{1,4}-[0-9]{1,8}
			- [B][A-Z0-9]{3}-[0-9]{1,8}
			- (EB01)-[0-9]{1,8}
			- [S][A-Z0-9]{3}-[0-9]{1,8}
			- [a-zA-Z0-9-]{1,20}-[0-9]{1,10}
			ERROR 2117 -->
			<!--Versión 5 excel -->
			<!--<xsl:when test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '10'">
			
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
					<xsl:with-param name="errorCodeValidate" select="'2117'"/>
					<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
					<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8})|((E001)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([B][A-Z0-9]{3}-[0-9]{1,8})|((EB01)-[0-9]{1,8})|([S][A-Z0-9]{3}-[0-9]{1,8})|([a-zA-Z0-9-]{1,20}-[0-9]{1,10}))$'"/>
				</xsl:call-template>-->
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es igual a"10" (Otros conceptos),  el valor del tag UBL puede ser vacío ó los valores del catálogo 01.
				ERROR 2922 -->
				
					
				<!-- <xsl:call-template name="existElementNoVacio">
					<xsl:with-param name="errorCodeNotExist" select="'2922'"/>
					<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode"/>
				</xsl:call-template>
				-->
				<!--Versión 5 excel -->
				<!--<xsl:if test="string(cac:InvoiceDocumentReference/cbc:DocumentTypeCode)">
					<xsl:call-template name="findElementInCatalog">
						<xsl:with-param name="catalogo" select="'01'"/>
						<xsl:with-param name="idCatalogo" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode"/>
						<xsl:with-param name="errorCodeValidate" select="'2922'"/>
					</xsl:call-template>
				</xsl:if>
			
			
			</xsl:when>
			<xsl:otherwise>-->
			
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la nota crédito modifica a una factura, el formato del Tag UBL es diferente a:
				- [F][A-Z0-9]{3}-[0-9]{1,8}
				- (E001)-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				ERROR 2117 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '01'">
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8})|((E001)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la NC modifica a una boleta de venta (tipo de comprobante =03), y el formato del Tag UBL es diferente a:
				- [B][A-Z0-9]{3}-[0-9]{1,8}
				- (EB01)-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				ERROR 2117 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '03'">
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([B][A-Z0-9]{3}-[0-9]{1,8})|((EB01)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de cédito" es diferente de "10" (Otros conceptos) y la NC modifica a un DAE (tipo de comprobante =14), y el formato del Tag UBL es diferente a:
				- [S][A-Z0-9]{3}-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				- [0-9]{1,8} (Para caso de DAE sin serie)
				ERROR 2117 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '14'">
                
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([S][A-Z0-9]{3}-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de cédito" es diferente de "10" (Otros conceptos) y  "Tipo del documento del documento que modifica" es "12", el formato del Tag UBL es diferente a:
				- [a-zA-Z0-9-]{1,20}-[0-9]{1,10}
				ERROR 2117 -->
				<!--Versión 5 excel -->
				<!--<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '12'">
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^([a-zA-Z0-9-]{1,20}-[0-9]{1,10})$'"/>
					</xsl:call-template>
				</xsl:if>-->
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y Si "Tipo del documento del documento que modifica" es "56", el valor del Tag UBL es diferente a alfanumérico (incluido el guión)
				ERROR 2117 -->
				<!--Versión 5 excel -->
				<!--<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '56'">
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^[\w\d\- ]+$'"/>
					</xsl:call-template>
				</xsl:if> -->
				
				<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si la nota de crédito modifica un Documento autorizado (tipo de comprobante "06","13","16", "37", "43","45","24","15"), la serie de la nota de credito debe iniciar con F y el formato del Tag UBL es diferente a:
				- [0-9]{1,4}-[0-9]{1,8}
				- [A-Z0-9]{1,9}-[A-Z0-9]{1,20}
				ERROR 2117 -->
				<!-- <xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text()='06' or text()='13' or text()='16' or text()='37' or text()='43' or text()='45' or text()='24' or text()='15']"> -->
				<!--Versión 5 excel -->
				<!--<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text()='06' or text()='13' or text()='15' or text()='16' or text()='18' or text()='21' or text()='37' or text()='43' or text()='45' or text()='55']"> -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text()='05' or text()='06' or text()='12' or text()='13' or text()='15' or text()='16' or text()='18' or text()='21' or text()='28' or text()='30' or text()='34' or text()='37' or text()='42' or text()='43' or text()='45' or text()='55' or text()='11' or text()='17' or text()='23' or text()='24' or text()='56']">
				   <!--<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="$root/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8}))$'"/>
				   </xsl:call-template>-->
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
						<xsl:with-param name="errorCodeValidate" select="'2117'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<!-- xsl:with-param name="regexp" select="'^(([0-9]{1,4}-[0-9]{1,8})|([A-Z0-9]{1,20}-[A-Z0-9]{1,20}))$'"/-->
						<xsl:with-param name="regexp" select="'^[a-zA-Z0-9-]{1,20}-[a-zA-Z0-9-]{1,20}$'"/>
					</xsl:call-template>
				</xsl:if>
				<!--Versión 5 excel -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text()='-'] or cac:InvoiceDocumentReference/cbc:DocumentTypeCode=''">
					<xsl:if test="cac:InvoiceDocumentReference/cbc:ID[text() != '']">
						<xsl:call-template name="existAndRegexpValidateElement">
							<xsl:with-param name="errorCodeNotExist" select="'2117'"/>
							<xsl:with-param name="errorCodeValidate" select="'2117'"/>
							<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
							<xsl:with-param name="regexp" select="'^[a-zA-Z0-9-]{1,20}-[a-zA-Z0-9-]{1,20}$'"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
				<!-- /CreditNote/cac:BillingReference/cbc:InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "B", el Tag UBL es diferente de "03"
				ERROR 2399 -->
				<!--Versión 5 excel -->			
				<xsl:choose>
					<xsl:when test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '10'">
						<xsl:if test="substring($root/cbc:ID, 1, 1) = 'B'">
							<xsl:call-template name="isTrueExpresion">
								<xsl:with-param name="errorCodeValidate" select="'2399'" />
								<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
								<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '03'" />
							</xsl:call-template>
						</xsl:if>
						
						<!-- /CreditNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y  la Serie del comprobante empieza con "F", el Tag UBL es diferente de "01", "12", "56"
						ERROR 2116 -->
						<xsl:if test="substring($root/cbc:ID, 1, 1) = 'F'">
							<xsl:call-template name="isTrueExpresion">
								<xsl:with-param name="errorCodeValidate" select="'2116'" />
								<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
								<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text() !='01' and text() !='12' and text() !='56' and text() !='06' and text() !='13' and text() !='15' and text() !='16' and text() !='18' and text() !='21' and text() !='37' and text() !='43' and text() !='45' and text() !='55']" />
							</xsl:call-template>
						</xsl:if>
						
						<!-- /CreditNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "S", el Tag UBL es diferente de "14"
						ERROR 2930 -->
						<xsl:if test="substring($root/cbc:ID, 1, 1) = 'S'">
							<xsl:call-template name="isTrueExpresion">
								<xsl:with-param name="errorCodeValidate" select="'2930'" />
								<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
								<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '14'" />
							</xsl:call-template>
						</xsl:if>
					</xsl:when>
				<xsl:otherwise>
					<!-- /CreditNote/cac:BillingReference/cbc:InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "B", el Tag UBL es diferente de "03"
					ERROR 2399 -->
					<xsl:if test="substring($root/cbc:ID, 1, 1) = 'B'">
						<xsl:call-template name="isTrueExpresion">
							<xsl:with-param name="errorCodeValidate" select="'2399'" />
							<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
							<xsl:with-param name="expresion" select="(cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text() !='03' and text() !='12' and text() !='16' and text() !='55']) or cac:InvoiceDocumentReference/cbc:DocumentTypeCode =''" />
						</xsl:call-template>
					</xsl:if>

					<!-- /CreditNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y  la Serie del comprobante empieza con "F", el Tag UBL es diferente de "01", "12", "56"
					ERROR 2116 -->
					<xsl:if test="substring($root/cbc:ID, 1, 1) = 'F'">
						<xsl:call-template name="isTrueExpresion">
							<xsl:with-param name="errorCodeValidate" select="'2116'" />
							<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
							<xsl:with-param name="expresion" select="(cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text() !='01'and text() !='05' and text() !='06' and text() !='12' and text() !='13' and text() !='15' and text() !='16' and text() !='18' and text() !='21' and text() !='28' and text() !='30' and text() !='34' and text() !='37' and text() !='42' and text() !='43' and text() !='45' and text() !='55' and text() !='11' and text() !='17' and text() !='23' and text() !='24' and text() !='56']) or cac:InvoiceDocumentReference/cbc:DocumentTypeCode =''" />					
						</xsl:call-template>
					</xsl:if>

					<!-- /CreditNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con número:
					ERROR 2594 -->
					<xsl:if test="substring($root/cbc:ID, 1, 1) = '0' or substring($root/cbc:ID, 1, 1) = '1' or substring($root/cbc:ID, 1, 1) = '2' or substring($root/cbc:ID, 1, 1) = '3' or substring($root/cbc:ID, 1, 1) = '4' or substring($root/cbc:ID, 1, 1) = '5' or substring($root/cbc:ID, 1, 1) = '6' or substring($root/cbc:ID, 1, 1) = '7' or substring($root/cbc:ID, 1, 1) = '8' or substring($root/cbc:ID, 1, 1) = '9'">
						<xsl:call-template name="isTrueExpresion">
							<xsl:with-param name="errorCodeValidate" select="'2594'" />
							<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
							<xsl:with-param name="expresion" select="(cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text() !='01'and text() !='03' and text() !='05' and text() !='06' and text() !='12' and text() !='13' and text() !='15' and text() !='16' and text() !='18' and text() !='21' and text() !='28' and text() !='30' and text() !='34' and text() !='37' and text() !='42' and text() !='43' and text() !='45' and text() !='55' and text() !='11' and text() !='17' and text() !='23' and text() !='24' and text() !='56']) or cac:InvoiceDocumentReference/cbc:DocumentTypeCode =''" />					
						</xsl:call-template>
					</xsl:if>

					<!-- /CreditNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "S", el Tag UBL es diferente de "14"
					ERROR 2930 -->
					<xsl:if test="substring($root/cbc:ID, 1, 1) = 'S'">
						<xsl:call-template name="isTrueExpresion">
							<xsl:with-param name="errorCodeValidate" select="'2930'" />
							<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
							<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '14'" />
						</xsl:call-template>
					</xsl:if>                                     				
				</xsl:otherwise>
				</xsl:choose>       
		
        <!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID El "Tipo de documento del documento que modifica" concatenado con el valor del Tag UBL no debe repetirse en el /CreditNote
        ERROR 2365 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2365'" />
            <xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-Billingreference', concat(cac:InvoiceDocumentReference/cbc:DocumentTypeCode, cac:InvoiceDocumentReference/cbc:ID))) &gt; 1" />
        </xsl:call-template>
		
		<!--Excel v6 PAS20211U210400011 JRGS - Se verifica que si hay más de un documento afectado todos sean del mismo tipo-->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2884'" />
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
			<xsl:with-param name="expresion" select="count(key('by-Billingreference-tipodoc', cac:InvoiceDocumentReference/cbc:DocumentTypeCode)) != count($root/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode)" />
		</xsl:call-template>
		
		<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:BillingReference
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:DespatchDocumentReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:DespatchDocumentReference">
    
        <!-- /CreditNote/cac:DespatchDocumentReference/cbc:ID Si el Tag UBL existe, el formato del Tag UBL es diferente a: 
		- [T][0-9]{3}-[0-9]{1,8}
		- [0-9]{4}-[0-9]{1,8}
		- [EG][0-9]{2}-[0-9]{1,8}
		- [G][0-9]{3}-[0-9]{1,8}
        OBSERV 4006 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4006'"/>
            <xsl:with-param name="errorCodeValidate" select="'4006'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <!--xsl:with-param name="regexp" select="'^(([T][0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0-9]{2}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'"/-->
            <xsl:with-param name="regexp" select="'^(([TV][A-Z0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0][1-4,7]{1}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:DespatchDocumentReference/cbc:ID El "Tipo de la guía de remisión relacionada" concatenado con el valor del Tag UBL no debe repetirse en el /CreditNote
        ERROR 2364 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2364'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
        </xsl:call-template>
		
        <!-- /CreditNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode Si existe el Tag UBL, el formato del Tag UBL es diferente de "09" o "31"
        OBSERV 4005 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4005'"/>
            <xsl:with-param name="errorCodeValidate" select="'4005'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(31)|(09)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
    
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:DespatchDocumentReference
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AdditionalDocumentReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:AdditionalDocumentReference">
        <xsl:param name="root" select = "'-'" />
    
        <!-- /CreditNote/cac:AdditionalDocumentReference/cbc:ID El formato del Tag UBL es diferente a alfanumérico de entre 6 y 30 caracteres  (se considera cualquier carácter no permite "whitespace character": espacio, salto de línea, fin de línea, tab, etc.)
        OBSERV 4010 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4010'"/>
            <xsl:with-param name="errorCodeValidate" select="'4010'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{6,30}$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AdditionalDocumentReference/cbc:ID El "Tipo de otro documento relacionado" concatenado con el valor del Tag UBL, no debe repetirse en el /CreditNote
        ERROR 2426 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2426'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AdditionalDocumentReference/cbc:ID Si "Código de tipo de nota de crédito" es diferente de 10 (Otros) y "Tipo de otro documento relacionado" es 99, el Tag UBL es vacío
        OBSERV 2636 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2636'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode != '10' and cbc:DocumentTypeCode ='99' and not(string(cbc:ID))" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es 10 (Otros), existe más de un Tag UBL igual a "99"
        OBSERV 2635 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2635'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '10' and count($root/cac:AdditionalDocumentReference/cbc:DocumentTypeCode[text()='99']) &gt; 1" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de crédito" es  10 (Otros) y "Tipo de otro documento relacionado"es 99, no existe el Tag UBL o es vacío
        OBSERV 2637 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2637'" />
            <xsl:with-param name="node" select="cbc:DocumentTypeCode" />
            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '10' and cbc:DocumentTypeCode !='99'" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
        <!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode El formato del Tag UBL es diferente de "04" o "05" o "99" o "01"
        ERROR 4009 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
            <xsl:with-param name="errorCodeValidate" select="'4009'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(0[145]|99)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@listName Si existe el tag, el valor ingresado es diferente a 'Documentos Relacionados' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Documento Relacionado)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@listAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@listURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:AdditionalDocumentReference
	===========================================================================================================================================
	--> 
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:PaymentTerms
	===========================================================================================================================================
	-->  
    <xsl:template match="cac:PaymentTerms">
		<xsl:param name="root"/>
	
		<!-- MIGE-Factoring JRGS-->
		<xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '13'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3261'" />
				<xsl:with-param name="node" select="cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:BillingReference/cac:InvoiceDocumentReference) &gt; 1" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3257'" />
				<xsl:with-param name="node" select="cbc:ID" />
				<xsl:with-param name="expresion" select="count(cbc:ID[text() = 'FormaPago']) &lt; 1" />
				<xsl:with-param name="descripcion" select="concat('Error en:::::::::: ', cbc:PaymentMeansID)"/>
			</xsl:call-template>
		</xsl:if>
		
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3248'" />
			<xsl:with-param name="node" select="cbc:PaymentMeansID" />
			<xsl:with-param name="expresion" select="count(key('by-cuotas-in-root', cbc:PaymentMeansID)) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Forma Pago : ', cac:PaymentTerms/cbc:PaymentMeansID)"/>
		</xsl:call-template>
		
		<xsl:if test="cbc:ID and cbc:ID='FormaPago'">
			<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'3245'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="descripcion" select="concat('Error en::: ', cbc:ID)"/>
			</xsl:call-template>
			
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3246'"/>
	            <xsl:with-param name="node" select="cbc:PaymentMeansID" />
				<xsl:with-param name="expresion" select="count(cbc:PaymentMeansID[text() = 'Credito' or substring(text(),1,5) = 'Cuota']) &lt; 1" />
	        </xsl:call-template>
			
			
		
			<xsl:if test="cbc:PaymentMeansID = 'Credito'">			
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3249'" />
					<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
					<xsl:with-param name="expresion" select="count($root/cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[substring(text(),1,5) = 'Cuota']]) = 0" />
				</xsl:call-template>
				
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'3251'"/>
					<xsl:with-param name="node" select="cbc:Amount"/>
				</xsl:call-template>	
				 
				<xsl:call-template name="validateValueTwoDecimalIfExist">
					<xsl:with-param name="errorCodeNotExist" select="'3250'"/>
					<xsl:with-param name="node" select="cbc:Amount"/>
				</xsl:call-template>   
				   
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'2071'" />
					<xsl:with-param name="node" select="cbc:Amount/@currencyID" />
					<xsl:with-param name="expresion" select="$root/cbc:DocumentCurrencyCode != cbc:Amount/@currencyID" />
				</xsl:call-template>  
			</xsl:if>    

			<xsl:if test="substring(cbc:PaymentMeansID,1,5) = 'Cuota'">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3252'" />
					<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
					<xsl:with-param name="expresion" select="count($root/cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() = 'Credito']]) = 0" />
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template>
								
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'3254'"/>
					<xsl:with-param name="node" select="cbc:Amount"/>
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template>
				
				<xsl:call-template name="validateValueTwoDecimalIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3253'"/>
					<xsl:with-param name="node" select="cbc:Amount"/>
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template>   
				   	
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'2071'" />
					<xsl:with-param name="node" select="cbc:Amount/@currencyID" />
					<xsl:with-param name="expresion" select="$root/cbc:DocumentCurrencyCode != cbc:Amount/@currencyID" />
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template> 
				   
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'3256'"/>                                        
					<xsl:with-param name="node" select="cbc:PaymentDueDate"/>
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3255'" />
					<xsl:with-param name="node" select="cbc:PaymentDueDate" />
					<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
				</xsl:call-template>
			</xsl:if>    
    	</xsl:if>
    <!-- FIN MIGE -->
    </xsl:template>
  	<!-- 
	===========================================================================================================================================
	Fin Template cac:PaymentTerms
	===========================================================================================================================================
	-->
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:TaxTotal mode=cabecera
	===========================================================================================================================================
	-->
	
	<xsl:template match="cac:TaxTotal" mode="cabecera">
		<xsl:param name="root" select = "'-'" />
		<xsl:param name="sumMontoTotalImpuestos" select = "'0'" />
        
        <!-- Ini PAS20181U210300115 --> 
        <xsl:variable name="tipoNotaCredito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/>
        
        <xsl:if test="$tipoNotaCredito = '12' ">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3221'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID[text() = '9995' or text() = '9997' or text() = '9998']]/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995' or text() = '9997' or text() = '9998']) &gt; 0 and number(cac:TaxSubtotal/cbc:TaxableAmount) &gt; 0" />
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$tipoNotaCredito = '11' ">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3221'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID[text() = '9997' or text() = '9998']]/cbc:ID" />
                <xsl:with-param name="expresion" select="count($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997' or text()='9998']]) &gt; 0" />
            </xsl:call-template>
        </xsl:if>
        
        
		<!-- /CreditNote/cac:TaxTotal/cbc:TaxAmount Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 3020 -->
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <!-- xsl:with-param name="errorCodeNotExist" select="'3020'"/> -->
            <xsl:with-param name="errorCodeValidate" select="'3020'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- Ini PAS20181U210300115 --> 
		<!-- Antonio add or text() = '7152'-->
        <xsl:variable name="totalImpuestos" select="$root/cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '9999' or text() = '2000']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4301'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="(round(($totalImpuestos + 1 ) * 100) div 100) &lt; (round($SumatoriaImpuestos * 100) div 100)  or (round(($totalImpuestos - 1) * 100) div 100) &gt; (round($SumatoriaImpuestos * 100) div 100) " />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- Fin PAS20181U210300115 -->  
		
		<!-- /CreditNote/cac:TaxTotal/cbc:TaxAmount Si el Tag UBL existe, el monto total de impuestos es diferente a la sumatoria de impuestos (Códigos 1000+1016+2000)
        ERROR 2519         
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2519'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number($sumMontoTotalImpuestos) != number(cbc:TaxAmount)" />
        </xsl:call-template>
        -->
		
		<xsl:variable name="totalISC" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
	    <xsl:variable name="totalISCxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
	        
	    <xsl:call-template name="isTrueExpresion">
	        <xsl:with-param name="errorCodeValidate" select="'4305'" />
	        <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
	        <xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalISCxLinea or ($totalISC - 1) &gt; $totalISCxLinea" />
	        <xsl:with-param name="isError" select ="false()"/>
	    </xsl:call-template>
	    
	    <xsl:variable name="totalOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount"/>
	    <xsl:variable name="totalOtrosxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)"/>
	    
	    <xsl:call-template name="isTrueExpresion">
	        <xsl:with-param name="errorCodeValidate" select="'4306'" />
	        <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
	        <xsl:with-param name="expresion" select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
	        <xsl:with-param name="isError" select ="false()"/>
	    </xsl:call-template>
			
			
		<xsl:variable name="totalBaseISC" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseISCxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4303'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseISC + 1 ) &lt; $totalBaseISCxLinea or ($totalBaseISC - 1) &gt; $totalBaseISCxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalBaseOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseOtrosxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount)"/>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4304'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseOtros + 1 ) &lt; $totalBaseOtrosxLinea or ($totalBaseOtros - 1) &gt; $totalBaseOtrosxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- Ini PAS20181U210300115 -->      
        <xsl:variable name="totalBaseExportacion" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseExportacionxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4295'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseExportacion + 1 ) &lt; $totalBaseExportacionxLinea or ($totalBaseExportacion - 1) &gt; $totalBaseExportacionxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <xsl:variable name="totalBaseExoneradas" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseExoneradasxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4297'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="(round(($totalBaseExoneradas + 1 ) * 100) div 100)  &lt; $totalBaseExoneradasxLinea or (round(($totalBaseExoneradas - 1) * 100) div 100)  &gt; $totalBaseExoneradasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <xsl:variable name="totalBaseInafectas" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseInafectasxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4296'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseInafectas + 1 ) &lt; $totalBaseInafectasxLinea or ($totalBaseInafectas - 1) &gt; $totalBaseInafectasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <xsl:variable name="totalBaseGratuitas" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseGratuitasxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4298'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseGratuitas + 1 ) &lt; $totalBaseGratuitasxLinea or ($totalBaseGratuitas - 1) &gt; $totalBaseGratuitasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <!-- <xsl:if test="$root/cac:CreditNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode ='02'">
        	<xsl:if test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996'">
	            <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2641'" />
					<xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
					<xsl:with-param name="expresion" select="not(cac:TaxSubtotal) or cac:TaxSubtotal/cbc:TaxableAmount = 0" />
	            </xsl:call-template>
	        </xsl:if>
        </xsl:if>-->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2641'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="$root/cac:CreditNoteLine/cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and (not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0)" />
        </xsl:call-template>
		
		<xsl:variable name="totalBaseIGV" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIVAP" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIGVxLinea" select="sum($root/cac:CreditNoteLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseIVAPxLinea" select="sum($root/cac:CreditNoteLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalDescuentosGlobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '02' or text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="totalCargosGobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '49']]/cbc:Amount)"/>
        <xsl:variable name="totalBaseIGVCalculado" select="$totalBaseIGVxLinea - $totalDescuentosGlobales + $totalCargosGobales"/>
        <xsl:variable name="totalBaseIVAPCalculado" select="$totalBaseIVAPxLinea - $totalDescuentosGlobales + $totalCargosGobales"/>
		
		
		<xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4299'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIGV + 1 ) &lt; $totalBaseIGVCalculado or ($totalBaseIGV - 1) &gt; $totalBaseIGVCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
		
		<xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4300'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIVAP + 1 ) &lt; $totalBaseIVAPCalculado or ($totalBaseIVAP - 1) &gt; $totalBaseIVAPCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
		<!-- /CreditNote/cac:TaxTotal El tag cac:TaxTotal no debe repetirse en el comprobante
        ERROR 3024 -->        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3024'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal" />
            <xsl:with-param name="expresion" select="count($root/cac:TaxTotal) &gt; 1" />
        </xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4020'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:Taxmount" />
            <xsl:with-param name="expresion" select="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount = 0" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>	
		
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:TaxTotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:TaxTotal/cac:TaxSubtotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
		<xsl:param name="root" select = "'-'" />
		<!--<xsl:param name="sumMontosTotales" select = "'0'" />-->
		
		<!-- <xsl:variable name="tipoNotaCredito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/> -->
    <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
		
		<xsl:variable name="totValorVentaIGVLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaIVAPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaISCLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaEXPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9995']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9995']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaEXOLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9997']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9997']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaINALinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9998']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9998']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaOTRLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaIGVLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaIVAPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaISCLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaOTRLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="MontoBaseIGVLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        
        <xsl:variable name="SumatoriaIGV" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
        
        <xsl:variable name="SumatoriaIGVCalculado" select="$MontoBaseIGVLinea * 0.18"/>
		
		<!-- Antonio-->
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template name="existAndValidateValueTwoDecimal">
				<xsl:with-param name="errorCodeNotExist" select="'3003'"/>
				<xsl:with-param name="errorCodeValidate" select="'2999'"/>
				<xsl:with-param name="node" select="cbc:TaxableAmount"/>
				<xsl:with-param name="isGreaterCero" select="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>			      
        
        <!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount si codigo de tributo es = '1000' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones gravadas de IGV en cada ítem (con una tolerancia + - 1)
        ERROR 3039 
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3039'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaIGVLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaIGVLinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		-->   
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount si codigo de tributo es = '1016' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones gravadas de IGV en cada ítem (con una tolerancia + - 1)
        ERROR 3046 -->   
        <!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3046'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaIVAPLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaIVAPLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si codigo de tributo = '2000', Si el Tag UBL existe y el valor del Tag UBL es diferente a la sumatoria del total valor de venta  - ISC de cada ítem (con una tolerancia + - 1)
        ERROR 3045 -->   
        <!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3045'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaISCLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaISCLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si codigo de tributo = '9999', Si el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta  - Otros tributos '9999' de cada ítem  (con una tolerancia + - 1)
        ERROR 3008 -->   
        <!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9999']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3008'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaOTRLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaOTRLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '1000', el valor del Tag Ubl es diferente de la sumatoria de los importes de IGV de cada ítem
        ERROR 3038 -->   
        <!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3038'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaIGVLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaIGVLinea)-1)" />
			</xsl:call-template>
		</xsl:if> 
		
		<xsl:if test="$root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4290'" />
                <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $SumatoriaIGVCalculado or ($SumatoriaIGV - 1) &gt; $SumatoriaIGVCalculado" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>-->
        <!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '1016', el valor del Tag Ubl es diferente de la sumatoria de los importes de IVAP de cada ítem
        ERROR 3049 -->   
        <!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3049'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaIVAPLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaIVAPLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115 -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '2000', el valor del Tag Ubl es diferente de la sumatoria de los importes de ISC de cada ítem (con una tolerancia + - 1)
        ERROR 3048 -->
        <!-- Ini PAS20181U210300115  -->   
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3048'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaISCLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaISCLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115  -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '9999', el valor del Tag Ubl es diferente de la sumatoria de los importes de otros tributos (9999) de cada ítem (con una tolerancia + - 1)
        ERROR 3009    
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9999']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3009'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaOTRLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaOTRLinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		-->
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9995', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - Exportaciones de cada ítem
        ERROR 3040 -->   
        <!-- Ini PAS20181U210300115 --> 
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3040'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaEXPLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaEXPLinea)-1)" />
			</xsl:call-template>
		</xsl:if> -->
		<!-- Fin PAS20181U210300115 --> 
		
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997']"> -->
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9997', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones exoneradas de cada ítem  (con una tolerancia + - 1)
			ERROR 3042 --> 
			<!-- Ini PAS20181U210300115 -->
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3042'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaEXOLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaEXOLinea)-1)" />
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 -->
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada)  y existe alguna línea con "codigo de tributo por linea" igual a "9997" (Exonerada),  el Tag UBL es igual a 0 (cero)
			OBSERVACION 4018 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4018'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="count($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997']]) > 0 and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada)  y "Código de leyenda" es 2001, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4022 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4022'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2001' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2002, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4023 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4023'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2002' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2003, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4024 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4024'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2003' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2007, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4243 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4243'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2007' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2008, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4244 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4244'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2008' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			
		<!-- </xsl:if> -->
		
		<!-- <xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9998']"> -->
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9998', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones inafectos de cada ítem  (con una tolerancia + - 1)
			ERROR 3041 --> 
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3041'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaINALinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaINALinea)-1)" />
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9998" (inafectas) y  existe alguna línea con "codigo de tributo por linea" igual a "9998" (inafectas), el Tag UBL es igual a 0 (cero)
			OBSERVACION 4017 -->  
			<!-- Ini PAS20181U210300115 --> 
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4017'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="count($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9998']]) > 0 and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 --> 
		<!-- </xsl:if> -->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 2048 -->
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/> 
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si el Tag UBL existe, el valor del Tag Ubl es diferente de 0 (cero), cuando el código de tributo es 9995, 9997 y 9998. 
		ERROR 3000 -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3000'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="expresion" select="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998'] and number(cbc:TaxAmount) != 0" />
		</xsl:call-template>
        <!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID No existe el Tag UBL o es vacío
        ERROR 3059 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL es diferente al código del tributo del listado
        ERROR 3007 -->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'3007'"/>
        </xsl:call-template>
        
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el comprobante
        ERROR 3068 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-codigo-tributo-cabecera-reference', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-'))) &gt; 1" />
        </xsl:call-template>
        <!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 12 (IVAP)  y existe un Id '9995' o '9997' o '9998' a nivel global
        ERROR 3107 
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998']">
		
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998'])" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
		
		</xsl:if>-->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y  '9997' o '9998' en cualquier invoice line
		ERROR 3107 
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3107'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and count($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997' or text()='9998']]) &gt; 0" />
			<xsl:with-param name="isError" select ="true()"/>
		</xsl:call-template>-->  
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000' or text()='1016']">
		
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL debe tener por lo menos uno de los siguientes valores en el comprobante: 1000 (Gravada), 1016 (IVAP)
			ERROR 3105 -->  
			<!-- Ini PAS20181U210300115 -->
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3105'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']) = 0 and 
				count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']) = 0" />
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 -->
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si existe los siguientes valores 1000, 1016 a la vez
			ERROR 3106 -->  
			<!-- Ini PAS20181U210300115 -->
			<!-- <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3106'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']) > 0 and 
				count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']) > 0" />
			</xsl:call-template> -->
			<!-- Fin PAS20181U210300115 -->
		
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 12 (IVAP) y existe un Id '1000'
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000'] and cbc:TaxableAmount &gt; 0)" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y existe un ID '1000' o '1016' o  a nivel global
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000' or text()='1016']" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
		
		</xsl:if>
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000' or text()='9999']">
		
            <!--<xsl:variable name="totalISC" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount"/>
	        <xsl:variable name="totalISCxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4305'" />
	            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalISCxLinea or ($totalISC - 1) &gt; $totalISCxLinea" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	        <xsl:variable name="totalOtros" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount"/>
	        <xsl:variable name="totalOtrosxLinea" select="sum($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)"/>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4306'" />
	            <xsl:with-param name="node" select="$root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>-->
		
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 12 (IVAP)  y existe un Id '2000'
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000'] and cbc:TaxableAmount &gt; 0)" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y existe un ID '2000' o '9999' a nivel global
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000' or text()='9999']" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
		
		</xsl:if>
        
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y  '9997' o '9998' en cualquier invoice line
        OBSERV 3107 -->
        <!--<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3107'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and (cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID ='9997' or cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID ='9998')" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>-->
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName Si existe el tag, el valor ingresado es diferente a 'Codigo de tributos' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        <!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL o es vacío
        ERROR 2054 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2054'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name Si el tag es diferente al nombre del tributo del listado según el codigo del tributo. (catalogo 5)
        ERROR 2964 -->
		<!-- 
		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'2964'"/>
		</xsl:call-template>
		 -->
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode No existe el Tag UBL o es vacío
        ERROR 2052 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2052'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode Si el tag es diferente al codigo internacional del tributo del listado según el codigo del tributo. (catalogo 5)
        ERROR 2961 -->
		<!-- 
		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2961'"/>
		</xsl:call-template>
		 -->
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:TaxTotal/cac:TaxSubtotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:CreditNoteLine
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:CreditNoteLine">
    
        <xsl:param name="root"/>
        <xsl:variable name="nroLinea" select="cbc:ID"/>
        <!--<xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>-->
        <xsl:variable name="codigoPrecio" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode"/>
		
        <!-- /CreditNote/cac:CreditNoteLine/cbc:ID El formato del Tag UBL es diferente de numérico de hasta 3 dígitos; o, es igual cero.
		ERROR 2137 -->
		<!-- Excel v6 PAS20211U210400011 JRGS - Se pasa de 5 a 3-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2137'"/>
            <xsl:with-param name="errorCodeValidate" select="'2137'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <!---xsl:with-param name="regexp" select="'^(?!0*$)\d{1,5}$'"/--> <!-- enteros mayores a cero y hasta 5 digitos -->
			<xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/>
			<!--<xsl:with-param name="regexp" select="'^([0-9]{1,5})?$'"/>  enteros mayores o iguales a cero y hasta 5 digitos -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:CreditNoteLine/cbc:ID El valor del Tag UBL no debe repetirse en el /CreditNote
		ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-creditNoteLine-id', number(cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:CreditNoteLine/cbc:CreditedQuantity@unitCode NSi el Tag UBL existe, no existe el atributo del Tag UBL
		ERROR 2138 -->
        <xsl:if test="cbc:CreditedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2138'"/>
                <xsl:with-param name="node" select="cbc:CreditedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        
		<!-- /CreditNote/cac:CreditNoteLine/cbc:CreditedQuantity@unitCodeListID Si existe el tag, el valor ingresado es diferente a 'UN/ECE rec 20'
		ERROR 4258 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4258'"/>
			<xsl:with-param name="node" select="cbc:CreditedQuantity/@unitCodeListID"/>
			<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cbc:CreditedQuantity@unitCodeListAgencyName Si existe el tag, el valor ingresado es diferente a 'United Nations Economic Commission for Europe'
		ERROR 4259 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4259'"/>
			<xsl:with-param name="node" select="cbc:CreditedQuantity/@unitCodeListAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        <!-- /CreditNote/cac:CreditNoteLine/cbc:CreditedQuantity No existe el Tag UBL
		ERROR 2580 -->
		<!-- /CreditNote/cac:CreditNoteLine/cbc:CreditedQuantity Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales
		ERROR 2139 -->
		
<!-- 		<xsl:call-template name="existAndRegexpValidateElement"> -->
<!--             <xsl:with-param name="errorCodeNotExist" select="'2580'"/> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'2580'"/> -->
<!--             <xsl:with-param name="node" select="cbc:CreditedQuantity"/> -->
<!--             <xsl:with-param name="regexp" select="'^(?!0[0-9]*(\.0*)?$)[0-9]{0,}(\.[0-9]{0,})?$'"/> -->
<!--         </xsl:call-template> -->
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2580'"/>
            <xsl:with-param name="node" select="cbc:CreditedQuantity"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2580'" />
            <xsl:with-param name="node" select="cbc:CreditedQuantity" />
            <xsl:with-param name="expresion" select="cbc:CreditedQuantity = 0" />
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2139'"/>
            <xsl:with-param name="node" select="cbc:CreditedQuantity"/>
            <xsl:with-param name="regexp" select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
		
		
<!--         <xsl:call-template name="existAndValidateValueTenDecimal"> -->
<!--             <xsl:with-param name="errorCodeNotExist" select="'2580'"/> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'2139'"/> -->
<!--             <xsl:with-param name="node" select="cbc:CreditedQuantity"/> -->
<!--             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--         </xsl:call-template> -->
		
<!-- 		<xsl:call-template name="isTrueExpresion"> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'2580'" /> -->
<!--             <xsl:with-param name="node" select="cbc:CreditedQuantity" /> -->
<!--             <xsl:with-param name="expresion" select="cbc:CreditedQuantity = 0" /> -->
<!--             <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/> -->
<!--         </xsl:call-template> -->
        
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:SellersItemIdentification/cbc:ID Si el tag UBL existe,  el formato del Tag UBL es diferente a alfanumérico de 1 hasta 50 caracteres (se considera cualquier carácter excepto salto de línea)
		OBSERVACION 4234 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4234'"/>
            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{1,30})$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode Si el tag UBL existe y el código de tipo de nota de crédito es 11, el valor del Tag UBL es vacío
		ERROR 3001 -->
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode Si el tag UBL existe y el código de tipo de nota de crédito es 11, el valor del Tag UBL no se encuentra en el listado
		ERROR 3002 -->
<!--        <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11'"> -->
<!--         	<xsl:call-template name="existElement"> -->
<!--                 <xsl:with-param name="errorCodeNotExist" select="'3001'"/> -->
<!--                 <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/> -->
<!--                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--             </xsl:call-template> -->
			
<!--			<xsl:call-template name="findElementInCatalog"> -->
<!--				<xsl:with-param name="errorCodeValidate" select="'3002'"/> -->
<!--				<xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/> -->
<!--				<xsl:with-param name="catalogo" select="'25'"/> -->
<!--				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--			</xsl:call-template> -->
 <!--       </xsl:if> -->
 		<!-- PAS20191U210000026 observación 4332 -->
 		
 		
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4332'"/>
			<xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
			<xsl:with-param name="catalogo" select="'25'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- PAS20191U210000026 Agrega validación 4337 	-->
	 	<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and string-length(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode) = 8">
	 		
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4337'" />
	            <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
	            <xsl:with-param name="expresion" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and substring(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode, 3, 6) = '000000' or cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and substring(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode, 5, 4) = '0000'" />
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>
	        	        
        </xsl:if>
		
        
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listID Si existe el tag, el valor ingresado es diferente a 'UNSPSC'
		ERROR 4254 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(UNSPSC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listAgencyName Si existe el tag, el valor ingresado es diferente a 'GS1 US'
		ERROR 4251 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(GS1 US)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listName Si existe el tag, el valor ingresado es diferente a 'Item Classification'
		ERROR 4252 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Item Classification$)'"/>
<!-- 			<xsl:with-param name="regexp" select="'^(?!.*(Item Classification$)).*'"/> -->
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- PAS20191U210000026 cambio de error 3201 a observación 4334-->
		<!-- PAS20191U210000026 se agrego GTIN-12 -->
		<xsl:choose>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-8'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <!-- <xsl:with-param name="errorCodeValidate" select="'3201'"/> -->
		            <xsl:with-param name="errorCodeValidate" select="'4334'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{8})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-12'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4334'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{12})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-13'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <!-- <xsl:with-param name="errorCodeValidate" select="'3201'"/> -->
		            <xsl:with-param name="errorCodeValidate" select="'4334'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{13})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-14'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <!-- <xsl:with-param name="errorCodeValidate" select="'3201'"/> -->
		            <xsl:with-param name="errorCodeValidate" select="'4334'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{14})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
        </xsl:choose>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3224'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- PAS20191U210000026 cambio de error 3200 a observación 4335-->
        <xsl:call-template name="regexpValidateElementIfExist">
			<!-- <xsl:with-param name="errorCodeValidate" select="'3200'"/> -->
			<xsl:with-param name="errorCodeValidate" select="'4335'"/>
			<xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="regexp" select="'^(GTIN-8|GTIN-12|GTIN-13|GTIN-14)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- PAS20191U210000026 cambio de error 3199 a observación 4333-->
        <xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID">
			<xsl:call-template name="existElementNoVacio">
                <!-- <xsl:with-param name="errorCodeNotExist" select="'3199'"/> -->
                <xsl:with-param name="errorCodeNotExist" select="'4333'"/>
                <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
                <xsl:with-param name="isError" select ="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>                
            </xsl:call-template>
		</xsl:if>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:Item/cbc:Description Si el tag UBL existe,  el formato del Tag UBL es diferente a alfanumérico de 3 hasta 500 caracteres (se considera cualquier carácter excepto salto de línea)
		ERROR 4084 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4084'"/>
			<xsl:with-param name="node" select="cac:Item/cbc:Description"/>
			<xsl:with-param name="regexp" select="'^((?!\s*$)[^\n\r]{3,500})$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
        <!-- /CreditNote/cac:CreditNoteLine/cac:Price/cbc:PriceAmount Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales
		ERROR 4254 -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2369'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:Price/cbc:PriceAmount Si "Código de tipo de precio" es 02 (Gratuitas), el valor del Tag UBL es mayor a 0 (cero)
		ERROR 2640 -->
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2640'" />
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and cac:Price/cbc:PriceAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
	    </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
	        <xsl:with-param name="errorCodeValidate" select="'2409'" />
	        <xsl:with-param name="node" select="cbc:PriceTypeCode" />
	        <xsl:with-param name="expresion" select="count(cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode) &gt; 1" />
	        <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	    </xsl:call-template>
		
        <xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">
        	
        	<!-- cac:CreditNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount No existe el Tag UBL
	        ERROR 2028 -->
	        <!-- cac:CreditNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales 
	        ERROR 2367 -->	   
	        <!-- DRI Ini PAS20181U210300115 -->     
	        <!-- <xsl:call-template name="existAndValidateValueTenDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template> -->
	        <xsl:if test="cbc:PriceAmount">
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	           <!-- <xsl:with-param name="errorCodeNotExist" select="'2367'"/>-->
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            </xsl:if>
            <!-- DRI Fin PAS20181U210300115 -->
     
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2410'"/>
                <xsl:with-param name="node" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'16'"/>
                <xsl:with-param name="idCatalogo" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2410'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            
<!--             <xsl:call-template name="isTrueExpresion"> -->
<!-- 	            <xsl:with-param name="errorCodeValidate" select="'2409'" /> -->
<!-- 	            <xsl:with-param name="node" select="cbc:PriceTypeCode" /> -->
<!-- 	            <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode) &gt; 1" /> -->
<!-- 	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/> -->
<!-- 	        </xsl:call-template> -->
            
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4252'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listName"/>
				<xsl:with-param name="regexp" select="'^(Tipo de Precio)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4251'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4253'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
            
        </xsl:for-each>
        
		<!-- /CreditNote/cac:CreditNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount Si 
		Si "Afectación al IGV por línea" es 10 (Gravado), 20 (Exonerado) o 30 (Inafecto) y "Código de precio" es 02 (Valor referencial en operaciones no onerosa), el Tag UBL es mayor a 0 (cero)
		ERROR 2425 -->
		<!-- Valor referencial unitario por ítem en operaciones no onerosas -->
		<!-- Ini PAS20181U210300115 -->
		<!-- <xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2425'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode" />
			<xsl:with-param name="expresion" select="$codigoPrecio='02' and cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount > 0 and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template> --> 
		<!-- Fin PAS20181U210300115 -->
		
		<!--  Debe existir en el cac:CreditNoteLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <!-- <xsl:with-param name="errorCodeValidate" select="'2956'" /> -->
            <xsl:with-param name="errorCodeValidate" select="'3195'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount)"/>
        
		<!-- Si el Tag UBL existe, el monto total de impuestos por línea es diferente a la sumatoria de impuestos por línea -->
        <!-- Ini PAS20181U210300115 --> 
        <!-- <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3022'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $SumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1) &gt; $SumatoriaImpuestosxLinea" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template> -->
        <!-- Fin PAS20181U210300115 --> 
		
        <!-- El tag /CreditNoteLine/cac:TaxTotal no debe repetirse en el /CreditNoteLine -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3026'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- Ini PAS20181U210300115 -->
		<xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
			<xsl:with-param name="cntLineaProd" select="cbc:CreditedQuantity"/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
        </xsl:apply-templates>
        <!-- Fin PAS20181U210300115 -->
		
		<!-- Fin Template cac:TaxTotal/cac:TaxSubtotal Linea -->
              
		<!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
        ERROR 3100 -->
        <!-- Ini PAS20181U210300115 -->
        <!-- <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3105'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template> -->
        <!-- Fin PAS20181U210300115 -->
        
        <!-- Ini PAS20181U210300115 -->
        <!-- <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3106'" />
           <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
           <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &gt; 1" />
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template> -->
        <!-- Fin PAS20181U210300115 -->
        
        <!-- Valor de venta por línea -->
        <!-- cac:CreditNoteLine/cbc:LineExtensionAmount El formato del Tag UBL es diferente de decimal (positivo o negativo) de 12 enteros y hasta 2 decimales ERROR 2370 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        
        <!-- Ini PAS20181U210300115 -->
        <!-- Validaciones de sumatoria -->
        <xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount"/>
        <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount"/>
        <xsl:variable name="ImpuestosItem" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="DsctosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)"/>
        <xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)"/>
        <xsl:variable name="CargosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)"/>
        <xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)"/>
        <xsl:variable name="CantidadItem" select="cbc:CreditedQuantity"/>
       	<xsl:variable name="PrecioUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount)"/>
       	<xsl:variable name="PrecioReferencialUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount)"/>
        
        <xsl:variable name="PrecioUnitarioCalculado" select="($ValorVentaxItem + $ImpuestosItem - $DsctosNoAfectanBI + $CargosNoAfectanBI) div ( $CantidadItem)"/>
        <xsl:variable name="ValorVentaReferencialxItemCalculado" select="($PrecioReferencialUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/>
        <xsl:variable name="ValorVentaxItemCalculado" select="($ValorVentaUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/> 
		
		<!-- 4288 - Valor de Venta x Item = Dividir (suma del valor de venta + impuestos x item - descuentos No afectan a BI + Cargos no afectan a BI ) con la cantida -->  
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4288'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaReferencialxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaReferencialxItemCalculado)" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4288'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and (($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" />
             <!-- <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0)" />-->
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- FIN Validacion 4288 -->
        
        
        <xsl:variable name="codigoSUNAT" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
        <xsl:variable name="indPrimeraVivienda" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '7002']]/cbc:Value"/>
        
        <xsl:if test="$codigoSUNAT = '84121901'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3150'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7001')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3151'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7003']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7003')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3152'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7004')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3153'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7005')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3154'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7006']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7006')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3155'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7007']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7007')"/>
            </xsl:call-template>
            
        </xsl:if>
        
        <xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        <!--<xsl:if test="$tipoOperacion='0102'">
 
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2501'" />
                <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
                <xsl:with-param name="expresion" select="cbc:LineExtensionAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>                
       
        </xsl:if>-->
        
        <!-- Tributos por linea de detalle 
        <xsl:apply-templates select="cac:Allowancecharge" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
        -->
        
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:CreditNoteLine
	===========================================================================================================================================
	--> 
	
	 <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'4235'"/>
            <xsl:with-param name="node" select="cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
<!--         <xsl:call-template name="findElementInCatalog"> -->
<!--             <xsl:with-param name="catalogo" select="'55'"/> -->
<!--             <xsl:with-param name="idCatalogo" select="cbc:NameCode"/> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'4279'"/> -->
<!--             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!--             <xsl:with-param name="isError" select ="false()"/> -->
<!--         </xsl:call-template> -->
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Propiedad del item)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:variable name="codigoConcepto" select="cbc:NameCode"/>
        
		<xsl:choose>
			
            <xsl:when test="$codigoConcepto = '7000'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'26'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'27'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 50 or string-length(cbc:Value) &lt; 3 ">
						<xsl:call-template name="isTrueExpresion">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="expresion" select="true()" />
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:when>
		        	<xsl:otherwise>				
				        <xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
							<!--Excel v6 PAS20211U210400011 JRGS - Se agrega modifica expresion -->
				            <!--<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> -->
							<xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/>
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 50 or string-length(cbc:Value) &lt; 3 ">
						<xsl:call-template name="isTrueExpresion">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="expresion" select="true()" />
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:when>
		        	<xsl:otherwise>
				        <xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
							<!--Excel v6 PAS20211U210400011 JRGS - Se agrega modifica expresion -->
				            <!--<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>  -->
							<xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/>
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            	<!--xsll:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template-->
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
<!-- 		            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/> Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
					<xsl:with-param name="regexp" select="'^(\d{4})(-)(0[1-9]|1[0-2])\2([0-2][0-9]|3[0-1])$'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7007'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 200 or string-length(cbc:Value) &lt; 3 ">
						<xsl:call-template name="isTrueExpresion">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="expresion" select="true()" />
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:when>
		        	<xsl:otherwise>
				        <xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
							<!--Excel v6 PAS20211U210400011 - Se agrega modifica expresion -->
				            <!--<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>  -->
							<xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            	<!-- xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template-->
            </xsl:when>
            
            <!-- Excel v6 PAS20211U210400011 JRGS-->
            <xsl:when test="$codigoConcepto = '7008' or $codigoConcepto = '7009' or $codigoConcepto = '7010' or $codigoConcepto = '7011'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>
            </xsl:when>
            
            <!-- Excel v6 PAS20211U210400011 JRGS-->
            <xsl:when test="$codigoConcepto = '7004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>
		        
		          <xsl:choose>
		        	  <xsl:when test="string-length(cbc:Value) &gt; 50 or string-length(cbc:Value) &lt; 3 ">
						      <xsl:call-template name="isTrueExpresion">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="expresion" select="true()" />
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				          </xsl:call-template>
		        	  </xsl:when>
		        	  <xsl:otherwise>
				          <xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^[^\t\n\r]{3,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				          </xsl:call-template>
		        	  </xsl:otherwise>
		          </xsl:choose>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '7005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		          </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '7013'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>
		          <xsl:choose>
		        	  <xsl:when test="string-length(cbc:Value) &gt; 50 or string-length(cbc:Value) &lt; 1 ">
						       <xsl:call-template name="isTrueExpresion">
				              <xsl:with-param name="errorCodeValidate" select="'4280'" />
				              <xsl:with-param name="node" select="cbc:Value" />
				              <xsl:with-param name="expresion" select="true()" />
				              <xsl:with-param name="isError" select ="false()"/>
				              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				           </xsl:call-template>
		        	  </xsl:when>
		        	  <xsl:otherwise>
				          <xsl:call-template name="regexpValidateElementIfExist">
				             <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				             <xsl:with-param name="node" select="cbc:Value"/>
				             <xsl:with-param name="regexp" select="'^[^\t\n\r\f]{1,}$'"/> 
				             <xsl:with-param name="isError" select ="false()"/>
				             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				          </xsl:call-template>
		        	  </xsl:otherwise>
		          </xsl:choose>
		        </xsl:when>

            <xsl:when test="$codigoConcepto = '7015'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>

				      <xsl:call-template name="regexpValidateElementIfExist">
				        <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				        <xsl:with-param name="node" select="cbc:Value"/>
				        <xsl:with-param name="regexp" select="'^[123]{1}$'"/> 
				        <xsl:with-param name="isError" select ="false()"/>
				        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				      </xsl:call-template>
		        </xsl:when>

            <xsl:when test="$codigoConcepto = '7012' or $codigoConcepto = '7016'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>

				      <xsl:call-template name="regexpValidateElementIfExist">
				        <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				        <xsl:with-param name="node" select="cbc:Value"/>
				        <xsl:with-param name="regexp" select="'^(?=.*[1-9])[0-9]{1,15}(\.[0-9]{1,2})?$'"/> 
				        <xsl:with-param name="isError" select ="false()"/>
				        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				      </xsl:call-template>
		        </xsl:when>
            
			      <xsl:when test="$codigoConcepto = '7014'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3243'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>

              <xsl:call-template name="regexpValidateElementIfExist">
				        <xsl:with-param name="errorCodeValidate" select="'4280'" />
				        <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate" />
				        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'" />
				        <xsl:with-param name="isError" select ="false()"/>
				        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				      </xsl:call-template>

            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'4366'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:EndDate"/>
		            <xsl:with-param name="isError" select ="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>

 			        <xsl:call-template name="regexpValidateElementIfExist">
				        <xsl:with-param name="errorCodeValidate" select="'4280'" />
				        <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:EndDate" />
				        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'" />
				        <xsl:with-param name="isError" select ="false()"/>
				        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				      </xsl:call-template>
		        </xsl:when>
			
        </xsl:choose>
        
    </xsl:template>
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
	
	
	
	
	<!-- 
    ===========================================================================================================================================
    Ini Template cac:TaxTotal Linea
    ===========================================================================================================================================
    --> 
    <!-- Ini PAS20181U210300115 -->
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
		<xsl:param name="cntLineaProd"/>
        <xsl:param name="valorVenta"/>
         
        <xsl:variable name="tipoNotaCredito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/>
        
        <!--  <xsl:if test="$tipoNotaCredito='11'">
           Si 'Código de tipo de nota de credito' es 11 (Exportación) y  existe un ID '1000' o '1016' o '9997' o '9998' en cualquier CreditNoteline 
            ERROR 3100 
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>  
        </xsl:if>-->
        
        <!--<xsl:if test="$tipoNotaCredito='11'">
             Si 'Código de tipo de nota de credito' es 11 (Exportación) y  existe un ID '1000' o '1016' o '9997' o '9998' en cualquier CreditNoteline 
            ERROR 3100 
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000' or text() = '9999']) &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000' or text() = '9999']]/cbc:TaxableAmount &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>  
        </xsl:if>-->
        
        
        <!-- DRI ini-->
        
		<!-- Antonio add 7152 -->
        <xsl:variable name="totalImpuestosxLinea" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '7152' or text() = '2000' or text() = '9999']]/cbc:TaxAmount)"/>
        
		<xsl:if test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '2000' or text() = '9999']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4293'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="(round(($totalImpuestosxLinea + 1 )*100) div 100) &lt; $SumatoriaImpuestosxLinea or (round(($totalImpuestosxLinea - 1 )*100) div 100) &gt; $SumatoriaImpuestosxLinea" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>  
		</xsl:if>
        
		<!-- Ini Template cac:TaxTotal/cac:TaxSubtotal Linea -->
		<xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
			<xsl:with-param name="cntLineaProd" select="$cntLineaProd"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
		
        <xsl:variable name="TributoISCxLinea">		
            <xsl:choose>
                <xsl:when test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
        <xsl:variable name="BaseIGVIVAPxLinea" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016']]/cbc:TaxableAmount"/>
        <xsl:variable name="BaseIGVIVAPxLineaCalculado" select="$valorVenta + $TributoISCxLinea"/>
        
        
        <xsl:if test="$BaseIGVIVAPxLinea">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4294'" />
	            <xsl:with-param name="node" select="$BaseIGVIVAPxLinea" />
	            <xsl:with-param name="expresion" select="($BaseIGVIVAPxLinea + 1 ) &lt; $BaseIGVIVAPxLineaCalculado or ($BaseIGVIVAPxLinea - 1) &gt; $BaseIGVIVAPxLineaCalculado" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        <!-- DRI fin-->
        <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
        ERROR 3105 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3105'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:if test="count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) &gt; 1">
                        <xsl:call-template name="isTrueExpresion">
                           <xsl:with-param name="errorCodeValidate" select="'3223'" />
                           <xsl:with-param name="node" select="cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                           <xsl:with-param name="expresion" select="not((cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                           (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                           (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
                           (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1016' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                           (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9995' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                           (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2)or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
                            (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2))" />
                       </xsl:call-template>
            </xsl:if>        
        
    </xsl:template>
    <!-- Fin PAS20181U210300115 -->
	
	<!-- 
    ===========================================================================================================================================
    Fin Template cac:TaxTotal Linea
    ===========================================================================================================================================
    --> 
	
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:TaxTotal/cac:TaxSubtotal Linea
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:TaxTotal/cac:TaxSubtotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
		<xsl:param name="cntLineaProd"/>
        
        <xsl:variable name="tipoNotaCredito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/>

		<xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        <xsl:variable name="codTributo">
            <xsl:choose>
                <xsl:when test="$codigoTributo = '1000'">
                    <xsl:value-of select="'igv'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '1016'">
                    <xsl:value-of select="'iva'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9995'">
                    <xsl:value-of select="'exp'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9996'">
                    <xsl:value-of select="'gra'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9997'">
                    <xsl:value-of select="'exo'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9998'">
                    <xsl:value-of select="'ina'"/>
                </xsl:when>
				<!--PAS20191U210000012 - add  test="$codigoTributo = '7152'-->
				<xsl:when test="$codigoTributo = '7152'">
                    <xsl:value-of select="'oth'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
    
        <xsl:variable name="MontoTributo">
            <xsl:choose>
               <xsl:when test="cbc:TaxAmount">
                 <xsl:value-of select="cbc:TaxAmount" />
               </xsl:when>
               <xsl:otherwise>
                 <xsl:text>0</xsl:text>
               </xsl:otherwise>
             </xsl:choose> 
        </xsl:variable>
		
    		<!-- PAS20191U210000012-->
        <xsl:variable name="BaseImponible">
            <xsl:choose>
               <xsl:when test="cbc:TaxableAmount">
                 <xsl:value-of select="cbc:TaxableAmount" />
               </xsl:when>
			   <xsl:when test="cbc:TaxAmount">
                 <xsl:value-of select="cbc:TaxAmount" />
               </xsl:when>
               <xsl:otherwise>
                 <xsl:text>0</xsl:text>
               </xsl:otherwise>
             </xsl:choose> 
        </xsl:variable>
	
        <xsl:variable name="Tasa">
            <xsl:choose>
               <xsl:when test="cac:TaxCategory/cbc:Percent">
                 <xsl:value-of select="cac:TaxCategory/cbc:Percent" />
               </xsl:when>
               <xsl:otherwise>
                 <xsl:text>0</xsl:text>
               </xsl:otherwise>
             </xsl:choose> 
        </xsl:variable>
		
        <xsl:variable name="MontoTributoCalculado" select="$BaseImponible * $Tasa * 0.01"/>
	
		<!-- PAS20191U210000012 -->
        <xsl:if test="$codigoTributo = '7152'">
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>
		<xsl:variable name="monedaBolsa" select="cac:TaxAmount/@currencyID"/>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2071'"/>
				<xsl:with-param name="node" select="cac:TaxAmount"/>
				<xsl:with-param name="expresion" select="$monedaDocumento != $monedaBolsa"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>
		
		<!-- Antonio -->
		<xsl:if test="$codigoTributo = '7152'">
		<xsl:variable name="CantidadBolsa" select="cbc:BaseUnitMeasure"/>
		<xsl:variable name="PrecioBolsa" select="cac:TaxCategory/cbc:PerUnitAmount"/>
		<xsl:variable name="MontoBolsa" select="(round(cbc:TaxAmount * 100) div 100)"/>
			<xsl:if test="$CantidadBolsa &gt; 0">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'4318'"/>
					<xsl:with-param name="node" select="cbc:TaxAmount"/>
					<xsl:with-param name="expresion" select="(round($CantidadBolsa*$PrecioBolsa * 100) div 100)!=$MontoBolsa"/>
					<xsl:with-param name="isError" select ="false()"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		
		<!-- Antonio -->
		<xsl:if test="$codigoTributo = '7152'">
	    <xsl:call-template name="existElement">
		    <xsl:with-param name="errorCodeNotExist" select="'3237'"/>
		    <xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
		    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		  </xsl:call-template>
		</xsl:if>
		
		<!-- Antonio -->
		<xsl:if test="$codigoTributo = '7152'">
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2892'"/>
				<xsl:with-param name="errorCodeValidate" select="'2892'"/>
				<xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
				<!---xsl:with-param name="regexp" select="'^(?!0*$)\d{1,5}$'"/--> <!-- enteros mayores a cero y hasta 5 digitos -->
				<xsl:with-param name="regexp" select="'^([0-9]{1,5})?$'"/> <!-- enteros mayores o iguales a cero y hasta 5 digitos -->
				<xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
			</xsl:call-template>
		</xsl:if>

		<!-- Antonio -->
		<xsl:if test="$codigoTributo = '7152'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4320'"/>
				<xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
				<xsl:with-param name="expresion" select="cbc:BaseUnitMeasure/@unitCode != 'NIU'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>		
		
		<!-- Antonio -->
		<xsl:if test="$codigoTributo = '7152'">
		<xsl:variable name="CantProducto" select="round($cntLineaProd)"/>
		<xsl:variable name="CantidadBolsa" select="cbc:BaseUnitMeasure"/>
			<xsl:if test="$CantidadBolsa &gt; 0">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3236'"/>
					<xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
					<xsl:with-param name="expresion" select="$CantidadBolsa!=$CantProducto"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:if>	
        </xsl:if>
		
		<!-- PAS20191U210000012 -->
		<xsl:if test="$codigoTributo = '7152'">
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2892'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:PerUnitAmount"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		</xsl:if>	
		
		<!-- PAS20191U210000012 -->
		<xsl:if test="$codigoTributo = '7152'">
			<xsl:if test="cbc:BaseUnitMeasure &gt; 0">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3238'" />
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:PerUnitAmount" />
					<xsl:with-param name="expresion" select="(round(cac:TaxCategory/cbc:PerUnitAmount * 100000) div 100000) = 0 " />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo,' PerUnitAmount::::',(round(cac:TaxCategory/cbc:PerUnitAmount * 100) div 100))"/>
				</xsl:call-template>
			</xsl:if>
	    </xsl:if>
		

        <!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales   
		ERROR   3031 -->
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template name="validateValueTwoDecimalIfExist">
				<xsl:with-param name="errorCodeNotExist" select="'3031'"/>
				<xsl:with-param name="errorCodeValidate" select="'3031'"/>
				<xsl:with-param name="node" select="cbc:TaxableAmount"/>
				<xsl:with-param name="isGreaterCero" select="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
		</xsl:if>	
        
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID No existe el Tag UBL o es vacío
		ERROR 2037 -->
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
		<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2036'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
        <!-- DRI Ini PAS20181U210300115         
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3222'" />
            <xsl:with-param name="node" select="cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and not($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = $codigoTributo and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        DRI Fin PAS20181U210300115 -->
        
        
        
        <!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales   
		ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Ini PAS20181U210300115 --> 
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999' ">
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2371'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
        
        <xsl:if test="$codigoTributo = '9996'">
        
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3111'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17'] and cbc:TaxAmount = 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3110'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '37' or text() = '40'] and cbc:TaxAmount != 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
        
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2993'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17'] and cac:TaxCategory/cbc:Percent = 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Fin PAS20181U210300115 --> 
		
				<!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 3 enteros y hasta 5 decimales
				ERROR 3102 -->
	    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3102'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        
        <xsl:choose>
        
            <xsl:when test="$codigoTributo = '1000' or $codigoTributo = '1016' ">
            	
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3100'" />
		            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		            <xsl:with-param name="expresion" select="$tipoNotaCredito ='11'" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			    </xsl:call-template>
	        
				<!-- Si codigo de tributo por linea es igual a '1000' o '1016', El valor del tag UBL es igual a 0
				ERROR 3111 -->
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3111'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <!-- Ini PAS20181U210300115 -->
	                <!-- <xsl:with-param name="expresion" select="cbc:TaxAmount = 0" /> -->
	                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cbc:TaxAmount = 0" />
	                <!-- Fin PAS20181U210300115 -->
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>
	            
	            <!-- Ini PAS20181U210300115 
	            <xsl:if test="$codigoTributo = '1016'">
		            <xsl:call-template name="isTrueExpresion">
	                    <xsl:with-param name="errorCodeValidate" select="'3061'" />
	                    <xsl:with-param name="node" select="cbc:TaxAmount" />
	                    <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and $tipoNotaCredito = '12' and cbc:TaxAmount != 0" />
	                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	                </xsl:call-template>
	            </xsl:if>
                Fin PAS20181U210300115 -->
                            
	            <!--
	            <xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
		            <xsl:with-param name="errorCodeValidate" select="'3102'"/>
		            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
		            <xsl:with-param name="isGreaterCero" select="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>-->
	            
				<!-- Si codigo de tributo por linea es igual a '1000' o '1016', El valor del tag UBL es igual a 0
				ERROR 2993 -->
				<!-- Ini PAS20181U210300115 -->
	            <!-- <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
	            
	            <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	            </xsl:call-template>
	            <!-- Fin PAS20181U210300115 -->
	            
				<!-- Si "Código de tributo por línea" es 1000 (IGV), no existe el Tag UBL
				ERROR 2371 -->
				<!-- Ini PAS20181U210300115 --> 
	            <!-- <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
	            <!-- Fin PAS20181U210300115 --> 
	            
				<!-- Si "Código de tributo por línea" es diferente a 2000 (ISC) o 9999 (Otros tributos), el valor del Tag UBL es diferente al listado de su código de tributo.
				ERROR 2040 -->
				<!-- 
		        <xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="1"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
	             -->
            </xsl:when>
            <xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">
				<!-- No existe el Tag UBL o es vacío
				ERROR 2992
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
	            
				<!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 3 enteros y hasta 5 decimales
				ERROR 3102 
	            <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3102'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
					<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>-->
				
				<!-- Si "Código de tributo por línea" es igual a 2000 (ISC) o 9999 (Otros tributos), existe el tag UBL
				ERROR 3050 -->
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3050'" />
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
					<xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
				
				
		       	<!-- PAS20211U210400011 JRGS <xsl:if test="$codigoTributo = '2000' ">  -->
            	<xsl:if test="$codigoTributo = '2000' and cbc:TaxableAmount &gt; 0 ">
	            	
					<!-- Si codigo de tributo por linea es igual a '2000' , El valor del tag UBL es igual a 0
					ERROR 3104 -->
	            	<xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3104'" />
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
		                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent = 0" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
	            	
	            	<!-- <xsl:call-template name="isTrueExpresion">
		                <xsl:with-param name="errorCodeValidate" select="'3108'" />
		                <xsl:with-param name="node" select="cbc:TaxAmount" />
		                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoBaseTributo * $tasaTributo / 100 or ($MontoTributo - 1) &gt; $MontoBaseTributo * $tasaTributo / 100" />
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
		            -->
					<!-- Si "Código de tributo por línea" es 2000 (ISC), no existe el Tag UBL
					ERROR 2373 -->
		            <xsl:call-template name="existElement">
		                <xsl:with-param name="errorCodeNotExist" select="'2373'"/>
		                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange"/>
		                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            </xsl:call-template>
		            
					<!-- Si "Código de tributo por línea" es 2000 (ISC), el valor del Tag UBL es diferente al listado
					ERROR 2199 -->
		            <xsl:call-template name="findElementInCatalog">
			            <xsl:with-param name="catalogo" select="'08'"/>
			            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TierRange"/>
			            <xsl:with-param name="errorCodeValidate" select="'2199'"/>
						<!--<xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0" /> -->
			            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			        </xsl:call-template>
	            </xsl:if>
				
				<xsl:if test="$codigoTributo != '2000'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'3210'" />
						<xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
						<xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
					</xsl:call-template>
				</xsl:if>
				
				<xsl:if test="$codigoTributo = '2000'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'3108'" />
						<xsl:with-param name="node" select="cbc:TaxAmount" />
						<xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
					</xsl:call-template>
				</xsl:if>
				
				<xsl:if test="$codigoTributo = '9999'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'3109'" />
						<xsl:with-param name="node" select="cbc:TaxAmount" />
						<xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
					</xsl:call-template>
				</xsl:if>
	            
	            <!--<xsl:if test="$codigoTributo = '9999'">
		            
		             <xsl:if test="cac:TaxCategory/cbc:Percent != 0">	            	     -->       
			            
			            <!--<xsl:call-template name="isTrueExpresion">
			                <xsl:with-param name="errorCodeValidate" select="'3109'" />
			                <xsl:with-param name="node" select="cbc:TaxAmount" />
			                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; ($MontoBaseTributo * $tasaTributo / 100) or ($MontoTributo - 1) &gt; ($MontoBaseTributo * $tasaTributo / 100)" />
			                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			            </xsl:call-template>	-->
			            
			            <!--<xsl:call-template name="isTrueExpresion">
			                <xsl:with-param name="errorCodeValidate" select="'2993'" />
			                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
			                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
			                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			            </xsl:call-template>            -->
		      <!--      </xsl:if>
		            
	            </xsl:if>-->
	            
            </xsl:when>
            
            <xsl:when test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
            	
            <!--Versión 5 excel --> 
	            <!--<xsl:if test="$codigoTributo = '9997' or $codigoTributo = '9998'">
	            
	            	<xsl:call-template name="isTrueExpresion">
			            <xsl:with-param name="errorCodeValidate" select="'3100'" />
			            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			            <xsl:with-param name="expresion" select="$tipoNotaCredito ='11'" />
			            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				    </xsl:call-template>
				    
	            </xsl:if>-->
				<!-- Si codigo de tributo por linea es igual a '9995' o '9997' o '9998', El valor del tag UBL es diferente de 0
				ERROR 3110 -->
            	<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3110'" />
	                <xsl:with-param name="node" select="cbc:TaxAmount" />
	                <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ', código de tributo: ', $codigoTributo)"/>
	            </xsl:call-template>
				
	            <!-- No existe el Tag UBL o es vacío
				ERROR 2992 
	            <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template>-->
	            
				<!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 3 enteros y hasta 5 decimales
				ERROR 3102
	            <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3102'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
					<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template> -->
			       
				<!-- Si codigo de tributo por linea es igual a '9995' o '9997' o '9998', El valor del tag UBL es diferente de 0
				ERROR 3101 -->
				<!-- Ini PAS20181U210300115 --> 
	            <!-- <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3101'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent != 0" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
	            <!-- Fin PAS20181U210300115 --> 
	            
	            <!-- Ini PAS20181U210300115 --> 
	            <!-- <xsl:call-template name="existElement">
	                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
		        <!-- Fin PAS20181U210300115 --> 
				
				<!-- Si "Código de tributo por línea" es diferente a 2000 (ISC) o 9999 (Otros tributos), el valor del Tag UBL es diferente al listado de su código de tributo.
				ERROR 2040 -->
				<!-- 
		        <xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="1"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
				 -->
				<!-- Ini PAS20181U210300115 --> 
				<!-- <xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'2993'" />
	                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            </xsl:call-template> -->
	            <!-- Fin PAS20181U210300115 --> 
	            
	            
            </xsl:when>
           
        </xsl:choose>
        
        <!-- Ini PAS20181U210300115 -->
        <xsl:if test="cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3103'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Fin PAS20181U210300115 --> 
        
        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoNotaCredito ='11'">
        
        
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2642'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode != '40'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <!-- Validaciones para IVAP -->
        <xsl:if test="$tipoNotaCredito ='12'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2644'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode != '17'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <!-- Ini PAS20181U210300115 --> 
        <xsl:if test="cac:TaxCategory/cbc:TaxExemptionReasonCode = '17'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3230'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="$tipoNotaCredito != '12'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Fin PAS20181U210300115 --> 
        
        
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT'
		OBSERVACION 4251 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName Si existe el tag, el valor ingresado es diferente a 'Afectacion del IGV'
		OBSERVACION 4252 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07'
		OBSERVACION 4253 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		      	
		<!-- No existe el Tag UBL o es vacío
		ERROR 2992 -->
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2992'"/>
				<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
	    </xsl:if> 
		
        <!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse por linea en el comprobante
		ERROR 3067 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 12 (IVAP) y existe un Id '1000' o '9995' o '9997' o '9998' en cualquier CreditNoteLine
		Si "código de tipo de nota de credito" es 12 (IVAP) y existe un Id '2000' o '9999' en cualquier CreditNoteLine
		ERROR 3100 -->
		<!-- Ini PAS20181U210300115 -->
		<!-- <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '2000' or text() = '9995' or text() = '9997' or text() = '9998' or text() = '9999']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        </xsl:if> -->
        <!-- Fin PAS20181U210300115 -->
        
        <!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y  existe un ID '1000' o '1016' o '9997' o '9998' en cualquier CreditNoteline
		si "código de tipo de nota de credito" es 11 (Exportación) y existe un ID '2000' o '9999' en cualquier CreditNoteLine
		ERROR 3100 -->
		<!-- Ini PAS20181U210300115 -->
        <!-- <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '2000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        </xsl:if> -->
        <!-- Fin PAS20181U210300115 -->
        
        <!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName Si existe el tag, el valor ingresado es diferente a 'Codigo de tributos'
		OBSERVACION 4255 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT'
		OBSERVACION 4256 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05'
		OBSERVACION 4257 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!--<xsl:choose>
			<xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">-->
				<!-- /DebitNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL o es vacío 
				ERROR 2038 -->		
			<!--	<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2038'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>-->
				<!-- /DebitNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL o es vacío 
				ERROR 2996		
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2996'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template> -->
		<!--	</xsl:otherwise>
           
        </xsl:choose>-->
		
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL o es vacío 
        ERROR 2996 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2996'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name El valor del Tag UBL es diferente al listado según su código de tributo por linea (catalogo 05)
        ERROR 3051 -->
		<!-- 
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'3051'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		 -->
		<!-- /CreditNote/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode El valor del Tag UBL es diferente al listado según su código de tributo por linea (catalogo 05)
        ERROR 2377 -->
		<!-- 
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2377'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		 -->
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:TaxTotal/cac:TaxSubtotal Linea
	===========================================================================================================================================
	-->
   
</xsl:stylesheet>
