<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times"
	extension-element-prefixes="dp" exclude-result-prefixes="dp"
	version="1.0">

	<xsl:include
		href="local:///commons/error/validate_utils.xsl"
		dp:ignore-multiple="yes" />

	<!-- key Numero de lineas duplicados fin -->
	<xsl:key name="by-invoiceLine-id" match="*[local-name()='SelfBilledInvoice']/cac:InvoiceLine" use="number(cbc:ID)" />
	
	<!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='SelfBilledInvoice']/cac:DespatchDocumentReference" use="cbc:ID"/>
    
    <xsl:key name="by-document-additional-reference" match="*[local-name()='SelfBilledInvoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
	
	<xsl:key name="by-idprepaid-in-root" match="*[local-name()='SelfBilledInvoice']/cac:PrepaidPayment" use="cbc:ID"/>
	<!-- key tributos duplicados por linea -->
	<xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)" />
	<!-- key tributos duplicados por cabecera -->
	<xsl:key name="by-tributos-in-root" match="*[local-name()='SelfBilledInvoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
	
	<xsl:key name="by-document-additional-anticipo" match="*[local-name()='SelfBilledInvoice']/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '10']]" use="cbc:DocumentStatusCode"/>

	<xsl:template match="/*">

		<!-- =========================================================================================================================================== 
			Variables
		=========================================================================================================================================== -->


		<!-- Validando que el nombre del archivo coincida con la informacion enviada 
			en el XML -->

		<xsl:variable name="numeroRuc"
			select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)" />

		<xsl:variable name="tipoComprobante"
			select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)" />

		<xsl:variable name="numeroSerie"
			select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)" />

		<xsl:variable name="numeroComprobante"
			select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)" />

		<xsl:variable name="monedaComprobante"
			select="cbc:DocumentCurrencyCode/text()" />

		<xsl:variable name="codigoProducto"
			select="cac:PaymentTerms/cbc:PaymentMeansID" />

		<xsl:variable name="tipoOperacion"
			select="cbc:InvoiceTypeCode/@listID" />

		<!-- =========================================================================================================================================== 
			Datos de la Liquidacion de compra
		=========================================================================================================================================== -->

		<!-- cbc:UBLVersionID No existe el Tag UBL ERROR 2075 -->
		<!-- El valor del Tag UBL es diferente de "2.1" ERROR 2074 -->
		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2075'" />
			<xsl:with-param name="errorCodeValidate" select="'2074'" />
			<xsl:with-param name="node" select="cbc:UBLVersionID" />
			<xsl:with-param name="regexp" select="'^(2.1)$'" />
		</xsl:call-template>

		<!-- cbc:CustomizationID No existe el Tag UBL ERROR 2073 -->
		<!-- El valor del Tag UBL es diferente de "2.0" ERROR 2072 -->
		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2073'" />
			<xsl:with-param name="errorCodeValidate" select="'2072'" />
			<xsl:with-param name="node" select="cbc:CustomizationID" />
			<xsl:with-param name="regexp" select="'^(2.0)$'" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cbc:CustomizationID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1004'" />
			<xsl:with-param name="errorCodeValidate" select="'1003'" />
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode" />
			<xsl:with-param name="regexp" select="'^04$'" />
		</xsl:call-template>

		<!-- Cambio el tipo de operacion sea obligatorio y exista en el catalogo -->
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3205'" />
			<xsl:with-param name="node" select="$tipoOperacion" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'51'" />
			<xsl:with-param name="propiedad" select="'liquidacion'" />
			<xsl:with-param name="idCatalogo" select="$tipoOperacion" />
			<xsl:with-param name="valorPropiedad" select="'1'" />
			<xsl:with-param name="errorCodeValidate" select="'3206'" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4260'" />
			<xsl:with-param name="node"
				select="cbc:InvoiceTypeCode/@name" />
			<xsl:with-param name="regexp"
				select="'^(Tipo de Operacion)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4261'" />
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listSchemeURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="$monedaComprobante"/>
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="$monedaComprobante"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'" />
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listID" />
			<xsl:with-param name="regexp" select="'^(ISO 4217 Alpha)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:DocumentCurrencyCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Currency)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:DocumentCurrencyCode/@listAgencyName" />
			<xsl:with-param name="regexp"
				select="'^(United Nations Economic Commission for Europe)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:InvoiceTypeCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:InvoiceTypeCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Tipo de Documento)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cbc:InvoiceTypeCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<!-- Numero de Serie del nombre del archivo no coincide con el consignado 
			en el contenido del archivo XML -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'1035'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="$numeroSerie != substring(cbc:ID, 1, 4)" />
		</xsl:call-template>

		<!-- Numero de documento en el nombre del archivo no coincide con el consignado 
			en el contenido del XML -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'1036'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="$numeroComprobante != substring(cbc:ID, 6)" />
		</xsl:call-template>

		<!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="regexp" select="'^([L][A-Z0-9]{3}|[0-9]{4})-[0-9]{1,8}?$'" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2458'" />
			<xsl:with-param name="node" select="cac:DeliveryTerms/cac:DeliveryLocation/cbc:LocationTypeCode" />
		</xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'60'" />
			<xsl:with-param name="idCatalogo" select="cac:DeliveryTerms/cac:DeliveryLocation/cbc:LocationTypeCode" />
			<xsl:with-param name="errorCodeValidate" select="'2459'" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2956'" />
			<xsl:with-param name="node" select="cac:TaxTotal" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2509'" />
			<xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount" />
			<xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0 and (round(sum(cac:PrepaidPayment/cbc:PaidAmount)* 100) div 100)  != number(cac:LegalMonetaryTotal/cbc:PrepaidAmount)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaDocumento" select="cbc:DocumentCurrencyCode"/>
		<xsl:variable name="monedaLine" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount/@currencyID"/>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3024'" />
			<xsl:with-param name="node" select="cac:TaxTotal" />
			<xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
		</xsl:call-template>
		
		<xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" />
		<xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)" />
		<xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)" />
		<xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)" />
		<xsl:variable name="MontoBaseIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)" />
		<xsl:variable name="SumatoriaIGVCalculado" select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18" />

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4290'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $SumatoriaIGVCalculado or ($SumatoriaIGV - 1) &gt; $SumatoriaIGVCalculado" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3014'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(cbc:Note[@languageLocaleID='1000']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='1002']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2000']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2001']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2002']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2003']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2004']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2005']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2006']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2007']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2008']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2009']) &gt; 1 or
			count(cbc:Note[@languageLocaleID='2010']) &gt; 1" />
		</xsl:call-template>
		
		<xsl:variable name="totalBaseExoneradas"
			select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)" />
		<xsl:variable name="totalBaseExoneradasxLinea"
			select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)" />
		<xsl:variable name="totalDescuentosGlobalesExo"
			select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '05']]/cbc:Amount)" />
		<xsl:variable name="totalBaseExoneradasxLineaCalc"
			select="$totalBaseExoneradasxLinea - $totalDescuentosGlobalesExo" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4297'" />
			<xsl:with-param name="node"
				select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount" />
			<xsl:with-param name="expresion"
				select="(round(($totalBaseExoneradas + 1 ) * 100) div 100)  &lt; $totalBaseExoneradasxLineaCalc or (round(($totalBaseExoneradas - 1) * 100) div 100)  &gt; $totalBaseExoneradasxLineaCalc" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:variable name="totalBaseInafectas" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
		<xsl:variable name="totalBaseInafectasxLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)" />
		<xsl:variable name="totalDescuentosGlobales" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '06']]/cbc:Amount)" />
		<xsl:variable name="totalCalculado" select="$totalBaseInafectasxLinea - $totalDescuentosGlobales" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4296'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
			<xsl:with-param name="expresion" select="($totalBaseInafectas + 1 ) &lt; $totalCalculado or ($totalBaseInafectas - 1) &gt; $totalCalculado" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:if test="cbc:Note[@languageLocaleID = '2001']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'4022'" />
				<xsl:with-param name="node"
					select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion"
					select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:Note[@languageLocaleID = '2002']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'4023'" />
				<xsl:with-param name="node"
					select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion"
					select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:Note[@languageLocaleID = '2003']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'4024'" />
				<xsl:with-param name="node"
					select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion"
					select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:Note[@languageLocaleID = '2008']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'4244'" />
				<xsl:with-param name="node"
					select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion"
					select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:apply-templates select="cac:InvoiceLine">
			<xsl:with-param name="root" select="." />
			<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
		</xsl:apply-templates>
		
		<xsl:apply-templates select="cac:AccountingSupplierParty"/>
		
		<xsl:apply-templates select="cac:AccountingCustomerParty">
			<xsl:with-param name="root" select="."/>
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:DeliveryTerms/cac:DeliveryLocation/cac:Address"/>
        
        <xsl:apply-templates select="cac:InvoiceLine/cac:Item/cac:AdditionalItemProperty" mode="linea">
        	<xsl:with-param name="root" select="."/>
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
			<xsl:with-param name="cntLineaProd" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
			<xsl:with-param name="cntLineaProd" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:LegalMonetaryTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:PrepaidPayment" mode="cabecera">
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:AdditionalDocumentReference"/>
        
        <xsl:apply-templates select="cac:AllowanceCharge" mode="linea">
        	<xsl:with-param name="root" select="."/>
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cbc:Note"/>
        
        <xsl:apply-templates select="cac:DespatchDocumentReference"/>
        
        <xsl:apply-templates select="cac:Delivery/cac:Shipment">
        	<xsl:with-param name="root" select="."/>
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
            <xsl:with-param name="monedaDocumento" select="cbc:DocumentCurrencyCode" />
        </xsl:apply-templates>
        
        <xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)"/>
        <xsl:variable name="DescuentoGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
        <xsl:variable name="totalValorVenta" select="sum(cac:LegalMonetaryTotal/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalValorVentaCalculado" select="$totalValorVentaxLinea - $DescuentoGlobalesAfectaBI + $cargosGlobalesAfectaBI"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4309'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount" />
            <xsl:with-param name="expresion" select="($totalValorVenta + 1 ) &lt; $totalValorVentaCalculado or ($totalValorVenta - 1) &gt; $totalValorVentaCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="totalImporte" select="sum(cac:LegalMonetaryTotal/cbc:PayableAmount)"/>
        <xsl:variable name="totalPrecioVenta" select="sum(cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount)"/>
        <xsl:variable name="totalCargos" select="sum(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount)"/>
        <xsl:variable name="totalDescuentos" select="sum(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount)"/>
        <xsl:variable name="totalAnticipo" select="sum(cac:LegalMonetaryTotal/cbc:PrepaidAmount)"/>
        <xsl:variable name="totalRedondeo" select="sum(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
		    
        <!-- PAS20211U210700059 - Excel v7 - Correccion las sumatorias se toman de las líneas -->
        <!--xsl:variable name="SumatoriaIR" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxAmount)" /-->
        <!--xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" /-->
        <xsl:variable name="SumatoriaIR" select="sum(cac:InvoiceLine/cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '3000' ] and cbc:TaxableAmount &gt; 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount > 0 ] ) ]/cac:TaxSubtotal [cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '3000' ]]/cbc:TaxAmount )"/>
		    <xsl:variable name="SumatoriaIGV" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" />

        <!-- PAS20211U210700059 - Excel v7 - Correccion se agrega el $ a la variable totalAnticipo -->
        <!--xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta - $SumatoriaIGV - $SumatoriaIR - totalAnticipo - $SumatoriaOtrosTributos + $totalRedondeo"/-->
        <xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta - $SumatoriaIGV - $SumatoriaIR - $totalAnticipo - $SumatoriaOtrosTributos + $totalRedondeo"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4312'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and (($totalImporte + 1 ) &lt; $totalImporteCalculado or ($totalImporte - 1) &gt; $totalImporteCalculado)" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <xsl:variable name="totalPrecioVentaCalculadoIGV" select="$totalValorVenta + $SumatoriaOtrosTributos + ($MontoBaseIGVLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.18"/>
		
		<xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount &gt; 0">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalPrecioVenta + 1) * 100) div 100)  &lt; (round($totalPrecioVentaCalculadoIGV * 100) div 100) or (round(($totalPrecioVenta - 1) * 100) div 100) &gt; (round($totalPrecioVentaCalculadoIGV * 100) div 100)" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>

	</xsl:template>
	
	<!-- =========================================================================================================================================== 
		============================================ Template cac:AccountingSupplierParty =========================================================
	=========================================================================================================================================== -->
	
	<xsl:template match="cac:AccountingSupplierParty">
	
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3090'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
			<xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
		</xsl:call-template>
		
		<xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2014'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
		</xsl:call-template>
		
		<xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2015'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2800'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
			<xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '1' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '4' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '7'" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2021'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName and (string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 1500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2022'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
		            <xsl:with-param name="expresion" select="true()" />
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2022'" />
					<xsl:with-param name="errorCodeValidate" select="'2022'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" /> <!-- de tres a 1500 caracteres que no inicie por espacio -->
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2022'" />
					<xsl:with-param name="errorCodeValidate" select="'2022'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2452'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2453'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2456'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode" />
		</xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'60'" />
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode" />
			<xsl:with-param name="errorCodeValidate" select="'2457'" />
		</xsl:call-template>
		
		<xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '4' or cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '7'">
			<xsl:choose>
	        	<xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID and (string-length(cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15)">
			        <xsl:call-template name="isTrueExpresion">
			            <xsl:with-param name="errorCodeValidate" select="'2802'" />
			            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
			            <xsl:with-param name="expresion" select="true()" />
			        </xsl:call-template>
	        	</xsl:when>
	        	<xsl:otherwise>
			        <xsl:call-template name="regexpValidateElementIfExist">
						<xsl:with-param name="errorCodeValidate" select="'2802'" />
						<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
						<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,}$'" />
					</xsl:call-template>
	        	</xsl:otherwise>
	        </xsl:choose>
		</xsl:if>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line) &gt; 250)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2593'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line" />
		            <xsl:with-param name="expresion" select="true()" />
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2593'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'" /> <!-- de tres a 250 caracteres que no inicie por espacio -->
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2593'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de tres a 250 caracteres que no inicie por espacio -->
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4255'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp"
				select="'^(Documento de Identidad)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4257'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4341'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName" />
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,25}$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4341'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName" />
			<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4342'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4342'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4342'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4339'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4343'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4343'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4343'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4344'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4344'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4344'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4041'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode" />
			<xsl:with-param name="regexp" select="'^(PE)$'" /> <!-- igual a PE -->
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4254'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID" />
			<xsl:with-param name="regexp"
				select="'^(ISO 3166-1)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName" />
			<xsl:with-param name="regexp"
				select="'^(United Nations Economic Commission for Europe)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Country)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
	
	</xsl:template>
	
	<!-- =========================================================================================================================================== 
		============================================ fin - Template cac:AccountingSupplierParty =========================================================
	=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		============================================ Template cac:AccountingCustomerParty =========================================================
	=========================================================================================================================================== -->
	<xsl:template match="cac:AccountingCustomerParty">

		<xsl:param name="tipoOperacion" select="'-'" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3089'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
			<xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName and (string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 1500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4338'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat(' cbc:Line ', cbc:Line)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4338'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4338'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{2,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyName/cbc:Name and (string-length(cac:Party/cac:PartyName/cbc:Name) &gt; 1500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4092'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat(' cbc:Line ', cbc:Line)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4092'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4092'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line) &gt; 200)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4094'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat(' cbc:Line ', cbc:Line)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
		            <xsl:with-param name="regexp" select="'^[^\t\n\r]{2,}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\n]{0,}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4095'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName) &gt; 25" />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:CitySubdivisionName ', cbc:CitySubdivisionName)"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        
        <xsl:if test="not(string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName) &gt; 30)">
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
	            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> <!-- de 1 a 30 caracteres que no inicie por espacio -->
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat(' cbc:CityName ', cbc:CityName)"/>
	        </xsl:call-template>
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
	            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
	            <xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de 1 a 30 caracteres que no inicie por espacio -->
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat(' cbc:CityName ', cbc:CityName)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4096'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName) &gt; 30" />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:CityName ', cbc:CityName)"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4093'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4097'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity) &gt; 30" />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:CountrySubentity ', cbc:CountrySubentity)"/>
        </xsl:call-template>
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4098 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4098'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District) &gt; 30" />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:District ', cbc:District)"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1008'"/>
            <xsl:with-param name="errorCodeValidate" select="'1007'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4257'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'1037'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4341'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName" />
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,25}$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4341'" />
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName" />
			<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4342'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4342'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4342'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4255'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp"
				select="'^(Ubigeos)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4343'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat(' cbc:Line ', cbc:Line)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4343'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4343'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<xsl:choose>
        	<xsl:when test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District and (string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4344'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4344'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4344'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4041'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode" />
			<xsl:with-param name="regexp" select="'^(PE)$'" /> <!-- igual a PE -->
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4254'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID" />
			<xsl:with-param name="regexp"
				select="'^(ISO 3166-1)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName" />
			<xsl:with-param name="regexp"
				select="'^(United Nations Economic Commission for Europe)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Country)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:AccountingCustomerParty ===========================================
	=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:DeliveryTerms/cac:DeliveryLocation/cac:Address ===========================================
	=========================================================================================================================================== -->
	<xsl:template match="cac:DeliveryTerms/cac:DeliveryLocation/cac:Address">

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2454'" />
			<xsl:with-param name="node"
				select="cac:AddressLine/cbc:Line" />
		</xsl:call-template>

		<xsl:choose>
			<xsl:when test="string-length(cac:AddressLine/cbc:Line) &gt; 250 or string-length(cac:AddressLine/cbc:Line) &lt; 3 ">
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2778'" />
					<xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
					<xsl:with-param name="expresion" select="true()" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2778'" />
					<xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'" />
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2778'" />
					<xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{2,}$'"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:choose>
			<xsl:when
				test="string-length(cbc:CitySubdivisionName) &gt; 25 or string-length(cbc:CitySubdivisionName) &lt; 1 ">
				<!-- El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres 
					ERROR 4238 -->
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate"
						select="'4238'" />
					<xsl:with-param name="node"
						select="cbc:CitySubdivisionName" />
					<xsl:with-param name="expresion" select="true()" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4238'" />
					<xsl:with-param name="node" select="cbc:CitySubdivisionName" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4238'" />
					<xsl:with-param name="node" select="cbc:CitySubdivisionName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when
				test="cbc:CityName and (string-length(cbc:CityName) &gt; 30 or string-length(cbc:CityName) &lt; 1 )">
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate"
						select="'4239'" />
					<xsl:with-param name="node" select="cbc:CityName" />
					<xsl:with-param name="expresion" select="true()" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4239'" />
					<xsl:with-param name="node" select="cbc:CityName" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4239'" />
					<xsl:with-param name="node" select="cbc:CityName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2455'" />
			<xsl:with-param name="node" select="cbc:ID" />
		</xsl:call-template>
		
		<xsl:if test="cbc:ID">
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate"
					select="'2917'" />
				<xsl:with-param name="idCatalogo" select="cbc:ID" />
				<xsl:with-param name="catalogo" select="'13'" />
			</xsl:call-template>
		</xsl:if>


		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4255'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		<xsl:choose>
			<xsl:when
				test="string-length(cbc:CountrySubentity) &gt; 30 or string-length(cbc:CountrySubentity) &lt; 1 ">
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate"
						select="'4240'" />
					<xsl:with-param name="node"
						select="cbc:CountrySubentity" />
					<xsl:with-param name="expresion" select="true()" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4240'" />
					<xsl:with-param name="node" select="cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4240'" />
					<xsl:with-param name="node" select="cbc:CountrySubentity" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:choose>
			<xsl:when
				test="string-length(cbc:District) &gt; 30 or string-length(cbc:District) &lt; 1 ">
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate"
						select="'4241'" />
					<xsl:with-param name="node" select="cbc:District" />
					<xsl:with-param name="expresion" select="true()" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4241'" />
					<xsl:with-param name="node" select="cbc:District" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4241'" />
					<xsl:with-param name="node" select="cbc:District" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4041'" />
			<xsl:with-param name="node"
				select="cac:Country/cbc:IdentificationCode" />
			<xsl:with-param name="regexp" select="'^(PE)$'" /> <!-- igual a PE -->
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4254'" />
			<xsl:with-param name="node"
				select="cac:Country/cbc:IdentificationCode/@listID" />
			<xsl:with-param name="regexp"
				select="'^(ISO 3166-1)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cac:Country/cbc:IdentificationCode/@listAgencyName" />
			<xsl:with-param name="regexp"
				select="'^(United Nations Economic Commission for Europe)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cac:Country/cbc:IdentificationCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Country)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
	</xsl:template>



	<!-- =========================================================================================================================================== 
		=================================== fin Template cac:DeliveryTerms/cac:DeliveryLocation/cac:Address	=======================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:InvoiceLine =========================================== 
		=========================================================================================================================================== -->

	<xsl:template match="cac:InvoiceLine">

		<xsl:variable name="nroLinea" select="cbc:ID" />
		<xsl:variable name="valorVenta" select="cbc:LineExtensionAmount" />
		<xsl:param name="root" />
		<xsl:param name="tipoOperacion" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2023'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2023'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<!-- Excel v6 PAS20211U210400011 - Se pasa de 5 a 3-->
      <xsl:with-param name="regexp"
				select="'^(?!0*$)\d{1,3}$'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2752'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTenDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'2024'" />
			<xsl:with-param name="errorCodeValidate" select="'2025'" />
			<xsl:with-param name="node" select="cbc:InvoicedQuantity" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'2024'" />
			<xsl:with-param name="node"
				select="cbc:InvoicedQuantity" />
			<xsl:with-param name="expresion"
				select="cbc:InvoicedQuantity = 0" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>

		<xsl:if test="cbc:InvoicedQuantity">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2883'" />
				<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCode" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate"
				select="'2936'" />
			<xsl:with-param name="idCatalogo"
				select="cbc:InvoicedQuantity/@unitCode" />
			<xsl:with-param name="catalogo" select="'03'" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4258'" />
			<xsl:with-param name="node"
				select="cbc:InvoicedQuantity/@unitCodeListID" />
			<xsl:with-param name="regexp"
				select="'^(UN/ECE rec 20)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4259'" />
			<xsl:with-param name="node"
				select="cbc:InvoicedQuantity/@unitCodeListAgencyName" />
			<xsl:with-param name="regexp"
				select="'^(United Nations Economic Commission for Europe)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2026'" />
			<xsl:with-param name="node"
				select="cac:Item/cbc:Description" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>
		
		<xsl:choose>
			<xsl:when test="string-length(cac:Item/cbc:Description) &gt; 500 or string-length(cac:Item/cbc:Description) &lt; 1 ">
				<xsl:call-template name="isTrueExpresionIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2027'" />
					<xsl:with-param name="node" select="cac:Item/cbc:Description" />
					<xsl:with-param name="expresion" select="true()" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
		
		<xsl:choose>
        	<xsl:when test="cac:Item/cac:SellersItemIdentification/cbc:ID and (string-length(cac:Item/cac:SellersItemIdentification/cbc:ID) &gt; 30)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4269'" />
		            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select="false()" />
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4269'" />
					<xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
					<xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{0,})$'" />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4269'" />
					<xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		
		<!--xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4332'" />
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template-->

		<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != ''">
 		   <xsl:call-template name="findElementInCatalog">
			     <xsl:with-param name="errorCodeValidate" select="'4332'" />
			     <xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
			     <xsl:with-param name="catalogo" select="'25'" />
			     <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
			     <xsl:with-param name="isError" select="false()" />
		   </xsl:call-template>
		</xsl:if>
    
		<xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and string-length(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode) = 8">
	 		
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4337'" />
	            <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
	            <xsl:with-param name="expresion" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and substring(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode, 3, 6) = '000000' or cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode and substring(cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode, 5, 4) = '0000'" />
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>	        
        </xsl:if>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4254'" />
			<xsl:with-param name="node"
				select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID" />
			<xsl:with-param name="regexp" select="'^(UNSPSC)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(GS1 US)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Item Classification)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTenDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2068'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2369'" />
			<xsl:with-param name="node"
				select="cac:Price/cbc:PriceAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2640'" />
			<xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
			<xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and cac:Price/cbc:PriceAmount &gt; 0" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cac:TaxTotal/cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2028'" />
			<xsl:with-param name="node"
				select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2409'" />
				<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice" />
				<xsl:with-param name="expresion" select="count(cac:PricingReference/cac:AlternativeConditionPrice) &gt; 1" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
			</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'" />
			<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Tipo de Precio)$'"/>
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'" />
			<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'" />
			<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode/@listURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">

			<xsl:call-template
				name="existAndValidateValueTenDecimal">
				<xsl:with-param name="errorCodeValidate"
					select="'2367'" />
				<xsl:with-param name="node" select="cbc:PriceAmount" />
				<xsl:with-param name="isGreaterCero" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist"
					select="'2410'" />
				<xsl:with-param name="node"
					select="cbc:PriceTypeCode" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="catalogo" select="'16'" />
				<xsl:with-param name="idCatalogo"
					select="cbc:PriceTypeCode" />
				<xsl:with-param name="errorCodeValidate"
					select="'2410'" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4252'" />
				<xsl:with-param name="node"
					select="cbc:PriceTypeCode/@listName" />
				<xsl:with-param name="regexp"
					select="'^(Tipo de Precio)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4251'" />
				<xsl:with-param name="node"
					select="cbc:PriceTypeCode/@listAgencyName" />
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4253'" />
				<xsl:with-param name="node"
					select="cbc:PriceTypeCode/@listURI" />
				<xsl:with-param name="regexp"
					select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>

		</xsl:for-each>

		<!-- Validaciones de sumatoria -->
		<xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount" />
    <!-- PAS20211U210700059 - Excel v7 - Correccion-->
		<!--xsl:variable name="ValorVentaUnitarioxItem" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount" /-->
    <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount" />
		<xsl:variable name="ImpuestosItem" select="cac:TaxTotal/cbc:TaxAmount" />
		<xsl:variable name="DsctosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)" />
		<xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)" />
		<xsl:variable name="CargosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)" />
		<xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)" />
		<xsl:variable name="CantidadItem" select="cbc:InvoicedQuantity" />
		<xsl:variable name="PrecioUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount)" />
		<xsl:variable name="PrecioReferencialUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount)" />
		<xsl:variable name="PrecioUnitarioCalculado" select="($ValorVentaxItem + $ImpuestosItem - $DsctosNoAfectanBI + $CargosNoAfectanBI) div ( $CantidadItem)" />
		<xsl:variable name="ValorVentaReferencialxItemCalculado" select="($PrecioReferencialUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI" />
		<xsl:variable name="ValorVentaxItemCalculado" select="($ValorVentaUnitarioxItem * $CantidadItem)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4287'" />
			<xsl:with-param name="node"
				select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount" />
			<xsl:with-param name="expresion"
				select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and ($PrecioUnitarioxItem + 1 ) &lt; $PrecioUnitarioCalculado or ($PrecioUnitarioxItem - 1) &gt; $PrecioUnitarioCalculado" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3224'" />
			<xsl:with-param name="node"
				select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount" />
			<xsl:with-param name="expresion"
				select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0])" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3234'" />
			<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode != '02']/cbc:PriceAmount" />
			<xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode !='02']/cbc:PriceAmount &gt; 0 and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0]" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2370'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2370'" />
			<xsl:with-param name="node"
				select="cbc:LineExtensionAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

    <!-- PAS20211U210700059 - Excel v7 - Correccion de la validación 4288 -->
		<!--xsl:if test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996'"-->
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4288'" />
				<xsl:with-param name="node" select="cbc:LineExtensionAmount" />
				<xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaReferencialxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaReferencialxItemCalculado)" />
        <!--xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" /-->
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
	
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4288'" />
				<xsl:with-param name="node" select="cbc:LineExtensionAmount" />
				<xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and (($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		<!--/xsl:if-->
		
		<xsl:variable name="monedaLine" select="cac:Price/cbc:PriceAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:Price/cbc:PriceAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:LineExtensionAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:LineExtensionAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3195'" />
			<xsl:with-param name="node" select="cac:TaxTotal" />
			<xsl:with-param name="expresion"
				select="not(cac:TaxTotal)" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'3021'" />
			<xsl:with-param name="errorCodeValidate"
				select="'3021'" />
			<xsl:with-param name="node"
				select="cac:TaxTotal/cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cbc:TaxAmount" />
		<xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9999']]/cbc:TaxAmount)" />

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9999']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4293'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="(round(($totalImpuestosxLinea + 1 )*100) div 100) &lt; $SumatoriaImpuestosxLinea or (round(($totalImpuestosxLinea - 1 )*100) div 100) &gt; $SumatoriaImpuestosxLinea" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3026'" />
			<xsl:with-param name="node"
				select="cac:TaxTotal/cbc:TaxAmount" />
			<xsl:with-param name="expresion"
				select="count(cac:TaxTotal) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'3031'" />
			<xsl:with-param name="errorCodeValidate" select="'3031'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:variable name="TributoISCxLinea">
			<xsl:choose>
				<xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount">
					<xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'0'" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="BaseIGVIVAPxLinea" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)" />
		<xsl:variable name="BaseIGVIVAPxLineaCalculado" select="$valorVenta + $TributoISCxLinea" />

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4294'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$BaseIGVIVAPxLinea != cbc:LineExtensionAmount" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]">
			<xsl:variable name="BaseIGVIVAPxLinea" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxableAmount)" />
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4294'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$BaseIGVIVAPxLinea != cbc:LineExtensionAmount" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3105'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9996' or text() = '9997' or text() = '9998']) &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

		<xsl:apply-templates select="cac:Delivery"
			mode="linea">
			<xsl:with-param name="nroLinea" select="$nroLinea" />
		</xsl:apply-templates>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2037'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:if test="$tipoOperacion = '0503'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2466'" />
				<xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
				<xsl:with-param name="expresion" select="count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '6000']) = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2467'" />
				<xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
				<xsl:with-param name="expresion" select="count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '6004']) = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2468'" />
				<xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
				<xsl:with-param name="expresion" select="count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '6005']) = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2469'" />
				<xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
				<xsl:with-param name="expresion" select="count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '6006']) = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) &gt; 1">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3223'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="not(
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
			   (cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
			   (cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
			   (cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2)or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 2) or
				(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '3000' and cbc:TaxableAmount &gt; 0] and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999' and cbc:TaxableAmount &gt; 0] and count(cac:TaxTotal/cac:TaxSubtotal[cbc:TaxableAmount &gt; 0]) = 3))" />
			</xsl:call-template>
		</xsl:if>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:InvoiceLine ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:InvoiceLine/cac:Item/cac:AdditionalItemProperty ===========================================
		=========================================================================================================================================== -->
	<xsl:template match="cac:InvoiceLine/cac:Item/cac:AdditionalItemProperty" mode="linea">
		<xsl:param name="nroLinea" />
		<xsl:param name="tipoOperacion" />
		<xsl:param name="root" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4235'" />
			<xsl:with-param name="node" select="cbc:Name" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:NameCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Propiedad del item)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Guia Relacionada : ', cbc:NameCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:NameCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Guia Relacionada : ', cbc:NameCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cbc:NameCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Guia Relacionada : ', cbc:NameCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:variable name="codigoConcepto" select="cbc:NameCode" />

		<xsl:choose>
			<xsl:when
				test="$codigoConcepto = '6000' or $codigoConcepto = '6004' or $codigoConcepto = '6005' or $codigoConcepto = '6006'">
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist"
						select="'3064'" />
					<xsl:with-param name="node" select="cbc:Value" />
					<xsl:with-param name="descripcion"
						select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>

		<xsl:if test="$codigoConcepto = '6004'">
			<xsl:choose>
				<xsl:when test="string-length(cbc:Value) &gt; 6 or string-length(cbc:Value) &lt; 1 ">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'4280'" />
						<xsl:with-param name="node" select="cbc:Value" />
						<xsl:with-param name="expresion" select="true()" />
						<xsl:with-param name="isError" select="false()" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="regexpValidateElementIfExist">
						<xsl:with-param name="errorCodeValidate" select="'4280'" />
						<xsl:with-param name="node" select="cbc:Value" />
						<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
						<xsl:with-param name="isError" select="false()" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:Item/cac:AdditionalItemProperty ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal ===========================================
		=========================================================================================================================================== -->

	<xsl:template match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal">
		<xsl:param name="nroLinea" />
		<xsl:param name="cntLineaProd" />
		<xsl:param name="root" />
		<xsl:param name="valorVenta" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>
		
		<xsl:variable name="tipoOperacion"
			select="$root/cbc:InvoiceTypeCode/@listID" />
		<xsl:variable name="codigoTributo"
			select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		<xsl:variable name="codTributo">
			<xsl:choose>
				<xsl:when test="$codigoTributo = '1000'">
					<xsl:value-of select="'igv'" />
				</xsl:when>
				<xsl:when test="$codigoTributo = '1016'">
					<xsl:value-of select="'iva'" />
				</xsl:when>
				<xsl:when test="$codigoTributo = '9995'">
					<xsl:value-of select="'exp'" />
				</xsl:when>
				<xsl:when test="$codigoTributo = '9996'">
					<xsl:value-of select="'gra'" />
				</xsl:when>
				<xsl:when test="$codigoTributo = '9997'">
					<xsl:value-of select="'exo'" />
				</xsl:when>
				<xsl:when test="$codigoTributo = '9998'">
					<xsl:value-of select="'ina'" />
				</xsl:when>
				<!--PAS20191U210000012 - add test="$codigoTributo = '7152' -->
				<xsl:when test="$codigoTributo = '7152'">
					<xsl:value-of select="'oth'" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''" />
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
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'2033'" />
			<xsl:with-param name="errorCodeValidate" select="'2033'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:if test="$codigoTributo = '9997' or $codigoTributo = '9998'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3110'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo = '9996'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3111'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0.06 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16'] and cbc:TaxAmount = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3110'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '37'] and cbc:TaxAmount != 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo = '1000'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3111'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0.06 and cbc:TaxAmount = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

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

		<xsl:variable name="MontoTributoCalculado" select="$BaseImponible * $Tasa * 0.01" />

		<xsl:if
			test="cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3103'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo, ', MontoTributoCalculado: ', $MontoTributoCalculado, ', MontoTributo: ', $MontoTributo, ', BaseImponible: ', $BaseImponible, ', Tasa: ', $Tasa)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2992'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'3102'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="regexp"
				select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:if test="$codigoTributo = '9996'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'2993'" />
				<xsl:with-param name="node"
					select="cac:TaxCategory/cbc:Percent" />
				<xsl:with-param name="expresion"
					select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17'] and cac:TaxCategory/cbc:Percent = 0" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo = '1000'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'2993'" />
				<xsl:with-param name="node"
					select="cac:TaxCategory/cbc:Percent" />
				<xsl:with-param name="expresion"
					select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
				<xsl:with-param name="descripcion"
					select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo != '3000' and $codigoTributo != '9999'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2371'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo = '3000' or $codigoTributo = '9999'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3050'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
				<xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo != '3000' and $codigoTributo != '9999' and cbc:TaxableAmount &gt; 0">
			<xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'07'" />
				<xsl:with-param name="propiedad" select="$codTributo" />
				<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
				<xsl:with-param name="valorPropiedad" select="'1'" />
				<xsl:with-param name="errorCodeValidate" select="'2040'" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'2036'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3067'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2996'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'3051'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate" select="'2377'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'3031'" />
			<xsl:with-param name="errorCodeValidate" select="'3031'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:variable name="TributoISCxLinea">
			<xsl:choose>
				<xsl:when
					test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount">
					<xsl:value-of
						select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'0'" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="BaseIGVIVAPxLinea"
			select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016']]/cbc:TaxableAmount)" />
		<xsl:variable name="BaseIGVIVAPxLineaCalculado"
			select="$valorVenta + $TributoISCxLinea" />
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2033'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2033'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:if test="$codigoTributo = '9999' and cbc:TaxableAmount > 0">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3109'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="((cbc:TaxAmount + 1) &lt; (round((cac:TaxCategory/cbc:Percent)*(cbc:TaxableAmount)) div 100)) or ((round((cbc:TaxAmount - 1) &gt; (cac:TaxCategory/cbc:Percent)*(cbc:TaxableAmount)) div 100))" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$codigoTributo = '3000'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2464'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="((cbc:TaxAmount + 1) &lt; (round((cac:TaxCategory/cbc:Percent)*(cbc:TaxableAmount)) div 100)) or ((round((cbc:TaxAmount - 1) &gt; (cac:TaxCategory/cbc:Percent)*(cbc:TaxableAmount)) div 100))" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2992'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:if test="$codigoTributo = '3000'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4237'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
				<xsl:with-param name="expresion" select="cac:TaxCategory/cbc:Percent != 1.5 and cac:TaxCategory/cbc:Percent != 4.0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'3102'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="regexp"
				select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'2036'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3067'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2996'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'3051'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2377'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'3031'" />
			<xsl:with-param name="errorCodeValidate" select="'3031'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2033'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2033'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2992'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'3102'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cbc:Percent" />
			<xsl:with-param name="regexp"
				select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'2036'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3067'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2996'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'3051'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2377'" />
			<xsl:with-param name="descripcion"
				select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)" />
		</xsl:call-template>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:TaxTotal =========================================== 
		=========================================================================================================================================== -->
	<xsl:template match="cac:TaxTotal" mode="linea">

		<xsl:param name="root" />
		<xsl:param name="nroLinea" />
		<xsl:param name="valorVenta"/>
		<xsl:param name="cntLineaProd"/>
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>
		
		<xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID" />
		

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'3020'" />
			<xsl:with-param name="errorCodeValidate" select="'3020'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
		</xsl:call-template>

		<xsl:variable name="totalImpuestos"
			select="cbc:TaxAmount" />
		<xsl:variable name="SumatoriaImpuestos"
			select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'or text() = '1016' or text() = '7152' or text() = '9999' or text() = '2000']]/cbc:TaxAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4301'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="expresion"
				select="(round(($totalImpuestos + 1 ) * 100) div 100) &lt; (round($SumatoriaImpuestos * 100) div 100) or (round(($totalImpuestos - 1) * 100) div 100) &gt; (round($SumatoriaImpuestos * 100) div 100)" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:variable name="totalBaseIGV" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)" />
		<xsl:variable name="totalBaseIVAP" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)" />
		<xsl:variable name="totalBaseIGVxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)" />
		<xsl:variable name="totalBaseIVAPxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)" />
		<xsl:variable name="totalDescuentosGlobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '02' or text() = '04']]/cbc:Amount)" />
		<xsl:variable name="totalCargosGobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '49']]/cbc:Amount)" />
		<xsl:variable name="totalBaseIGVCalculado" select="$totalBaseIGVxLinea - $totalDescuentosGlobales + $totalCargosGobales" />

		<xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4299'" />
				<xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="($totalBaseIGV + 1 ) &lt; $totalBaseIGVCalculado or ($totalBaseIGV - 1) &gt; $totalBaseIGVCalculado" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>
		
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
		
		<xsl:variable name="BaseIGVIVAPxLinea" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="BaseIGVIVAPxLineaCalculado" select="$valorVenta + $TributoISCxLinea"/>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:TaxTotal =========================================== 
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:TaxTotal/cac:TaxSubtotal ===========================================
		=========================================================================================================================================== -->
	<xsl:template match="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
		<xsl:param name="root" />
		<xsl:param name="nroLinea" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:variable name="codigoTributo"
			select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'3003'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2999'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'2048'" />
			<xsl:with-param name="errorCodeValidate" select="'2048'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'3059'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'3007'" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3068'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2054'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'3007'" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate" select="'2964'" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2052'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2961'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'3003'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2999'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2048'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2048'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:if
			test="$codigoTributo = '9997' or $codigoTributo = '9998'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'3000'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion"
					select="cbc:TaxAmount != 0" />
				<xsl:with-param name="descripcion"
					select="concat('Error Tributo ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'3059'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate" select="'3007'" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3068'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2054'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'2964'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2052'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2961'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template
				name="existAndValidateValueTwoDecimal">
				<xsl:with-param name="errorCodeNotExist"
					select="'3003'" />
				<xsl:with-param name="errorCodeValidate"
					select="'2999'" />
				<xsl:with-param name="node"
					select="cbc:TaxableAmount" />
				<xsl:with-param name="isGreaterCero" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Error Tributo ', $codigoTributo)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2048'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2048'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'3059'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate"
				select="'3007'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3068'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2054'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'2964'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2052'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate" select="'2961'" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'3003'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'2470'" />
			<xsl:with-param name="errorCodeValidate" select="'2470'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2048'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2048'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'3059'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate"
				select="'3007'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3068'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2054'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'2964'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2052'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2961'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'3003'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2999'" />
			<xsl:with-param name="node" select="cbc:TaxableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist"
				select="'2048'" />
			<xsl:with-param name="errorCodeValidate"
				select="'2048'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'3059'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="errorCodeValidate"
				select="'3007'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'3068'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion"
				select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2054'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad" select="'name'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:Name" />
			<xsl:with-param name="errorCodeValidate"
				select="'2964'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist"
				select="'2052'" />
			<xsl:with-param name="node"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'" />
			<xsl:with-param name="propiedad"
				select="'UN_ECE_5153'" />
			<xsl:with-param name="idCatalogo"
				select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="valorPropiedad"
				select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode" />
			<xsl:with-param name="errorCodeValidate"
				select="'2961'" />
			<xsl:with-param name="descripcion"
				select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

	</xsl:template>
	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:TaxTotal/cac:TaxSubtotal ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:TaxTotal =========================================== 
		=========================================================================================================================================== -->

	<xsl:template match="cac:TaxTotal" mode="cabecera">

		<xsl:param name="root" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:variable name="totalBaseGratuitas"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
		<xsl:variable name="totalBaseGratuitasxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4298'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
			<xsl:with-param name="expresion"
				select="($totalBaseGratuitas + 1 ) &lt; $totalBaseGratuitasxLinea or ($totalBaseGratuitas - 1) &gt; $totalBaseGratuitasxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'2641'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
			<xsl:with-param name="expresion"
				select="$root/cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and (not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0)" />
		</xsl:call-template>

		<xsl:if test="$root/cbc:Note[@languageLocaleID = '1002']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate"
					select="'2416'" />
				<xsl:with-param name="node"
					select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
				<xsl:with-param name="expresion"
					select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
			</xsl:call-template>
		</xsl:if>

		<xsl:variable name="totalGratuitas"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount" />
		<xsl:variable name="totalGratuitasxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4311'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount" />
			<xsl:with-param name="expresion"
				select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<!--xsl:variable name="totalGratuitas"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:LineExtensionAmount" />
		<xsl:variable name="totalGratuitasxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:LineExtensionAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4345'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:LineExtensionAmount" />
			<xsl:with-param name="expresion"
				select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template-->

		<xsl:variable name="totalGratuitas"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxableAmount" />
		<!-- Versión 5 excel -->
		<!--xsl:variable name="totalGratuitasxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxableAmount)" /-->
		<xsl:variable name="totalGratuitasxLinea"
			select="sum($root/cac:InvoiceLine[cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '3000' ] and cbc:TaxableAmount &gt; 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount &gt; 0 ] ) ]]/cbc:LineExtensionAmount )" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4345'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxableAmount" />
			<xsl:with-param name="expresion"
				select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:variable name="totalRetenciones" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxAmount" />
		<!-- Versión 5 excel -->
    <!--xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxAmount)" /-->
    <xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '3000' ] and cbc:TaxableAmount > 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount > 0 ] ) ]/cac:TaxSubtotal [cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '3000' ]]/cbc:TaxAmount )" />
		<xsl:variable name="totalAnticipoRet"
      select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() ='61']]/cbc:Amount)" />
    <xsl:variable name="totalRetencionesxLinea"
      select="$totalGratuitasxLinea - $totalAnticipoRet" />
		<!-- Versión 5 excel -->
		<!--xsl:if test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode and cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode = '3000'"-->
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4346'" />
				<xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($totalRetenciones + 1 ) &lt; $totalRetencionesxLinea or ($totalRetenciones - 1) &gt; $totalRetencionesxLinea" />
        <xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		<!--/xsl:if-->

		<xsl:variable name="totalBaseOtros"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
		<xsl:variable name="totalBaseOtrosxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4304'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
			<xsl:with-param name="expresion"
				select="($totalBaseOtros + 1 ) &lt; $totalBaseOtrosxLinea or ($totalBaseOtros - 1) &gt; $totalBaseOtrosxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:variable name="totalOtros"
			select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
		<xsl:variable name="totalOtrosxLinea"
			select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4306'" />
			<xsl:with-param name="node"
				select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
			<xsl:with-param name="expresion"
				select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

	</xsl:template>
	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:TaxTotal =========================================== 
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:LegalMonetaryTotal ===========================================
		=========================================================================================================================================== -->

	<xsl:template match="cac:LegalMonetaryTotal" mode="cabecera">

		<xsl:param name="root" />
		<xsl:param name="nroLinea" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>
		
		<xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
		<xsl:variable name="totalValorVenta" select="sum(cbc:LineExtensionAmount)" />
		<xsl:variable name="totalPrecioVenta" select="sum(cbc:TaxInclusiveAmount)" />
		<xsl:variable name="totalCargos" select="sum(cbc:ChargeTotalAmount)" />
		<xsl:variable name="totalImporte" select="sum(cbc:PayableAmount)" />
		<xsl:variable name="totalDescuentos" select="sum(cbc:AllowanceTotalAmount)" />
		<xsl:variable name="totalAnticipo" select="sum(cbc:PrepaidAmount)" />
		<xsl:variable name="totalRedondeo" select="sum(cbc:PayableRoundingAmount)" />
		<xsl:variable name="SumatoriaISC" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)" />
		<xsl:variable name="SumatoriaICBPER" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount)" />
		<xsl:variable name="SumatoriaOtrosTributos" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
		<xsl:variable name="SumatoriaIR" select="sum($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '3000']]/cbc:TaxAmount)" />
		<xsl:variable name="MontoBaseIGVLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)" />
		<xsl:variable name="MontoCargosAfectoBI" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)" />
		<xsl:variable name="MontoDescuentoAfectoBI" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)" />
		<xsl:variable name="totalValorVentaxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)" />
		<xsl:variable name="DescuentoGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)" />
		<xsl:variable name="cargosGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)" />
			
		<xsl:variable name="totalImporteCalculado" select="$totalValorVenta + $totalCargos - $SumatoriaIR - $totalDescuentos - $totalAnticipo + $totalRedondeo" />
		<xsl:variable name="totalPrecioVentaCalculadoIGV" select="$totalValorVenta + $SumatoriaISC + $SumatoriaICBPER + $SumatoriaOtrosTributos + ($MontoBaseIGVLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.18" />
		<xsl:variable name="totalValorVentaCalculado" select="$totalValorVentaxLinea - $DescuentoGlobalesAfectaBI + $cargosGlobalesAfectaBI" />

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2591'" />
			<xsl:with-param name="node" select="cbc:LineExtensionAmount" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>

		<xsl:call-template
			name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'2031'" />
			<xsl:with-param name="node"
				select="cbc:LineExtensionAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:LineExtensionAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:LineExtensionAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2592'" />
			<xsl:with-param name="node" select="cbc:TaxInclusiveAmount" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
		</xsl:call-template>
		
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3019'"/>
            <xsl:with-param name="node" select="cbc:TaxInclusiveAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:TaxInclusiveAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:TaxInclusiveAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate"
				select="'4314'" />
			<xsl:with-param name="node"
				select="cbc:PayableRoundingAmount" />
			<xsl:with-param name="expresion"
				select="cbc:PayableRoundingAmount &gt; 1 or cbc:PayableRoundingAmount &lt; -1" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:PayableRoundingAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:PayableRoundingAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

		<xsl:call-template name="existAndValidateValueTwoDecimal">
			<xsl:with-param name="errorCodeNotExist" select="'2062'" />
			<xsl:with-param name="errorCodeValidate" select="'2062'" />
			<xsl:with-param name="node" select="cbc:PayableAmount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:PayableAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:PayableAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:LegalMonetaryTotal ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== cac:PrepaidPayment =========================================== 
		=========================================================================================================================================== -->

	<xsl:template match="cac:PrepaidPayment" mode="cabecera">
		<xsl:param name="root" />
		<xsl:param name="nroLinea" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3211'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="cbc:PaidAmount and not(string(cbc:ID))" />
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3212'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3213'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:ID)) = 0" />
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4255'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeName" />
			<xsl:with-param name="regexp" select="'^(Anticipo)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2503'" />
			<xsl:with-param name="node" select="cbc:PaidAmount" />
			<xsl:with-param name="expresion" select="cbc:PaidAmount and cbc:PaidAmount &lt;= 0" />
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)" />
		</xsl:call-template>

		<xsl:if test="cbc:PaidAmount and cbc:PaidAmount &gt; 0">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3220'" />
				<xsl:with-param name="node" select="$root/cac:LegalMonetaryTotal/cbc:PrepaidAmount" />
				<xsl:with-param name="expresion" select="not($root/cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0)" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="monedaLine" select="cbc:PaidAmount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:PaidAmount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin cac:PrepaidPayment =========================================== 
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:AdditionalDocumentReference ===========================================
		=========================================================================================================================================== -->
	<xsl:template match="cac:AdditionalDocumentReference">
		
		<xsl:param name="root" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:if test="cbc:DocumentTypeCode = '10'">

			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3214'" />
				<xsl:with-param name="node" select="cbc:DocumentStatusCode" />
				<xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:DocumentStatusCode)) &lt; 1" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3215'" />
				<xsl:with-param name="node" select="cbc:DocumentStatusCode" />
				<xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:DocumentStatusCode)) &gt; 1" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3216'" />
				<xsl:with-param name="node" select="cbc:DocumentStatusCode" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4252'" />
				<xsl:with-param name="node"
					select="cbc:DocumentStatusCode/@listName" />
				<xsl:with-param name="regexp" select="'^(Anticipo)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4251'" />
				<xsl:with-param name="node"
					select="cbc:DocumentStatusCode/@listAgencyName" />
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2521'" />
				<xsl:with-param name="node" select="cbc:ID" />
				<xsl:with-param name="regexp" select="'^(([L][0-9A-Z]{3}-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([E][0][0][1]-[0-9]{1,8}))$'" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

		</xsl:if>

		<xsl:if test="cbc:DocumentStatusCode">
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2465'" />
				<xsl:with-param name="node" select="cbc:DocumentTypeCode" />
				<xsl:with-param name="regexp" select="'^(10)$'" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'3217'" />
				<xsl:with-param name="errorCodeValidate" select="'3217'" />
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
				<xsl:with-param name="regexp" select="'^[\d]{11}$'" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2520'" />
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeID" />
			</xsl:call-template>
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2520'" />
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeID" />
				<xsl:with-param name="regexp" select="'^(6)$'" />
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4255'" />
				<xsl:with-param name="node"
					select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeName" />
				<xsl:with-param name="regexp"
					select="'^(Documento de Identidad)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4256'" />
				<xsl:with-param name="node"
					select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName" />
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>

			<xsl:call-template
				name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate"
					select="'4257'" />
				<xsl:with-param name="node"
					select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeURI" />
				<xsl:with-param name="regexp"
					select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'" />
				<xsl:with-param name="isError" select="false()" />
				<xsl:with-param name="descripcion"
					select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Documento Relacionado)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'4010'" />
			<xsl:with-param name="errorCodeValidate" select="'4010'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,30}$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2365'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>
		
		<!-- Versión 5 excel-->
    <!--xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'12'" />
			<xsl:with-param name="idCatalogo" select="cbc:DocumentTypeCode" />
			<xsl:with-param name="errorCodeValidate" select="'4009'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template-->

    <!-- Versión 5 excel-->
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
      <xsl:with-param name="errorCodeValidate" select="'4009'"/>
      <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
      <xsl:with-param name="regexp" select="'^(10|99)$'"/>
      <xsl:with-param name="isError" select ="false()"/>
      <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
    </xsl:call-template>
              
		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Documento Relacionado)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cbc:DocumentTypeCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

	</xsl:template>
	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:AdditionalDocumentReference ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:AllowanceCharge ===========================================
		=========================================================================================================================================== -->
	<xsl:template match="cac:AllowanceCharge" mode="linea">
		<xsl:param name="nroLinea" />
		<xsl:param name="root" />
		<xsl:variable name="monedaDocumento" select="$root/cbc:DocumentCurrencyCode"/>

		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode" />

		<xsl:choose>

			<xsl:when test="$codigoCargoDescuento = '04' or $codigoCargoDescuento = '05' or $codigoCargoDescuento = '06' or $codigoCargoDescuento = '61'">

				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3114'" />
					<xsl:with-param name="node" select="cbc:ChargeIndicator" />
					<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() != 'false'" />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)" />
				</xsl:call-template>

			</xsl:when>

		</xsl:choose>

		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3072'" />
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="catalogo" select="'53'" />
			<xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode" />
			<xsl:with-param name="errorCodeValidate" select="'3071'" />
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4251'" />
			<xsl:with-param name="node"
				select="cbc:AllowanceChargeReasonCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4252'" />
			<xsl:with-param name="node"
				select="cbc:AllowanceChargeReasonCode/@listName" />
			<xsl:with-param name="regexp"
				select="'^(Cargo/descuento)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4253'" />
			<xsl:with-param name="node"
				select="cbc:AllowanceChargeReasonCode/@listURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion"
				select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>

		<xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2968'" />
			<xsl:with-param name="node" select="cbc:Amount" />
			<xsl:with-param name="isGreaterCero" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)" />
		</xsl:call-template>
		
		<xsl:variable name="monedaLine" select="cbc:Amount/@currencyID"/>
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2337'"/>
			<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
			<xsl:with-param name="expresion" select="$monedaDocumento != $monedaLine"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		</xsl:call-template>

	</xsl:template>
	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:Allowancecharge ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cbc:Note =========================================== 
		=========================================================================================================================================== -->
	<xsl:template match="cbc:Note">

		<xsl:if test="@languageLocaleID">
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'" />
				<xsl:with-param name="idCatalogo" select="@languageLocaleID" />
				<xsl:with-param name="catalogo" select="'52'" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:choose>
        	<xsl:when test="(string-length(text()) &gt; 200)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3006'" />
		            <xsl:with-param name="node" select="text()" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="existAndRegexpValidateElement">
		        	<xsl:with-param name="errorCodeNotExist" select="'3006'"/>
					<xsl:with-param name="errorCodeValidate" select="'3006'"/>
					<xsl:with-param name="node" select="text()"/>
					 <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> 
					<xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'3006'" />
					<xsl:with-param name="errorCodeValidate" select="'3006'" />
					<xsl:with-param name="node" select="text()" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)" />
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cbc:Note ====================================================== 
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:DespatchDocumentReference ===========================================
		=========================================================================================================================================== -->

	<xsl:template match="cac:DespatchDocumentReference">

		<!-- cac:DespatchDocumentReference/cbc:ID "Si el Tag UBL existe, el formato del Tag UBL es diferente a:  
        (.){1,}-[0-9]{1,}
        [T][A-Z0-9]{3}-[0-9]{1,8}  Ajustado en PAS20221U210700001
        [0-9]{4}-[0-9]{1,8}" 
        OBSERV 4006 -->
		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4006'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="regexp" select="'^(([T][A-Z0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0-9]{2}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2364'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', cbc:ID)) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'4005'" />
			<xsl:with-param name="errorCodeValidate" select="'4005'" />
			<xsl:with-param name="node" select="cbc:DocumentTypeCode" />
			<xsl:with-param name="regexp" select="'^(31)|(09)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'" />
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'" />
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName" />
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'" />
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)" />
		</xsl:call-template>


	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:DespatchDocumentReference ===========================================
		=========================================================================================================================================== -->

	<!-- =========================================================================================================================================== 
		=========================================== Template cac:Delivery/cac:Shipment ===========================================
		=========================================================================================================================================== -->
	<xsl:template match="cac:Delivery/cac:Shipment">
		<xsl:param name="tipoOperacion" select="'-'" />

		<xsl:if test="cbc:ID">
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4249'" />
				<xsl:with-param name="idCatalogo" select="cbc:ID" />
				<xsl:with-param name="catalogo" select="'20'" />
				<xsl:with-param name="isError" select="false()" />
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4255'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeName" />
			<xsl:with-param name="regexp"
				select="'^(Motivo de Traslado)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4256'" />
			<xsl:with-param name="node"
				select="cbc:ID/@schemeAgencyName" />
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4257'" />
			<xsl:with-param name="node" select="cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp"
				select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20)$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

		<xsl:choose>
			<xsl:when test="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID and (string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID) &gt; 8 or string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID) &lt; 6 )">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'4167'" />
					<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID" />
					<xsl:with-param name="expresion" select="true()" />
					<xsl:with-param name="isError" select="false()" />
					<xsl:with-param name="descripcion" select="concat(' cbc:LicensePlateID 01 ', string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID))" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4167'" />
					<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID" />
					<xsl:with-param name="regexp" select="'^[A-Z0-9\-\s]{5,}$'" />
					<xsl:with-param name="descripcion" select="concat(' cbc:LicensePlateID 02 ', string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID))" />
					<xsl:with-param name="isError" select="false()" />
				</xsl:call-template>
			</xsl:otherwise>

		</xsl:choose>

		<xsl:call-template
			name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate"
				select="'4170'" />
			<xsl:with-param name="node"
				select="cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID" />
			<xsl:with-param name="regexp"
				select="'^(?!\s*$)[^\s].{5,7}$'" />
			<xsl:with-param name="isError" select="false()" />
		</xsl:call-template>

	</xsl:template>

	<!-- =========================================================================================================================================== 
		=========================================== fin Template cac:Delivery/cac:Shipment ===========================================
		=========================================================================================================================================== -->

</xsl:stylesheet>