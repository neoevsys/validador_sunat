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
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
    
	<!--xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" /-->
	<xsl:include href="commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
	


    <!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='Invoice']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <xsl:key name="by-document-additional-reference" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>

    <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>

    <!-- key tributos duplicados por cabecera -->
    <xsl:key name="by-tributos-in-root" match="*[local-name()='Invoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>

    <!-- key AdditionalMonetaryTotal duplicados -->
    <xsl:key name="by-AdditionalMonetaryTotal" match="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal" use="cbc:ID"/>

    <!-- key identificador de prepago duplicados -->
    <xsl:key name="by-idprepaid-in-root" match="*[local-name()='Invoice']/cac:PrepaidPayment" use="cbc:ID"/>

    <xsl:key name="by-document-additional-anticipo" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '02' or text() = '03']]" use="cbc:DocumentStatusCode"/>

    <!-- MIGE-Factoring -->
    <!-- key identificador de forma de pago duplicadas -->
    <xsl:key name="by-cuotas-in-root" match="*[local-name()='Invoice']/cac:PaymentTerms[cbc:ID[text() = 'FormaPago']]" use="cbc:PaymentMeansID"/>

    <xsl:template match="/*">

        <!--
        ===========================================================================================================================================
        Variables
        ===========================================================================================================================================
        -->


		<!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->

        <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>

        <xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>

        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>

        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>

        <!-- MIGE-Factoring Variable para controlar comportamiento ERR/OBS --> 
		<xsl:variable name="datosCpeNodo" select="document('local:///commons/cpe/datos/dat_fechas.xml')/l/d[@id='factoring'][1]" />
		<xsl:variable name="currentdate" select="date:date()" />
        <xsl:variable name="conError">
          <xsl:choose>
            <xsl:when test="number(concat(substring($currentdate,1,4),substring($currentdate,6,2),substring($currentdate,9,2))) &lt; number(string($datosCpeNodo/@valor))">
               <xsl:value-of select="'0'" />
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="'1'" />
            </xsl:otherwise>
          </xsl:choose> 
        </xsl:variable>	

        <!-- Esta validacion se hace de manera general -->
        <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML-->
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

        <!-- Variables 
        <xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>
        <xsl:variable name="cbcCustomizationID" select="cbc:CustomizationID"/>-->

        <xsl:variable name="monedaComprobante" select="cbc:DocumentCurrencyCode/text()"/>

        <xsl:variable name="codigoProducto" select="cac:PaymentTerms/cbc:PaymentMeansID"/>

        <xsl:variable name="tipoOperacion" select="cbc:InvoiceTypeCode/@listID"/>

        <!--
        ===========================================================================================================================================
        Variables
        ===========================================================================================================================================
        -->


        <!--
        ===========================================================================================================================================

        Datos de la Factura Electronica

        ===========================================================================================================================================
        -->
        <!-- cbc:UBLVersionID No existe el Tag UBL ERROR 2075 -->
        <!--  El valor del Tag UBL es diferente de "2.0" ERROR 2074-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.1)$'"/>
        </xsl:call-template>
        

        <!-- cbc:CustomizationID No existe el Tag UBL ERROR 2073 -->
        <!--  Vigente hasta el 01/01/2018   -->
        <!--  El valor del Tag UBL es diferente de "1.0" ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2073'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:CustomizationID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<!-- Pase126 Contingencia js 260718 <xsl:with-param name="regexp" select="'^[F][A-Z0-9]{3}-[0-9]{1,8}?$'"/> -->
			<xsl:with-param name="regexp" select="'^([F][A-Z0-9]{3}|[0-9]{4})-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
		-
        <!-- ================================== Verificar con el flujo o con Java ============================================================= -->
        <!-- cbc:ID El número de serie del Tag UBL es diferente al número de serie del archivo ERROR 1035 -->
        <!--  El número de comprobante del Tag UBL es diferente al número de comprobante del archivo ERROR 1036 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 0 o 1 ERROR 1033 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 2 ERROR 1032 -->

        <!-- cbc:IssueDate La diferencia entre la fecha de recepción del XML y el valor del Tag UBL es mayor al límite del listado ERROR 2108 -->
        <!--  El valor del Tag UBL es mayor a dos días de la fecha de envío del comprobante ERROR 2329 -->

        <!-- cbc:InvoiceTypeCode No existe el Tag UBL ERROR 1004 (Verificar que el error ocurra)-->
        <!--  El valor del Tag UBL es diferente al tipo de documento del archivo ERROR 1003 -->

        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1004'"/>
            <xsl:with-param name="errorCodeValidate" select="'1003'"/>
            <xsl:with-param name="node" select="cbc:InvoiceTypeCode"/>
            <xsl:with-param name="regexp" select="'^01$'"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!-- ================================================================================================================================ -->

        <!-- cbc:DocumentCurrencyCode No existe el Tag UBL ERROR 2070 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode"/>
		</xsl:call-template>


		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cbc:DocumentCurrencyCode"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>

		<!--  La moneda de los totales de línea y totales de comprobantes (excepto para los totales de Percepción (2001) y Detracción (2003)) es diferente al valor del Tag UBL ERROR 2071 -->
		<!-- PAS20191U210000012 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not(ancestor-or-self::cac:PaymentTerms/cbc:Amount) and not(ancestor-or-self::cac:DeliveryTerms/cbc:Amount) and not(ancestor-or-self::cbc:DeclaredForCarriageValueAmount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not (ancestor-or-self::cac:PaymentTerms/cbc:Amount) and not(ancestor-or-self::cac:DeliveryTerms/cbc:Amount) and not(ancestor-or-self::cbc:DeclaredForCarriageValueAmount) and not (ancestor-or-self::cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount)]" />
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 4217 Alpha)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Currency)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!--
        ===========================================================================================================================================

        Fin Datos de la Factura electronica

        ===========================================================================================================================================
        -->


        <!--
        ===========================================================================================================================================

        Datos del Emisor

        ===========================================================================================================================================
        -->


        <xsl:apply-templates select="cac:AccountingSupplierParty">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
          <!--Excel v6 PAS20211U210400011 - Se agrega parametro-->
          <xsl:with-param name="root" select="."/>
	    </xsl:apply-templates>

        <xsl:apply-templates select="cac:Delivery/cac:DeliveryLocation/cac:Address">
	            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>


        <!--
        ===========================================================================================================================================

        Fin Datos del Emisor

        ===========================================================================================================================================
        -->

        <!--
        ===========================================================================================================================================

        Datos del cliente o receptor

        ===========================================================================================================================================
        -->

        <!-- <xsl:apply-templates select="cac:AccountingCustomerParty">
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
        </xsl:apply-templates>-->
        
         <!-- PAS20191U210100194 -->
        <xsl:apply-templates select="cac:AccountingCustomerParty">
          <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
          <xsl:with-param name="root" select="."/>
       </xsl:apply-templates>
        <!-- PAS20191U210100194 -->

        <!--
        ===========================================================================================================================================

        fin Datos del cliente o receptor

        ===========================================================================================================================================
        -->

        <!--
        ===========================================================================================================================================

        Documentos de referencia

        ===========================================================================================================================================
        -->

        <xsl:apply-templates select="cac:DespatchDocumentReference"/>

        <xsl:apply-templates select="cac:AdditionalDocumentReference"/>

        <!--
        ===========================================================================================================================================

        Documentos de referencia

        ===========================================================================================================================================
        -->

        <!--
        ===========================================================================================================================================

        Datos del detalle o Ítem de la Factura

        ===========================================================================================================================================
        -->

        <!--  cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode
        Si "Código de tributo por línea" es 1000 (IGV) y el valor del Tag UBL es "40" (Exportación), no debe haber otro "Afectación a IGV por la línea" diferente a "40"
        ERROR 2655

        <xsl:variable name="afectacionIgvExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() = '40'])"/>
        <xsl:variable name="afectacionIgvNoExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() != '40'])"/>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2655'" />
            <xsl:with-param name="node" select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="($afectacionIgvExportacion > 0) and ($afectacionIgvNoExportacion > 0)" />
        </xsl:call-template>
         -->
		
        <xsl:apply-templates select="cac:InvoiceLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
		
		<!-- Error en validacion de creditos hipotecarios -->
		<xsl:if test="$tipoOperacion = '0112' ">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3181'" />
	            <xsl:with-param name="node" select="cac:InvoiceLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode[text() != '84121901' and text() != '80131501']" />
	            <xsl:with-param name="expresion" select="count(cac:InvoiceLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode[text() = '84121901' or text() = '80131501']) = 0" />
	        </xsl:call-template>
        </xsl:if>

		    <!--Excel v6 PAS20211U210400011-->
        <!-- Error en validacion de empresas financieras -->
		    <xsl:if test="$tipoOperacion = '2100' or $tipoOperacion = '2101' or $tipoOperacion = '2102'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3241'" />
	            <xsl:with-param name="node" select="cac:InvoiceLine/cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '0000']" />
	            <xsl:with-param name="expresion" select="count(cac:InvoiceLine[count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7004' or text() = '7005' or text() = '7012']) = 3]) &lt; 1" />
	            <xsl:with-param name="descripcion" select="concat('cac:AdditionalItemProperty/cbc:NameCode')"/>
	        </xsl:call-template>
        </xsl:if>                                                                 

        <!-- Error en validacion de empresas seguros -->
		    <xsl:if test="$tipoOperacion = '2104'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3242'" />
	            <xsl:with-param name="node" select="cac:InvoiceLine/cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '0000']" />
	            <xsl:with-param name="expresion" select="count(cac:InvoiceLine[count(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7015']) = 1]) &lt; 1" />
	            <xsl:with-param name="descripcion" select="concat('cac:AdditionalItemProperty/cbc:NameCode')"/>
          </xsl:call-template>
        </xsl:if>

        <!--
        ===========================================================================================================================================

        Datos del detalle o Ítem de la Factura

        ===========================================================================================================================================
        -->

        <!--
        ===========================================================================================================================================

        Totales de la Factura

        ===========================================================================================================================================
        -->


        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation El Tag UBL no debe repetirse en el /Invoice
        ERROR 2427
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2427'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation" />
            <xsl:with-param name="expresion" select="count(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation) &gt; 1" />
        </xsl:call-template>
        -->

        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID
        El valor del Tag UBL debe tener por lo menos uno de los siguientes valores en el /Invoice: 1001 (Gravada), 1002 (Inafecta), 1003 (Exonerada), 1004 (Gratuita) o 3001 (FISE)
        ERROR 2047
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2047'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID" />
            <xsl:with-param name="expresion" select="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID[text()='1001' or text()='1002' or text()='1003' or text()='1004' or text()='3001'])" />
        </xsl:call-template>
        -->

        <!-- cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR 2065 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR 2064 -->
        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount
        El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales    ERROR    2064 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <!-- cac:LegalMonetaryTotal/cbc:PayableAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR 2062 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <!-- Excel v6 PAS20211U210400011 -->
        <!-- PAS20211U210700059 - Excel v7 - OBS-4212 pasa a ERR-3288 -->
        <xsl:call-template name="existElementNoVacio">
			      <xsl:with-param name="errorCodeNotExist" select="'3288'"/>
			      <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
			      <!--xsl:with-param name="isError" select ="false()"/-->
		    </xsl:call-template> 

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2031'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3019'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4314 pasa a ERR-3303-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3303'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &gt; 1 or cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &lt; -1" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <!-- Versión 5 excel -->
            <!--xsl:with-param name="errorCodeValidate" select="'4315'" /-->
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID != $monedaComprobante" />
            <!-- Versión 5 excel -->
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        
        <!-- Tributos duplicados por cabecera
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera"/>
        -->
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 2956 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2956'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
        </xsl:call-template>

        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3024 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3024'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
        </xsl:call-template>

        <!-- Tributos de la cabecera-->
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>

        <!-- Cargos y descuentos de la cabecera -->
        <xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
          <xsl:with-param name="conError" select="$conError"/>
        </xsl:apply-templates>

		<!-- PAS20211U210700059 - Excel v7 - Se agrega ERR-3308 y ERR-3309-->
		<!--xsl:if test="$tipoOperacion ='2001'">
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3093'" />
                 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text() = '52' or text() = '53']" />
                 <xsl:with-param name="expresion" select="not(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text()='52' or text()='53'])" />
             </xsl:call-template>
		</xsl:if-->	
		
		
			
			<xsl:choose>
			  <xsl:when test="$tipoOperacion ='2001'">
				  <xsl:if test="cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() = 'Contado']]">	
					 <xsl:call-template name="isTrueExpresion">
						 <xsl:with-param name="errorCodeValidate" select="'3093'" />
						 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text() = '52' or text() = '53']" />
						 <xsl:with-param name="expresion" select="not(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text()='52' or text()='53'])" />
					 </xsl:call-template>

					 <xsl:call-template name="isTrueExpresion">
						 <xsl:with-param name="errorCodeValidate" select="'3309'" />
						 <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID[text() ='Percepcion']" />
						 <xsl:with-param name="expresion" select="not(cac:PaymentTerms/cbc:ID[text() ='Percepcion'])" />
					 </xsl:call-template>
					</xsl:if>
					
					<xsl:if test="cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() != 'Contado']]">	
					 <xsl:call-template name="isTrueExpresion">
						 <xsl:with-param name="errorCodeValidate" select="'3330'" />
						 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text() = '52' or text() = '53']" />
						 <xsl:with-param name="expresion" select="(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text()='52' or text()='53'])" />
					 </xsl:call-template>

					 <xsl:call-template name="isTrueExpresion">
						 <xsl:with-param name="errorCodeValidate" select="'3330'" />
						 <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID[text() ='Percepcion']" />
						 <xsl:with-param name="expresion" select="(cac:PaymentTerms/cbc:ID[text() ='Percepcion'])" />
					 </xsl:call-template>
					</xsl:if>
				 </xsl:when>

			  <xsl:otherwise>
				 <xsl:call-template name="isTrueExpresion">
					 <xsl:with-param name="errorCodeValidate" select="'3308'" />
					 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text() = '52' or text() = '53']" />
					 <xsl:with-param name="expresion" select="(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text()='52' or text()='53'])" />
				 </xsl:call-template>

				 <xsl:call-template name="isTrueExpresion">
					 <xsl:with-param name="errorCodeValidate" select="'3308'" />
					 <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID[text() ='Percepcion']" />
					 <xsl:with-param name="expresion" select="(cac:PaymentTerms/cbc:ID[text() ='Percepcion'])" />
				 </xsl:call-template>
			  </xsl:otherwise>
			</xsl:choose>		
		
		
        <xsl:choose>
          <xsl:when test="$tipoOperacion ='2002'">
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3316'" />
                 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='63']" />
                 <xsl:with-param name="expresion" select="not(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='63'])" />
             </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3317'" />
                 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='63']" />
                 <xsl:with-param name="expresion" select="(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='63'])" />
             </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>       
        <!-- PAS20211U210700059 - Excel v7 - Se agrega las retenciones de segunda categoria (código 63) a los descuentosGlobalesNOAfectaBI -->
		    <xsl:variable name="descuentosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '03' or text() = '63']]/cbc:Amount)"/>
        <xsl:variable name="descuentosxLineaNOAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '01']]/cbc:Amount)"/>
       	<xsl:variable name="totalDescuentos" select="sum(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount)"/>
       	<xsl:variable name="totalDescuentosCalculado" select="$descuentosGlobalesNOAfectaBI + $descuentosxLineaNOAfectaBI"/>
        <xsl:variable name="cargosxLineaNOAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '48']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '45' or text() = '46' or text() = '50']]/cbc:Amount)"/>
       	<xsl:variable name="totalCargos" select="sum(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount)"/>
       	<xsl:variable name="totalCargosCalculado" select="$cargosGlobalesNOAfectaBI + $cargosxLineaNOAfectaBI"/>
        <xsl:variable name="totalPrecioVenta" select="sum(cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount)"/>
        <xsl:variable name="totalAnticipo" select="sum(cac:LegalMonetaryTotal/cbc:PrepaidAmount)"/>
        <xsl:variable name="totalImporte" select="sum(cac:LegalMonetaryTotal/cbc:PayableAmount)"/>
        <xsl:variable name="totalRedondeo" select="sum(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)"/>
        <!-- PAS20211U210700059 - Excel v7 - Se redondea la variable totalImporteCalculado a dos decimales -->
        <!--xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta + $totalCargos - $totalDescuentos - $totalAnticipo + $totalRedondeo"/-->
        <xsl:variable name="totalImporteCalculado" select="round(($totalPrecioVenta + $totalCargos - $totalDescuentos - $totalAnticipo + $totalRedondeo)*100) div 100"/>
        <xsl:variable name="totalValorVenta" select="sum(cac:LegalMonetaryTotal/cbc:LineExtensionAmount)"/>
        <xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaICBPER" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaIVAP" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount)" />
        <xsl:variable name="SumatoriaISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
        <xsl:variable name="MontoBaseIGV" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseICBPER" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount"/>
        <xsl:variable name="MontoBaseIVAP" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoBaseICBPERLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount)"/>
        <xsl:variable name="MontoBaseIVAPLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)"/-->
        <xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>

        <xsl:variable name="DescuentoGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
       	<xsl:variable name="totalValorVentaCalculado" select="$totalValorVentaxLinea - $DescuentoGlobalesAfectaBI + $cargosGlobalesAfectaBI"/>
       	
        <!-- PAS20211U210700059 - Excel v7 - Se agrega variable de anticipos ISC y se considera en el calculo del totalPrecioVentaCalculadoIGV -->
        <xsl:variable name="AnticiposISC" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '20']]/cbc:Amount)"/>
        <xsl:variable name="totalPrecioVentaCalculadoIGV" select="$totalValorVenta + $SumatoriaISC + $SumatoriaICBPER + $SumatoriaOtrosTributos + $AnticiposISC + ($MontoBaseIGVLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.18"/>
       	<xsl:variable name="totalPrecioVentaCalculadoIVAP" select="$totalValorVenta + $SumatoriaICBPER + $SumatoriaOtrosTributos + ($MontoBaseIVAPLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.04"/>

		    <xsl:variable name="totalPrecioVentaCalculadoSinIgvSinIVAP" select="$totalValorVenta + $SumatoriaISC + $SumatoriaICBPER + $SumatoriaOtrosTributos"/>
       	
        <!-- PAS20211U210700059 - Excel v7 - Se resta variable de anticipos ISC solo si la operación es afecta al IGV --> 
        <!--xsl:variable name="SumatoriaIGVCalculado" select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18"/-->
        <xsl:variable name="SumatoriaIGVCalculado">
          <xsl:choose>
            <xsl:when test="$MontoBaseIGVLinea &gt; 0">
               <xsl:value-of select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo - $AnticiposISC + $MontoCargosAfectoBI) * 0.18"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18"/>
            </xsl:otherwise>
          </xsl:choose> 
        </xsl:variable>	       	
         
        <xsl:variable name="SumatoriaIVAPCalculado" select="($MontoBaseIVAPLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.04"/>
		<!-- PAS20191U210000012 -->
		    <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]">
			    <!-- PAS20211U210700059 - Excel v7 - OBS-4321 pasa a ERR-3306 -->
          <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3306'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '7152']]/cbc:TaxAmount" />
	            <!-- PAS20211U210700059 - Excel v7 - Se redondea la variable MontoBaseICBPERLinea para que pueda funcionar la comparacion -->
              <!--xsl:with-param name="expresion" select="$MontoBaseICBPER != $MontoBaseICBPERLinea" /-->
				      <xsl:with-param name="expresion" select="$MontoBaseICBPER != round($MontoBaseICBPERLinea*100) div 100" />
              <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>
		
		
		<!--PAS20221U210600205-->
      	 <!-- PAS20211U210700059 - Excel v7 - OBS-4290 pasa a ERR-3291 -->
			<!--<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			    <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3291'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $SumatoriaIGVCalculado or ($SumatoriaIGV - 1) &gt; $SumatoriaIGVCalculado" />
	        </xsl:call-template>
        </xsl:if>-->

       	<!-- PAS20211U210700059 - Excel v7 - OBS-4302 pasa a ERR-3295 -->
        <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]">
			    <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3295'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($SumatoriaIVAP + 1 ) &lt; $SumatoriaIVAPCalculado or ($SumatoriaIVAP - 1) &gt; $SumatoriaIVAPCalculado" />
	            <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4307 pasa a ERR-3300-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3300'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount" />
            <xsl:with-param name="expresion" select="($totalDescuentos + 1 ) &lt; $totalDescuentosCalculado or ($totalDescuentos - 1) &gt; $totalDescuentosCalculado" />
            <!--xsl:with-param name="isError" select ="false()"/-->
		    </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4308 pasa a ERR-3301 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3301'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount" />
            <xsl:with-param name="expresion" select="($totalCargos + 1 ) &lt; $totalCargosCalculado or ($totalCargos - 1) &gt; $totalCargosCalculado" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
		
        <!-- PAS20211U210700059 - Excel v7 - OBS-4312 pasa a ERR-3280-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3280'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and (($totalImporte + 1 ) &lt; $totalImporteCalculado or ($totalImporte - 1) &gt; $totalImporteCalculado)" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4309 pasa a ERR-3278-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3278'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount" />
            <xsl:with-param name="expresion" select="($totalValorVenta + 1 ) &lt; $totalValorVentaCalculado or ($totalValorVenta - 1) &gt; $totalValorVentaCalculado" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <!-- Detalle de sumatoria -->

        <!-- Versión 5 excel -->
        <!-- PAS20211U210700059 - Excel v7 - OBS-4317 pasa a ERR-3305 -->
        <xsl:call-template name="existElementNoVacio">
			      <xsl:with-param name="errorCodeNotExist" select="'3305'"/>
			      <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"/>
			      <!--xsl:with-param name="isError" select ="false()"/-->
		    </xsl:call-template>

        <!-- Versión 5 excel -->
        <!--xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount &gt; 0">
			     <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalPrecioVenta + 1) * 100) div 100)  &lt; (round($totalPrecioVentaCalculadoIGV * 100) div 100) or (round(($totalPrecioVenta - 1) * 100) div 100) &gt; (round($totalPrecioVentaCalculadoIGV * 100) div 100)" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount &gt; 0">
			    <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalPrecioVenta + 1 ) * 100) div 100) &lt; (round($totalPrecioVentaCalculadoIVAP * 100) div 100) or  (round(($totalPrecioVenta - 1) * 100) div 100) &gt; (round($totalPrecioVentaCalculadoIVAP * 100) div 100)" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
		
		   <xsl:if test="not(cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016' or text() = '1000']]/cbc:TaxAmount &gt; 0)">
			    <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalPrecioVenta + 1 ) * 100) div 100) &lt; (round($totalPrecioVentaCalculadoSinIgvSinIVAP * 100) div 100) or (round(($totalPrecioVenta - 1) * 100) div 100) &gt; (round($totalPrecioVentaCalculadoSinIgvSinIVAP * 100) div 100)" />
	            <xsl:with-param name="isError" select ="false()"/>			
	        </xsl:call-template>
        </xsl:if-->

		
		
		<!--PAS20221U210600205-->
        <!--<xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount">
           <xsl:choose>
              <xsl:when test="$MontoBaseIVAPLinea &gt; 0">
                  <xsl:call-template name="isTrueExpresion">
	                  <xsl:with-param name="errorCodeValidate" select="'3279'" />
	                  <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	                  <xsl:with-param name="expresion" select="($totalPrecioVenta + 1 ) &lt; $totalPrecioVentaCalculadoIVAP or ($totalPrecioVenta - 1) &gt; $totalPrecioVentaCalculadoIVAP" />
	                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
        			    <xsl:call-template name="isTrueExpresion">
	                  <xsl:with-param name="errorCodeValidate" select="'3279'" />
	                  <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	                  <xsl:with-param name="expresion" select="($totalPrecioVenta + 1 ) &lt; $totalPrecioVentaCalculadoIGV or ($totalPrecioVenta - 1) &gt; $totalPrecioVentaCalculadoIGV" />

	                </xsl:call-template>
              </xsl:otherwise>
           </xsl:choose>
        </xsl:if>-->

		
					
		<!--PAS20221U210600205-->
        <xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and $MontoBaseIVAPLinea &gt; 0">
			<xsl:call-template name="isTrueExpresion">
	                  <xsl:with-param name="errorCodeValidate" select="'3279'" />
	                  <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	                  <xsl:with-param name="expresion" select="($totalPrecioVenta + 1 ) &lt; $totalPrecioVentaCalculadoIVAP or ($totalPrecioVenta - 1) &gt; $totalPrecioVentaCalculadoIVAP" />
			</xsl:call-template>
        </xsl:if>		
		
		
		
         

        <!-- cac:TaxTotal/cbc:TaxAmount Si existe una línea con "Código de tributo por línea" igual a "2000" y "Monto ISC por línea" mayor a cero, el valor del Tag UBL es menor igual a 0 (cero)
        OBSERV 4020
        <xsl:variable name="detalleIscGreaterCero" select="cac:InvoiceLine/cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount[text() &gt; 0] "/>
        <xsl:if test="$detalleIscGreaterCero">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4020'" />
                <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']" />
                <xsl:with-param name="expresion" select="not(cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000' and text() &gt; 0])" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        -->

        <!--
        ===========================================================================================================================================

        Fin Totales de la Factura

        ===========================================================================================================================================
        -->

        <!--
        ===========================================================================================================================================

        Información Adicional  - Anticipos

        ===========================================================================================================================================
        -->

        <xsl:apply-templates select="cac:PrepaidPayment" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
        </xsl:apply-templates>

        <!-- PAS20211U210700059 - Excel v7 - Agrega validación ERR-3287 -->
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3287'" />
           <xsl:with-param name="node" select="cac:PrepaidPayment/cbc:PaidAmount" />
           <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0 and count(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04' or text() = '05' or text() = '06'] and cbc:Amount &gt; 0]) &lt; 1" />
        </xsl:call-template>

        <!-- /Invoice/cac:LegalMonetaryTotal/cbc:PrepaidAmount Si existe "Tipo de comprobante que se realizó el anticipo" igual a "02", la suma de "Monto anticipado" es diferente al valor del Tag UBL
        ERROR 2509 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2509'" />
            <xsl:with-param name="node" select="cac:PrepaidPayment/cbc:PaidAmount" />
<!--             <xsl:with-param name="node" select="cac:PrepaidPayment[cbc:ID/@schemeID='02']/cbc:PaidAmount" /> -->
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0 and (round(sum(cac:PrepaidPayment/cbc:PaidAmount)* 100) div 100)  != number(cac:LegalMonetaryTotal/cbc:PrepaidAmount)" />
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - Agrega validación ERR-3287 -->
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3287'" />
           <xsl:with-param name="node" select="cac:PrepaidPayment/cbc:PaidAmount" />
           <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0 and count(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04' or text() = '05' or text() = '06'] and cbc:Amount &gt; 0]) &lt; 1" />
        </xsl:call-template>

        <!--
        ===========================================================================================================================================

        Fin Información Adicional  - Anticipos

        ===========================================================================================================================================
        -->



        <!--
        ===========================================================================================================================================

        Información Adicional

        ===========================================================================================================================================
        -->

        <xsl:apply-templates select="cbc:Note"/>

        <xsl:call-template name="isTrueExpresion">
	        <xsl:with-param name="errorCodeValidate" select="'4264'" />
	        <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2007']" />
	        <xsl:with-param name="expresion" select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode='17']/cbc:TaxableAmount &gt; 0 and not(cbc:Note[@languageLocaleID='2007'])" />
	        <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4266'" />
            <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2005']" />
            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line  and not(cbc:Note[@languageLocaleID='2005'])" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:if test="$tipoOperacion ='1001' or $tipoOperacion ='1002' or $tipoOperacion ='1003' or $tipoOperacion ='1004'">
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4265'" />
                 <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2006']" />
                 <xsl:with-param name="expresion" select="not(cbc:Note[@languageLocaleID='2006'])" />
                 <xsl:with-param name="isError" select ="false()"/>
             </xsl:call-template>
        </xsl:if>

        <!-- /Invoice/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty/cbc:ID El valor del Tag UBL (1000, 1001, 1002, 2000, 2001, 2002, 2003) no debe repetirse en el /Invoice
        ERROR 2407 -->
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
            count(cbc:Note[@languageLocaleID='2009']) &gt; 1 " />
        </xsl:call-template>

        <!-- Cambio el tipo de operacion sea obligatorio y exista en el catalogo -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3205'"/>
			<xsl:with-param name="node" select="$tipoOperacion"/>
		</xsl:call-template>

        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'51'"/>
			<xsl:with-param name="propiedad" select="'factura'"/>
			<xsl:with-param name="idCatalogo" select="$tipoOperacion"/>
			<xsl:with-param name="valorPropiedad" select="'1'"/>
			<xsl:with-param name="errorCodeValidate" select="'3206'"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4260'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@name"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Operacion)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4261'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listSchemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

<!--         <xsl:call-template name="regexpValidateElementIfExist"> -->
<!-- 			<xsl:with-param name="errorCodeValidate" select="'4233'"/> -->
<!-- 			<xsl:with-param name="node" select="cac:OrderReference/cbc:ID"/> -->
<!-- 			<xsl:with-param name="regexp" select="'^[0-9a-zA-Z]{1,20}$'"/> -->
<!-- 			<xsl:with-param name="isError" select ="false()"/> -->
<!-- 		</xsl:call-template> -->
		
		<xsl:choose>
        	<xsl:when test="cac:OrderReference/cbc:ID and (string-length(cac:OrderReference/cbc:ID) &gt; 20)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4233'" />
		            <xsl:with-param name="node" select="cac:OrderReference/cbc:ID" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat(' cbc:Line ', cbc:Line)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4233'"/>
		            <xsl:with-param name="node" select="cac:OrderReference/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

		<!--
		<xsl:if test="$tipoOperacion = '0110' or $tipoOperacion = '0111'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'1076'" />
                 <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cbc:ID" />
                 <xsl:with-param name="expresion" select="not(cac:Delivery/cac:Shipment)" />
             </xsl:call-template>
        </xsl:if>

        <xsl:if test="$tipoOperacion = '0110' or $tipoOperacion = '0111'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'1077'" />
                 <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cbc:ID" />
                 <xsl:with-param name="expresion" select="cac:Delivery/cac:Shipment" />
             </xsl:call-template>
        </xsl:if>
        -->

        <xsl:apply-templates select="cac:Delivery/cac:Shipment">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>

        <xsl:if test="$tipoOperacion = '0303'">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3180'"/>
                <xsl:with-param name="node" select="cbc:DueDate"/>
            </xsl:call-template>
        </xsl:if>

        <!--
        ===========================================================================================================================================

        Fin Información Adicional

        ===========================================================================================================================================
        -->

         <!--
        ===========================================================================================================================================

        Detracciones

        ===========================================================================================================================================
        -->
		
		<!-- MIGE-Factoring -->
		<!-- PAS20211U210700045 - las validaciones se activarán de acuerdo a la fecha del parámetro -->
		<!-- PAS20211U210700120 - será Observación  hasta la fecha (del parametro), luego será error -->
		<!-- <xsl:if test="$conError = '1'"> -->
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3244'" />
				<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:PaymentTerms/cbc:ID[text() = 'FormaPago']) &lt; 1" />
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
			</xsl:call-template>

			<xsl:if test="cac:PaymentTerms/cbc:ID/text() = 'FormaPago'">
				<xsl:call-template name="isTrueExpresion">
				  <xsl:with-param name="errorCodeValidate" select="'3247'" />
				  <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
				  <xsl:with-param name="expresion" select="count(cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() = 'Contado']]) &gt; 0 and 
													 count(cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() = 'Credito']]) &gt; 0" />
				  <xsl:with-param name="isError" select ="boolean(number($conError))"/>
				</xsl:call-template>
			</xsl:if>			
		<!-- </xsl:if> -->
		<!--fin MIGE-->		

        <xsl:if test="$tipoOperacion ='1001' or $tipoOperacion ='1002' or $tipoOperacion ='1003' or $tipoOperacion ='1004'">
        	<!-- Versión 5 excel -->
          <!--xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3127'"/>
                <xsl:with-param name="node" select="cac:PaymentTerms/cbc:PaymentMeansID"/>
          </xsl:call-template-->
          <!-- Versión 5 excel -->
          <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3127'" />
	            <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
	            <xsl:with-param name="expresion" select="count(cac:PaymentTerms/cbc:ID[text() = 'Detraccion']) = 0" />
	        </xsl:call-template>
          <!-- Versión 5 excel -->
          <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3034'" />
	            <xsl:with-param name="node" select="cac:PaymentMeans/cbc:ID" />
	            <xsl:with-param name="expresion" select="count(cac:PaymentMeans/cbc:ID[text() = 'Detraccion']) = 0" />
	        </xsl:call-template>
        </xsl:if>

        <!-- Versión 5 excel -->
        <!--xsl:if test="$tipoOperacion !='1001' and $tipoOperacion !='1002' and $tipoOperacion !='1003' and $tipoOperacion !='1004'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3128'" />
                 <xsl:with-param name="node" select="cac:PaymentTerms/cbc:PaymentMeansID" />
                 <xsl:with-param name="expresion" select="cac:PaymentTerms/cbc:PaymentMeansID" />
             </xsl:call-template>
        </xsl:if-->

        <xsl:apply-templates select="cac:PaymentTerms">
        	<xsl:with-param name="root" select="."/>
          <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
          <xsl:with-param name="conError" select="$conError"/>
        </xsl:apply-templates>
		<!-- PAS20211U210700163 -->
		<xsl:if test="cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
			<!--<xsl:variable name="montoNetoPendientePago" select="sum(cac:PaymentTerms[cbc:PaymentMeansID[text() = 'Credito']]/cbc:Amount)"/>-->
			<!--<xsl:variable name="sumaCuotas" select="sum(cac:PaymentTerms[cbc:PaymentMeansID[substring(text(),1,5) = 'Cuota']]/cbc:Amount)"/>-->
			
			<xsl:variable name="montoNetoPendientePago" select="round(sum(cac:PaymentTerms[cbc:PaymentMeansID[text() = 'Credito']]/cbc:Amount) * 100000 ) div 100000"/>
            <xsl:variable name="sumaCuotas" select="round(sum(cac:PaymentTerms[cbc:PaymentMeansID[substring(text(),1,5) = 'Cuota']]/cbc:Amount) * 100000 ) div 100000"/>
			
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3319'" />
				<xsl:with-param name="node" select="cac:PaymentTerms[cbc:PaymentMeansID[text() = 'Credito']]/cbc:Amount" />
				<xsl:with-param name="expresion" select="$montoNetoPendientePago != $sumaCuotas" />
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
			</xsl:call-template>
		</xsl:if>
		<!-- PAS20211U210700163 Fin-->
        <xsl:if test="$tipoOperacion = '0302'">
	    	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3173'"/>
				<xsl:with-param name="node" select="cac:PaymentMeans/cbc:PaymentMeansCode"/>
			</xsl:call-template>
        </xsl:if>

        <xsl:apply-templates select="cac:PaymentMeans">
        	<xsl:with-param name="tipoOPeracion" select="$tipoOperacion"/>
        	<xsl:with-param name="codigoProducto" select="$codigoProducto"/>
        </xsl:apply-templates>
        <!--
        ===========================================================================================================================================

        Fin Detracciones

        ===========================================================================================================================================
        -->

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

        <!-- PAS20191U210100273 Se separa validacion 3006 para que controle correctamente la longitud del campo -->

        <!--xsl:call-template name="existAndRegexpValidateElement">
        	<xsl:with-param name="errorCodeNotExist" select="'3006'"/>
			    <xsl:with-param name="errorCodeValidate" select="'3006'"/>
			    <xsl:with-param name="node" select="text()"/>
			    <inicio PAS20191U210100194 JOH <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,199}$'"/>>
			    <xsl:with-param name="regexp" select="'^(?!\s*$).{0,199}$'"/>
			    <fin  PAS20191U210100194 JOH> 
			    <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/-->
        
        <!-- <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/>
            <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/> 
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="expresion" select="string-length(text()) &gt; 200 or string-length(text()) &lt; 0 "/>
            <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
        </xsl:call-template>-->
        
        <xsl:choose>        	
       		<xsl:when test="string-length(text()) &gt; 200 or string-length(text()) &lt; 1 " >
	        	<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3006'"/>
					<xsl:with-param name="node" select="text()" />
					<xsl:with-param name="regexp" select="true()" />
				</xsl:call-template>
       		</xsl:when>
       		
       		<xsl:otherwise>					
				<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
		            <xsl:with-param name="node" select="text()"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> 
		        </xsl:call-template>        		
       		</xsl:otherwise>
       	 
        </xsl:choose>
        
	  </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cbc:Note ======================================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    ============================================ Template cac:AccountingSupplierParty =========================================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AccountingSupplierParty">
    	<xsl:param name="tipoOperacion" select = "'-'" />
      <!--Excel v6 PAS20211U210400011 - Se agrega parametro -->
      <xsl:param name="root"/>
      
        <!-- cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID No existe el Tag UBL ERROR 1006 -->
        <!--  El valor del Tag UBL es diferente al RUC del nombre del XML ERROR 1034 -->
        <!--  El valor del Tag UBL no existe en el listado ERROR 2104 -->
        <!--  El valor del Tag UBL tiene un ind_estado diferente "00" en el listado ERROR 2010 -->
        <!--  El valor del Tag UBL tiene un ind_condicion diferente "00" en el listado ERROR 2011 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3089'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        <!-- cac:AccountingSupplierParty/cbc:AdditionalAccountID No existe el Tag UBL ERROR 1008 -->
        <!--  El valor del Tag UBL es diferente a "6" ERROR 1007 -->
        <!--  Existe más de un Tag UBL en el XML ERROR 2362 -->
        <!-- Tipo de documento -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1008'"/>
            <xsl:with-param name="errorCodeValidate" select="'1007'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 4092 -->
        <xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4092'" />
		    <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name" />
		    <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyName/cbc:Name) &gt; 1500" /><!-- de 3 a 1500 caracteres (sin importar que lleve tildes)-->
		    <xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4092'"/>
		    <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
		    <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> <!-- que no inicie por espacio -->
		    <xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        <!-- Apellidos y nombres, denominación o razón social -->
        <!-- cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL ERROR 1037 -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 1038 -->
        <!-- 
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
            <xsl:with-param name="errorCodeValidate" select="'1038'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> 
        </xsl:call-template> -->
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
        	</xsl:otherwise>
        </xsl:choose>
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\n]{0,}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
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

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
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
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4098'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District" />
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District) &gt; 30" />
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat(' cbc:District ', cbc:District)"/>
        </xsl:call-template>

		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4041 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    <!-- Excel v6 PAS20211U210400011 - Se redefine validación de establecimientos anexos-->
    <xsl:choose>
      <xsl:when test="substring($root/cbc:ID, 1, 1) = '0' or substring($root/cbc:ID, 1, 1) = '1' or substring($root/cbc:ID, 1, 1) = '2' or substring($root/cbc:ID, 1, 1) = '3' or substring($root/cbc:ID, 1, 1) = '4' or substring($root/cbc:ID, 1, 1) = '5' or substring($root/cbc:ID, 1, 1) = '6' or substring($root/cbc:ID, 1, 1) = '7' or substring($root/cbc:ID, 1, 1) = '8' or substring($root/cbc:ID, 1, 1) = '9'">
		      <xsl:call-template name="existElement">
			    <xsl:with-param name="errorCodeNotExist" select="'4198'"/>
			    <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
          <xsl:with-param name="isError" select ="false()"/>
		    </xsl:call-template>                               

        <xsl:if test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode != ''">
          <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4199'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{1,}$'"/> <!-- de 4 dígitos -->
            <xsl:with-param name="isError" select ="false()"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="existElement">
			    <xsl:with-param name="errorCodeNotExist" select="'3030'"/>
			    <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
			    <!-- PAS115 Se cambio a observación a solicitud de MICHAEL RUIZ  -->
			    <!-- Pasa a error -->
          <!--xsl:with-param name="isError" select ="false()"/-->
		    </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3239'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{1,}$'"/> <!-- de 4 dígitos -->
        </xsl:call-template>
       
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4242'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}$'"/> <!-- de 4 dígitos -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
    </xsl:if>
    
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

		<xsl:if test="$tipoOperacion = '0302'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3156'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID">
			<xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3157'"/>
	            <xsl:with-param name="errorCodeValidate" select="'3158'"/>
	            <xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(6)$'"/>
	        </xsl:call-template>

	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

		</xsl:if>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:AccountingSupplierParty ======================================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:Delivery/cac:DeliveryLocation/cac:Address ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:DeliveryLocation/cac:Address">
		<xsl:param name="tipoOperacion" select = "'-'" />
    	<!-- tipoOperacion es diferente 0104 Venta interna - Itinerante y existe el tag
        cac:Delivery/cac:DeliveryLocation/cac:Address OBSERVACION 4263
        <xsl:if test="not($tipoOperacion ='0104')">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4263'" />
                <xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
                <xsl:with-param name="expresion" select="cac:AddressLine/cbc:Line" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        -->
        <xsl:choose>
        	<xsl:when test="string-length(cac:AddressLine/cbc:Line) &gt; 200 or string-length(cac:AddressLine/cbc:Line) &lt; 3 ">
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4236'" />
		            <xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
		            <xsl:with-param name="node" select="cac:AddressLine/cbc:Line"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
        	<xsl:when test="string-length(cbc:CitySubdivisionName) &gt; 25 or string-length(cbc:CitySubdivisionName) &lt; 1 ">
		        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4238 -->
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4238'" />
		            <xsl:with-param name="node" select="cbc:CitySubdivisionName" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4238'"/>
		            <xsl:with-param name="node" select="cbc:CitySubdivisionName"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
        	<xsl:when test ="cbc:CityName and (string-length(cbc:CityName) &gt; 30 or string-length(cbc:CityName) &lt; 1 )">
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4239'" />
		            <xsl:with-param name="node" select="cbc:CityName" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>		
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4239'"/>
		            <xsl:with-param name="node" select="cbc:CityName"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

        <xsl:if test="cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4231'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		</xsl:call-template>
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Nodo padre:', cac:Delivery/cac:DeliveryLocation/cac:Address)"/>
		</xsl:call-template>
		<xsl:choose>
			<xsl:when test="string-length(cbc:CountrySubentity) &gt; 30 or string-length(cbc:CountrySubentity) &lt; 1 ">
				<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4240'" />
		            <xsl:with-param name="node" select="cbc:CountrySubentity" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4240'"/>
		            <xsl:with-param name="node" select="cbc:CountrySubentity"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
        
        <!-- 
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4240'"/>
            <xsl:with-param name="node" select="cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        -->
        <xsl:choose>
        	<xsl:when test="string-length(cbc:District) &gt; 30 or string-length(cbc:District) &lt; 1 ">
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4241'" />
		            <xsl:with-param name="node" select="cbc:District" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4241'"/>
		            <xsl:with-param name="node" select="cbc:District"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        <!--
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4241'"/>
            <xsl:with-param name="node" select="cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        -->

		<xsl:choose>
            <xsl:when test="$tipoOperacion ='0201' or $tipoOperacion ='0208'">

				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'3098'"/>
					<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
				</xsl:call-template>

				<xsl:call-template name="findElementInCatalog">
					<xsl:with-param name="errorCodeValidate" select="'3099'"/>
					<xsl:with-param name="idCatalogo" select="cac:Country/cbc:IdentificationCode"/>
					<xsl:with-param name="catalogo" select="'04'"/>
				</xsl:call-template>

				<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3099'" />
	                <xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode" />
	                <xsl:with-param name="expresion" select="cac:Country/cbc:IdentificationCode = 'PE'" />
	            </xsl:call-template>

			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
		            <xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
		            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Delivery/cac:DeliveryLocation/cac:Address ===========================================

    ===========================================================================================================================================
    -->


    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AccountingCustomerParty ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:AccountingCustomerParty">
        <xsl:param name="tipoOperacion" select = "'-'" />
        <xsl:param name="root"/> <!-- PAS20191U210100194 -->

        <!-- numero de documento -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>

        <!-- cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID No existe el Tag UBL
        ERROR 2014 -->
        <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2014'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>

		<xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID != '-'">
	        <xsl:choose>
	            <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
	            	<!--  Si "Tipo de documento de identidad del adquiriente" es 6, el formato del Tag UBL es diferente a numérico de 11 dígitos
	        		ERROR 2017 -->
					<xsl:call-template name="regexpValidateElementIfExist">
			             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
			             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
			             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
			         </xsl:call-template>
				</xsl:when>
				<xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='1'">
					<!--  Si "Tipo de documento de identidad del adquiriente" es "1", el formato del Tag UBL es diferente a numérico de 8 dígitos
	       				OBSERV 4207 -->
					<xsl:call-template name="regexpValidateElementIfExist">
		                <xsl:with-param name="errorCodeValidate" select="'2801'"/>
		                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
		            </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- Si "Tipo de documento de identidad del adquiriente" es diferente de "1" y diferente "6", el formato del Tag UBL es diferente a alfanumérico de hasta 15 caracteres
			        	OBSERV 4208 -->
          <!-- PAS20211U210700059 - Excel v7 - Se corrige la validación ERR-2802 para que determine correctamente la longitud -->
		      <xsl:choose>
			       <xsl:when test="string-length(cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:Party/cac:PartyIdentification/cbc:ID) &lt; 1 ">
 		            <xsl:call-template name="isTrueExpresionIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2802'" />
		               <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
		               <xsl:with-param name="expresion" select="true()" />
		            </xsl:call-template>
			       </xsl:when>
			       <xsl:otherwise>
		            <xsl:call-template name="regexpValidateElementIfExist">
		               <xsl:with-param name="errorCodeValidate" select="'2802'"/>
		               <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		               <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{0,}$'"/> 
		            </xsl:call-template>
			       </xsl:otherwise>
		      </xsl:choose>

					<!--xsl:call-template name="regexpValidateElementIfExist">
		                <xsl:with-param name="errorCodeValidate" select="'2802'"/>
		                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
		            </xsl:call-template-->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
        <!-- No existe el Tag UBL
        ERROR 2015 -->
        <xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2015'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
		
        <!-- El Tag UBL es diferente al listado
        ERROR 2016  TODO agregar la validacion contra el catalogo-->
        <!-- <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
       	<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'2016'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="catalogo" select="'06'"/>
		</xsl:call-template>-->
        <!-- </xsl:if> -->

        
        <!-- PAS20191U210100194 -->
               
        <xsl:if test="count($root/cbc:Note[@languageLocaleID='2008']) = 0">
        <!-- inicio JOSH PAS20191U210100194 -->
        <!-- <xsl:if test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0204' or $tipoOperacion = '0208'">  -->
         <xsl:if test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0204'">
        <!-- FINJOSH PAS20191U210100194 -->      
        <xsl:call-template name="isTrueExpresion">
		    <xsl:with-param name="errorCodeValidate" select="'2800'" />
		    <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		    <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'" />
        </xsl:call-template>
		</xsl:if>
     </xsl:if>  
    <xsl:choose>
      <xsl:when test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0202' or $tipoOperacion = '0203' or $tipoOperacion = '0204' or $tipoOperacion = '0205' or $tipoOperacion = '0206' or $tipoOperacion = '0207' or $tipoOperacion = '0208' or $tipoOperacion = '0401'">
	       <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
              <xsl:call-template name="findElementInCatalog">
			            <xsl:with-param name="errorCodeValidate" select="'2800'"/>
    					    <xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
    					    <xsl:with-param name="catalogo" select="'06'"/>
				      </xsl:call-template>
         </xsl:if>        		
      </xsl:when>
			<xsl:when test="$tipoOperacion = '0112'">
				<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '1' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
        		</xsl:call-template>
			</xsl:when>
      <!-- PAS20211U210700059 - Excel v7 -->
			<xsl:when test="$tipoOperacion = '2106'">
				<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '7' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != 'B' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != 'G'" />
        		</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
        		</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		
		<!-- PAS20191U210100194 -->
		

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!-- No existe el Tag UBL ERROR
        2021 -->
        <!-- El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres
        ERROR 2022  -->
        
        <!-- 
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> PAS20191U210100194 INICIO comentado 
            de tres a 1500 caracteres que no inicie por espacio
             <xsl:with-param name="regexp" select="'^(?!\s*$).{2,1499}$'"/>
            PAS20191U210100194 FIN comentado
        </xsl:call-template> -->
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2021'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		</xsl:call-template>
        
        <xsl:choose>        	
       		<xsl:when test="string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 1500 or string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 3 " >
	        	<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2022'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
					<xsl:with-param name="regexp" select="true()" />
				</xsl:call-template>
       		</xsl:when>
       		
       		<xsl:otherwise>					
				<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
		            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$).{2,}$'"/> 
		        </xsl:call-template>        		
       		</xsl:otherwise>
       	 
       	</xsl:choose>
        
        
    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:AccountingCustomerParty ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:DespatchDocumentReference ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:DespatchDocumentReference">

        <!--  El "Tipo de la guía de remisión relacionada" concatenada con el valor del Tag UBL no debe repetirse en el /Invoice
        ERROR 2364 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2364'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        <!-- cac:DespatchDocumentReference/cbc:ID "Si el Tag UBL existe, el formato del Tag UBL es diferente a:
        (.){1,}-[0-9]{1,}
        [T][A-Z0-9]{3}-[0-9]{1,8}  Ajustado en PAS20221U210700001
        [0-9]{4}-[0-9]{1,8}"
        OBSERV 4006 -->

        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4006'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(([T][A-Z0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0-9]{2}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'"/>
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        <!-- cac:DespatchDocumentReference/cbc:DocumentTypeCode Si existe el "Número de la guía de remisión relacionada", el formato del Tag UBL es diferente de "09" o "31"
        OBSERV 4005 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4005'"/>
            <xsl:with-param name="errorCodeValidate" select="'4005'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(31)|(09)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>


    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:DespatchDocumentReference ===========================================

    ===========================================================================================================================================
    -->


    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AdditionalDocumentReference ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AdditionalDocumentReference">

        <xsl:if test= "cbc:DocumentTypeCode = '02' or cbc:DocumentTypeCode = '03'">

        	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3216'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3214'" />
	            <xsl:with-param name="node" select="cbc:DocumentStatusCode" />
	            <xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:DocumentStatusCode)) &lt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3215'" />
	            <xsl:with-param name="node" select="cbc:DocumentStatusCode" />
	            <xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:DocumentStatusCode)) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>

	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4252'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode/@listName"/>
				<xsl:with-param name="regexp" select="'^(Anticipo)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4251'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode/@listAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:if test= "cbc:DocumentTypeCode = '02'">
	        	<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2521'"/>
		            <xsl:with-param name="node" select="cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^(([F][0-9A-Z]{3}-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([E][0][0][1]-[0-9]{1,8}))$'"/>
		            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		        </xsl:call-template>
        	</xsl:if>

        	<xsl:if test= "cbc:DocumentTypeCode = '03'">
	        	<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2521'"/>
		            <xsl:with-param name="node" select="cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^(([B][0-9A-Z]{3}-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([E][B][0][1]-[0-9]{1,8}))$'"/>
		            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		        </xsl:call-template>
        	</xsl:if>
        </xsl:if>

        <xsl:if test= "cbc:DocumentTypeCode != '02' and cbc:DocumentTypeCode != '03'">
	        <!-- cac:AdditionalDocumentReference/cbc:ID Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres
	        OBSERV 4010 -->
	        <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4010'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4010'"/>
	            <xsl:with-param name="node" select="cbc:ID"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,30}$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>

       		<!-- cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si existe el "Número de otro documento relacionado", el formato del Tag UBL es diferente de "04" o "05" o "99" o "01"
	        OBSERV 4009 -->
	        <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4009'"/>
	            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
	            <!-- Versión 5 excel-->
              <!--xsl:with-param name="regexp" select="'^(0[145]|99)$'"/-->
              <xsl:with-param name="regexp" select="'^(0[23456789]|99)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>
	    </xsl:if>


        <xsl:if test= "cbc:DocumentStatusCode">
    		<!-- cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si existe el "Número de otro documento relacionado", el formato del Tag UBL es diferente de "04" o "05" o "99" o "01"
			OBSERV 2505 -->
			<xsl:call-template name="existAndRegexpValidateElement">
			    <!--<xsl:with-param name="errorCodeNotExist" select="'2505'"/>-->
			    <xsl:with-param name="errorCodeValidate" select="'2505'"/>
			    <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
			    <xsl:with-param name="regexp" select="'^(02|03)$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="existAndRegexpValidateElement">
			    <xsl:with-param name="errorCodeNotExist" select="'3217'"/>
			    <xsl:with-param name="errorCodeValidate" select="'3217'"/>
			    <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID"/>
			    <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
			    <xsl:with-param name="errorCodeValidate" select="'2520'"/>
			    <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
			    <xsl:with-param name="regexp" select="'^(6)$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>

    	</xsl:if>

        <!--  El "Tipo de otro documento relacionado" concatenada con el valor del Tag UBL no debe repetirse en el /Invoice ERROR 2365 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2365'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Documento Relacionado)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:AdditionalDocumentReference ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:InvoiceLine ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:InvoiceLine">

        <xsl:param name="root"/>

        <xsl:variable name="nroLinea" select="cbc:ID"/>

        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoProducto" select="$root/cac:PaymentTerms/cbc:PaymentMeansID/text()"/>
        <xsl:variable name="codigoPrecio" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode"/>

        <!-- cac:InvoiceLine/cbc:ID El formato del Tag UBL es diferente de numérico de 3 dígitos ERROR 2023 -->
        <!-- Numero de item -->
        <!-- Excel v6 PAS20211U210400011 - Se pasa de 5 a 3-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
            <xsl:with-param name="errorCodeValidate" select="'2023'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

        <!--  El valor del Tag UBL no debe repetirse en el /Invoice ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

        <!-- cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode No existe el atributo del Tag UBL ERROR 2883 -->
        <!-- Unidad de medida por item -->
        <xsl:if test="cbc:InvoicedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
                <xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>

        <!--Versión 5 excel -->
        <xsl:if test="cbc:InvoicedQuantity/@unitCode"> 
        		<xsl:call-template name="findElementInCatalog">
			         <xsl:with-param name="errorCodeValidate" select="'2936'" />
			         <xsl:with-param name="idCatalogo" select="cbc:InvoicedQuantity/@unitCode" />
			         <xsl:with-param name="catalogo" select="'03'" />
		        </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4258'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListID"/>
			<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4259'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        <!-- cac:InvoiceLine/cbc:InvoicedQuantity No existe el Tag UBL ERROR 2024 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2025 -->
        <!-- Cantidad de unidades por item -->

        <!--inicio  CAMBIOR DE ORDEN PAS20191U210100194 JOHS -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2024'" />
            <xsl:with-param name="node" select="cbc:InvoicedQuantity" />
            <xsl:with-param name="expresion" select="cbc:InvoicedQuantity = 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2024'"/>
            <xsl:with-param name="errorCodeValidate" select="'2025'"/>
            <xsl:with-param name="node" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

		<!--fin  -->

        <xsl:choose>        	
       		<xsl:when test="string-length(cac:Item/cac:SellersItemIdentification/cbc:ID) &gt; 30 or string-length(cac:Item/cac:SellersItemIdentification/cbc:ID) &lt; 1 " >
	        	<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4269'"/>
					<xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
					<xsl:with-param name="regexp" select="true()" />
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
       		</xsl:when>
       		
       		<xsl:otherwise>					
				<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4269'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> 
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>        		
       		</xsl:otherwise>
       	 
        </xsl:choose>

<!--         <xsl:if test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0202' or $tipoOperacion = '0203' or $tipoOperacion = '0204' or $tipoOperacion = '0205' or $tipoOperacion = '0206' or $tipoOperacion = '0207' or $tipoOperacion = '0208'"> -->
<!--         	<xsl:call-template name="existElement"> -->
<!--                 <xsl:with-param name="errorCodeNotExist" select="'3001'"/> -->
<!--                 <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/> -->
<!--                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--             </xsl:call-template> -->
<!--         </xsl:if> -->

        <!-- PAS20191U210000026 cambio de error 3002 a observación 4332-->
        <xsl:call-template name="findElementInCatalog">
			<!-- <xsl:with-param name="errorCodeValidate" select="'3002'"/> -->
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
		
		<!-- PAS20191U210400136 Flexibilizando 3181 -->
		
		<!--  <xsl:if test="$tipoOperacion = '0112' ">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3181'" />
	            <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
	            <xsl:with-param name="expresion" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != '84121901' and cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != '80131501'" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>
        </xsl:if> -->
        
		<!-- PAS20191U210400136 Flexibilizando 3181 -->
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(UNSPSC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(GS1 US)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Item Classification)$'"/>
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

<!-- cac:InvoiceLine/cac:Item/cbc:Description No existe el Tag UBL ERROR 2026 -->
        <!-- Descripción detallada del servicio prestado, bien vendido o cedido en uso, indicando las características. -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2026'"/>
            <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:choose>
			<xsl:when test="string-length(cac:Item/cbc:Description) &gt; 500">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2027'" />
		            <xsl:with-param name="node" select="cac:Item/cbc:Description" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2027'"/>
		            <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[\S\s].{0,}'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<!--        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2026'"/>
            <xsl:with-param name="errorCodeValidate" select="'2027'"/>
            <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,499}$'"/> 
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        -->

        <!-- cac:InvoiceLine/cac:Price/cbc:PriceAmount No existe el Tag UBL ERROR 2068 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2369 -->
        <!-- Valor unitario por ítem -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2068'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2640'" />
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and cac:Price/cbc:PriceAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
	    </xsl:call-template>

        <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode El valor del Tag UBL es diferente al listado ERROR 2028 -->
        <!-- Código de precio unitario -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">

        	<!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount No existe el Tag UBL o es vacío
	        ERROR 2028 -->
	        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales
	        ERROR 2367 -->
	         
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	            <!--<xsl:with-param name="errorCodeNotExist" select="'2028'"/>-->
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>

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

            <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2409'" />
	            <xsl:with-param name="node" select="cbc:PriceTypeCode" />
	            <!-- PAS20191U210100194 INICIO JOH-->
	            <!-- <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode) &gt; 1" /> -->
	            <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode[text() = '01']) &gt; 1 or count(cbc:PriceTypeCode[text() = '02']) &gt; 1" />
	            <!-- PAS20191U210100194 FIN JOH-->
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>


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

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2409'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode" />
            <!-- PAS20191U210100194 INICIO JOH TEMPORAL II-->
            <!-- <xsl:with-param name="expresion" select="count(cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode) &gt; 1" /> -->
             <xsl:with-param name="expresion" select="count(cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode[text() = '01']) &gt; 1 or count(cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode[text() = '02']) &gt; 1" />
             <!-- PAS20191U210100194 FIN JOH-->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

         <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount Si
     	"Afectación al IGV por línea" es 10 (Gravado), 20 (Exonerado) o 30 (Inafecto) y "cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode" es 02 (Valor referencial en operaciones no onerosa),
     	el Tag UBL es mayor a 0 (cero)
     	ERROR 2425 -->
	    <!-- Valor referencial unitario por ítem en operaciones no onerosas -->
	    <!--
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2425'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="$codigoPrecio='02' and cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount > 0 and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        -->

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3224'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3234'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode != '02']/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode !='02']/cbc:PriceAmount &gt; 0 and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0]" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3195'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3026 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3026'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
			<xsl:with-param name="cntLineaProd" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
        </xsl:apply-templates>
		

        <!-- Valor de venta por línea -->
        <!-- cac:InvoiceLine/cbc:LineExtensionAmount El formato del Tag UBL es diferente de decimal (positivo o negativo) de 12 enteros y hasta 2 decimales ERROR 2370 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- cbc:LineExtensionAmount
            Si "Tipo de operación" es 0102 (Venta interna - Anticipo), el Tag UBL es menor igual a 0 (cero)
            ERROR   2501
        <xsl:if test="$tipoOperacion='0102'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2501'" />
                <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
                <xsl:with-param name="expresion" select="cbc:LineExtensionAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        -->

        <!-- Cargos y tributos por linea de detalle -->
        <xsl:apply-templates select="cac:AllowanceCharge" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
		
        <!-- Validaciones de sumatoria -->
        <xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount"/>
        <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount"/>
        <xsl:variable name="ImpuestosItem" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="DsctosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)"/>
        <xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)"/>
        <xsl:variable name="CargosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)"/>
        <xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)"/>
        <xsl:variable name="CantidadItem" select="cbc:InvoicedQuantity"/>
       	<xsl:variable name="PrecioUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount)"/>
       	<xsl:variable name="PrecioReferencialUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount)"/>

        <!-- PAS20211U210700059 - Excel v7 - Se redondea la variable PrecioUnitarioCalculado a cinco decimales y las variables ValorVentaReferencialxItemCalculado y ValorVentaxItemCalculado a dos decimales -->
        <!--xsl:variable name="PrecioUnitarioCalculado" select="($ValorVentaxItem + $ImpuestosItem - $DsctosNoAfectanBI + $CargosNoAfectanBI) div ( $CantidadItem)"/>
        <xsl:variable name="ValorVentaReferencialxItemCalculado" select="($PrecioReferencialUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/>
        <xsl:variable name="ValorVentaxItemCalculado" select="($ValorVentaUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/-->
        <xsl:variable name="PrecioUnitarioCalculado" select="round(($ValorVentaxItem + $ImpuestosItem - $DsctosNoAfectanBI + $CargosNoAfectanBI) div ( $CantidadItem) * 100000) div 100000"/>
        <xsl:variable name="ValorVentaReferencialxItemCalculado" select="round(($PrecioReferencialUnitarioxItem * $CantidadItem - $DsctosAfectanBI + $CargosAfectanBI)*100) div 100"/>
        <xsl:variable name="ValorVentaxItemCalculado" select="round(($ValorVentaUnitarioxItem * $CantidadItem - $DsctosAfectanBI + $CargosAfectanBI)*100) div 100"/>
        <!-- 4287 - Precio Unitario x Item = Dividir (suma del valor de venta + impuestos x item - descuentos No afectan a BI + Cargos no afectan a BI ) con la cantida  -->
        <!-- PAS20211U210700059 - Excel v7 - OBS-4287 pasa a ERR-3270 -->
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'3270'"/>
             <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount" />
             <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and ($PrecioUnitarioxItem + 1 ) &lt; $PrecioUnitarioCalculado or ($PrecioUnitarioxItem - 1) &gt; $PrecioUnitarioCalculado" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <!-- FIN Validacion 4287 -->

        <!-- 4288 - Valor de Venta x Item = Dividir (suma del valor de venta + impuestos x item - descuentos No afectan a BI + Cargos no afectan a BI ) con la cantida -->
        <!-- PAS20211U210700059 - Excel v7 - OBS-4288 pasa a ERR-3271-->
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'3271'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaReferencialxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaReferencialxItemCalculado)" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4288 pasa a ERR-3271-->
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'3271'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and (($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" />
             <!-- <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0)" />-->
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        
<!--         <xsl:call-template name="isTrueExpresion"> -->
<!--              <xsl:with-param name="errorCodeValidate" select="'4289'"/> -->
<!--              <xsl:with-param name="node" select="cbc:LineExtensionAmount" /> -->
<!--              <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaReferencialxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaReferencialxItemCalculado)" /> -->
<!--              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--              <xsl:with-param name="isError" select ="false()"/> -->
<!--         </xsl:call-template> -->

        <!-- FIN Validacion 4288 -->                     

        <!-- Versión 5 excel-->
        <!--xsl:if test="$codigoProducto = '004'"-->
        <xsl:if test="$tipoOperacion = '1002'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3063'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3001')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3130'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3002'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3002')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3131'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3003'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3003')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3132'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3004')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3134'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3005')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3133'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3006'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3006')"/>
            </xsl:call-template>

        </xsl:if>

        <xsl:if test="$tipoOperacion = '0202'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3136'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4009'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4009')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3137'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4008'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4008')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3138'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4000'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4000')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3139'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4007'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4007')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3140'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4001')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3141'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4002'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4002')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3142'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4003'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4003')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3143'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4004')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3144'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4006'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4006')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3145'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4005')"/>
            </xsl:call-template>

        </xsl:if>

        <xsl:if test="$tipoOperacion = '0205'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3138'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4000'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4000')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3139'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4007'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4007')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3137'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4008'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4008')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3136'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4009'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4009')"/>
            </xsl:call-template>

        </xsl:if>
 
        <xsl:if test="$tipoOperacion = '0301'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3168'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4030']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4030'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4030')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3169'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4031']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4031'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4031')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3170'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4032']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4032'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4032')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3171'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4033']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4033'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4033')"/>
            </xsl:call-template>

        </xsl:if>


        <xsl:if test="$tipoOperacion = '0302'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3159'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4040']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4040'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4040')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3160'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4041']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4041'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4041')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3161'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4042']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4042'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4042')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3162'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4043']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4043'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4043')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3163'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4044']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4044'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4044')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3164'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4045']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4045'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4045')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3165'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4046']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4046'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4046')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3166'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4047']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4047'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4047')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3167'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4048']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4048'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4048')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3204'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4049']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4049'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4049')"/>
            </xsl:call-template>

        </xsl:if>
 
 		<!-- Se quito regalias petrolera 
        <xsl:if test="$tipoOperacion = '0303'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3176'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4060']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4060'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4060')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3177'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4061']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4061'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4061')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3178'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4062']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4062'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4062')"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3179'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4063']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4063'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4063')"/>
            </xsl:call-template>
        </xsl:if>
        -->

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3146'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001' or text() = '5002' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000'])"/>
            <xsl:with-param name="descripcion" select="concat('Error: en la linea: ', $nroLinea, ' Concepto: 5000')"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3147'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5002' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5001')"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3148'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5002']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5001' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5002'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5002')"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3149'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5003']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5001' or text() = '5002'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5003'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5003')"/>
        </xsl:call-template>

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

		    <!--Excel v6 PAS20211U210400011-->
        <!-- Validaciones de empresas de seguros -->
        <xsl:if test="$tipoOperacion = '2104'">
           <xsl:if test="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7015']">
              <xsl:variable name="tipoSeguro" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '7015']]/cbc:Value"/>
              
              <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2898'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7013']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7013']) and ($tipoSeguro = '1' or $tipoSeguro = '2')" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7013')"/>
              </xsl:call-template>              

              <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2898'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7014']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7014']) and ($tipoSeguro = '1' or $tipoSeguro = '2')" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7014')"/>
              </xsl:call-template> 

              <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2898'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7016']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7016']) and ($tipoSeguro = '1' or $tipoSeguro = '2')" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7016')"/>
              </xsl:call-template> 

              <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2899'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7013']) and $tipoSeguro = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7013')"/>
              </xsl:call-template>              
           
           </xsl:if>
        </xsl:if>


        <xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>

        <xsl:variable name="fechaIngreso" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '4003']]/cac:UsabilityPeriod/cbc:StartDate" />
		<xsl:variable name="fechaSalida" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '4004']]/cac:UsabilityPeriod/cbc:StartDate" />
        <xsl:variable name="cacInvoicePeriodcbcStartDate" select="date:seconds($fechaIngreso)" />
		<xsl:variable name="cacInvoicePeriodcbcEndDate" select="date:seconds($fechaSalida)" />

		<!-- La fecha/hora de recepcion del comprobante por ose, no debe de ser mayor a la fecha de recepcion de sunat -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4282'" />
			<xsl:with-param name="node" select="fechaIngreso" />
			<xsl:with-param name="expresion" select="$cacInvoicePeriodcbcStartDate &gt; $cacInvoicePeriodcbcEndDate" />
			<xsl:with-param name="descripcion" select="concat('La fecha de ingreso al establecimiento ', $fechaIngreso,' es mayor a la fecha de salida ', $fechaSalida,'&quot;')"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!-- Detracciones Servicios de transporte de carga -->
        <!-- Versión 5 excel-->
        <xsl:if test="$tipoOperacion = '1004'">
        <!--xsl:if test="$codigoProducto = '027'"-->
        	 
        	<xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3116'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>

	        <xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3117'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>

	       	<xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3118'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>

	        <xsl:call-template name="existElementNoVacio">
	        	<xsl:with-param name="errorCodeNotExist" select="'3119'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>

	        <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3120'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cbc:Instructions"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>

	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3124'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3125'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3126'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3122'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '01']]/cbc:Amount" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '01']]/cbc:Amount)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ValorReferencial: 01')"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3122'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '02']]/cbc:Amount" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '02']]/cbc:Amount)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ValorReferencial: 02')"/>
	        </xsl:call-template>
			
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3122'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '03']]/cbc:Amount" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '03']]/cbc:Amount)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ValorReferencial: 03')"/>
	        </xsl:call-template>
			
			<xsl:call-template name="existAndValidateValueTwoDecimal">
				<xsl:with-param name="errorCodeValidate" select="'3123'"/>
				<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '01' or text() = '02' or text() = '03']]/cbc:Amount" />
				<xsl:with-param name="isGreaterCero" select="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>

	        <xsl:call-template name="findElementInCatalog">
		        <xsl:with-param name="catalogo" select="'13'"/>
		        <xsl:with-param name="idCatalogo" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID"/>
		        <xsl:with-param name="errorCodeValidate" select="'4200'"/>
		        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        <xsl:with-param name="isError" select ="false()"/>
		    </xsl:call-template>
				        
	        
			<xsl:call-template name="findElementInCatalog">
		        <xsl:with-param name="catalogo" select="'13'"/>
		        <xsl:with-param name="idCatalogo" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID"/>
		        <xsl:with-param name="errorCodeValidate" select="'4200'"/>
		        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        <xsl:with-param name="isError" select ="false()"/>
		    </xsl:call-template>

	        
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4271'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cbc:CarrierServiceInstructions"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,99}$'"/> 
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount">
		    	<xsl:call-template name="existAndValidateValueTwoDecimal">
		    		<xsl:with-param name="errorCodeNotExist" select="'4272'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4272'"/>
		            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
			</xsl:if>

	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4273'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,14}$'"/> 
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
			
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4274'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID and cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID[text() != '01' and text() != '02']" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
 
	        <xsl:apply-templates select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension" mode="linea">
	            <xsl:with-param name="nroLinea" select="$nroLinea"/>
	        </xsl:apply-templates>

			<xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount">
				<xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4278'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4278'"/>
		            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:if>
        </xsl:if>
 		
        <xsl:apply-templates select="cac:Delivery" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:InvoiceLine ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:Delivery ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery" mode="linea">
        <xsl:param name="nroLinea"/>
    	<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'13'"/>
            <xsl:with-param name="idCatalogo" select="cac:Despatch/cac:DespatchAddress/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

    <xsl:choose>
			<xsl:when test="string-length(cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &gt; 200 or string-length(cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &lt; 3 ">
				<!-- Verifica el tamaño de la cadena enviada -->
				<xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4236'" />
		            <xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ', Nodo padre: cac:Delivery/cac:Despatch/cac:DespatchAddress')"/>
		        </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
		            <xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>
		            <xsl:with-param name="isError" select ="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ', Nodo padre: cac:Delivery/cac:Despatch/cac:DespatchAddress')"/>
		        </xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
        
		<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'13'"/>
            <xsl:with-param name="idCatalogo" select="cac:DeliveryLocation/cac:Address/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

      <xsl:choose>
  			<xsl:when test="string-length(cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line) &gt; 200 or string-length(cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line) &lt; 3 ">
  				<xsl:call-template name="isTrueExpresionIfExist">
  		            <xsl:with-param name="errorCodeValidate" select="'4236'" />
  		            <xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line" />
  		            <xsl:with-param name="expresion" select="true()" />
  		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ', Nodo padre: cac:Delivery/cac:DeliveryLocation/cac:Address')"/>
  		            <xsl:with-param name="isError" select ="false()"/>
  		        </xsl:call-template>
  			</xsl:when>
  			<xsl:otherwise>
  		        <xsl:call-template name="regexpValidateElementIfExist">
  		            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
  		            <xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/>
  		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>
  		            <xsl:with-param name="isError" select ="false()"/>
  		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ', Nodo padre: cac:Delivery/cac:DeliveryLocation/cac:Address')"/>
  		        </xsl:call-template>
  			</xsl:otherwise>
		</xsl:choose>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4236 -->
<!--         <xsl:call-template name="regexpValidateElementIfExist"> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'4236'"/> -->
<!--             <xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/> -->
<!--             <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> de tres a 1500 caracteres que no inicie por espacio -->
<!--             <xsl:with-param name="isError" select ="false()"/> -->
<!--             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--         </xsl:call-template> -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
<!--         <xsl:call-template name="regexpValidateElementIfExist"> -->
<!--             <xsl:with-param name="errorCodeValidate" select="'4270'"/> -->
<!--             <xsl:with-param name="node" select="cac:Despatch/cbc:Instructions"/> -->
<!--             <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,500}$'"/> de tres a 1500 caracteres que no inicie por espacio -->
<!--             <xsl:with-param name="isError" select ="false()"/> -->
<!--             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> -->
<!--         </xsl:call-template> -->
        <xsl:choose>
        	<xsl:when test="string-length(cac:Despatch/cbc:Instructions) &gt; 500 or string-length(cac:Despatch/cbc:Instructions) &lt; 3 ">
		        <xsl:call-template name="isTrueExpresionIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4270'" />
		            <xsl:with-param name="node" select="cac:Despatch/cbc:Instructions" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4270'"/>
					<xsl:with-param name="node" select="cac:Despatch/cbc:Instructions"/>
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\r\n]+$'"/>
					<xsl:with-param name="isError" select ="false()"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

        <xsl:apply-templates select="cac:DeliveryTerms" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

	    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Configuracion Vehícular)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:MTC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:Delivery/cac:DeliveryTerms/cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== FIN - Template cac:Delivery ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    ================= Template cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension ===================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension" mode="linea">
        <xsl:param name="nroLinea"/>

        <xsl:if test="cbc:AttributeID = '01' or cbc:AttributeID = '02'">

<!-- 	        <xsl:call-template name="isTrueExpresion"> -->
<!-- 	            <xsl:with-param name="errorCodeValidate" select="'4275'"/> -->
<!-- 	            <xsl:with-param name="node" select="cbc:Measure" /> -->
<!-- 	            <xsl:with-param name="expresion" select="not(cbc:Measure)" /> -->
<!-- 	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/> -->
<!-- 	            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 	        </xsl:call-template> -->

	        <!-- <xsl:if test="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:Measure">-->
				<xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4275'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4276'"/>
		            <xsl:with-param name="node" select="cbc:Measure"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/>
	            	<xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    <!-- </xsl:if>-->

		    <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4277'"/>
				<xsl:with-param name="node" select="cbc:Measure/@unitCode"/>
				<xsl:with-param name="regexp" select="'^(TNE)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/>
	            <xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
	    </xsl:if>
    </xsl:template>
    <!--
    ===========================================================================================================================================

    ======== FIN - Template cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension ======================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:DeliveryTerms ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:DeliveryTerms" mode="linea">
        <xsl:param name="nroLinea"/>

        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3122'"/>
            <xsl:with-param name="errorCodeValidate" select="'3123'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== FIN - Template cac:DeliveryTerms ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:TaxSubtotal" mode="linea">
        <xsl:param name="nroLinea"/>
		<xsl:param name="cntLineaProd"/>
        <xsl:param name="root"/>
		
		<xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
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
		
        <xsl:variable name="valorVentaLinea" select="$root/cac:InvoiceLine[cbc:ID[text() = $nroLinea]]/cbc:LineExtensionAmount"/>
			

		
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
		
		<!-- PAS20191U210000012 -->
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
		
		<!-- PAS20191U210000012 -->
		<xsl:if test="$codigoTributo = '7152'">
	    <xsl:call-template name="existElement">
		    <xsl:with-param name="errorCodeNotExist" select="'3237'"/>
		    <xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
		    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		  </xsl:call-template>
		</xsl:if>
		
		<!-- PAS20191U210000012 -->
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
		
		<!-- PAS20191U210000012 -->
		
		<xsl:if test="$codigoTributo = '7152'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4320'"/>
				<xsl:with-param name="node" select="cbc:BaseUnitMeasure"/>
				<xsl:with-param name="expresion" select="cbc:BaseUnitMeasure/@unitCode != 'NIU'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>
		
		<!-- PAS20191U210000012 -->
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
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo,' Tasa::',(round(cac:TaxCategory/cbc:PerUnitAmount * 100) div 100))"/>
				</xsl:call-template>
			</xsl:if>
	    </xsl:if>

		
<!--         <xsl:call-template name="existAndValidateValueTwoDecimal"> -->
		<!-- PAS20191U210000012 -->
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template name="validateValueTwoDecimalIfExist">
				<xsl:with-param name="errorCodeNotExist" select="'3031'"/>
				<xsl:with-param name="errorCodeValidate" select="'3031'"/>
				<xsl:with-param name="node" select="cbc:TaxableAmount"/>
				<xsl:with-param name="isGreaterCero" select="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>	
        
		<!-- PAS20191U210000012 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2036'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
		
		
        <xsl:if test="cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17']">
	    	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3103'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo, ', MontoTributoCalculado: ', $MontoTributoCalculado, ', MontoTributo: ', $MontoTributo, ', BaseImponible: ', $BaseImponible, ', Tasa: ', $Tasa)"/>
<!--                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/> -->
            </xsl:call-template>
	    </xsl:if>
      
      
       <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
		
        <xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3110'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>
	    <xsl:if test="$codigoTributo = '9996'">
	        <xsl:call-template name="isTrueExpresion">
	             <xsl:with-param name="errorCodeValidate" select="'3111'" />
	             <xsl:with-param name="node" select="cbc:TaxAmount" />
	             <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0.06 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17'] and cbc:TaxAmount = 0" /> <!-- PAS20191U210100194  -->
	             <!-- <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17'] and cbc:TaxAmount = 0" /> PAS20191U210100194 -->
	             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
	        <xsl:call-template name="isTrueExpresion">
	             <xsl:with-param name="errorCodeValidate" select="'3110'" />
	             <xsl:with-param name="node" select="cbc:TaxAmount" />
	             <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '37' or text() = '40'] and cbc:TaxAmount != 0" />
	             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:if test="$codigoTributo = '1000' or $codigoTributo = '1016'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3111'" /> 
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <!-- <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cbc:TaxAmount = 0" />  PAS20191U210100194 -->
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0.06 and cbc:TaxAmount = 0" /> <!-- PAS20191U210100194 -->
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>
		

		
	    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3102'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:if test="$codigoTributo = '9996'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2993'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17'] and cac:TaxCategory/cbc:Percent = 0" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:if test="$codigoTributo = '2000'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3104'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:if test="$codigoTributo = '1000' or $codigoTributo = '1016'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2993'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
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

		<xsl:if test="$codigoTributo != '7152'">
		    <!-- PAS20191U210100194 INICIO JOH-->
			<!-- <xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999'"> -->
			<xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999' and cbc:TaxableAmount &gt; 0"> 
			<!-- PAS20191U210100194 FIN JOH-->
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2371'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
				
				<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
				ERROR 2378
				<xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="'1'"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
				-->
			</xsl:if>
		</xsl:if>
	
        <xsl:if test="$codigoTributo = '2000' or $codigoTributo = '9999'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3050'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
	            <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
        </xsl:if>

        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">

            <!-- Si "Código de tributo por línea" es 1000 (IGV) y "Tipo de operación" es 02 (Exportación), el valor del Tag UBL es diferente a 40 (Exportación)
            ERROR 2642 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2642'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode != '40'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>

        </xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<!-- PAS20191U210100194 JOH <xsl:if test="$codigoTributo = '2000'">  -->
		<xsl:if test="$codigoTributo = '2000' and cbc:TaxableAmount &gt; 0 "> 
			<xsl:call-template name="existElement">
               <xsl:with-param name="errorCodeNotExist" select="'2373'"/>
               <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange"/>
               <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
           </xsl:call-template>

          	<xsl:call-template name="findElementInCatalog">
	            <xsl:with-param name="catalogo" select="'08'"/>
	            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TierRange"/>
	            <xsl:with-param name="errorCodeValidate" select="'2041'"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
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
		
	
		<!--PAS20191U210000012- si el codigo es diferente de 7152 y cac:Party/cac:PartyIdentification/cbc:ID No existe el Tag UBL  - ERROR 2992 -->
		<xsl:if test="$codigoTributo != '7152'">
	    <xsl:call-template name="existElement">
		    <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
		    <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
		    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		  </xsl:call-template>
		</xsl:if>

        <!-- cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el cac:InvoiceLine ERROR 2355 -->

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<!-- PAS20191U210000012 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<!-- PAS20191U210000012 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>


		
		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado
        ERROR 2038 y 2996-->
       <!-- <xsl:choose>-->
			<!--
			<xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2038'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:when> -->
			<!--<xsl:otherwise>-->
			
			<!-- PAS20191U210000012 -->
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2996'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			<!--</xsl:otherwise>-->
	<!--	</xsl:choose>-->
        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        
        <!-- PAS20191U210000012 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'3051'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <!-- PAS20191U210000012 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2377'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:if test="$codigoTributo != '7152'">
			<xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999' and cbc:TaxableAmount &gt; 0">
				<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
				ERROR 2378 -->
				<xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="'1'"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if> 

		<!-- 3222 Tag ubl > 0 and no exista un TaxableAmount  del mismo tributo > 0
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3222'" />
            <xsl:with-param name="node" select="cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and not($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = $codigoTributo and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        -->

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
		<xsl:param name="cntLineaProd"/>
        <xsl:param name="root"/>
        <xsl:param name="valorVenta"/>
        <xsl:param name="tipoOperacion"/>

        <!-- <xsl:variable name="tipoOperacion" select="$root/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID"/>-->

        <!-- cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount No existe el Tag UBL o es diferente al Tag anterior
        ERROR 2372
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2372'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number(cac:TaxSubtotal/cbc:TaxAmount) != number(cbc:TaxAmount)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        -->

        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3021 -->
		
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- Tributos duplicados por linea -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
		   <xsl:with-param name="cntLineaProd" select="$cntLineaProd"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
		
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2644'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory[cbc:TaxExemptionReasonCode!='17']/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode='17']/cbc:TaxableAmount &gt; 0 and $root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode!='17']/cbc:TaxableAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- Validaciones exportacion 
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">

            Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación)
            ERROR 3100 
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template> 

        </xsl:if>-->

<!-- 		PAS20191U210000012 add 7152 -->
        <xsl:variable name="totalImpuestosxLinea" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '2000' or text() = '9999']]/cbc:TaxAmount)"/>

		    <!-- PAS20211U210700059 - Excel v7 - OBS-4293 pasa a ERR-3292 -->
        <xsl:if test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '2000' or text() = '9999']">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3292'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalImpuestosxLinea + 1 )*100) div 100) &lt; $SumatoriaImpuestosxLinea or (round(($totalImpuestosxLinea - 1 )*100) div 100) &gt; $SumatoriaImpuestosxLinea" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
	      </xsl:if>
        <xsl:variable name="TributoISCxLinea">
            <xsl:choose>
                <!-- Versión 5 excel-->
                <!--xsl:when test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount"-->
                <xsl:when test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxableAmount &gt; 0">
                    <xsl:value-of select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--Versión 5 excel -->
        <!--xsl:variable name="BaseIGVIVAPxLinea" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="BaseIGVIVAPxLinea" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998'] and cbc:TaxableAmount &gt; 0]/cbc:TaxableAmount"/>
        <xsl:variable name="BaseIGVIVAPxLineaCalculado" select="$valorVenta + $TributoISCxLinea"/>

        <xsl:if test="$BaseIGVIVAPxLinea">                       
	        <!-- PAS20211U210700059 - Excel v7 - OBS-4294 pasa a ERR-3272-->
          <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3272'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998'] and cbc:TaxableAmount &gt; 0]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="$TributoISCxLinea &gt; 0 and (($BaseIGVIVAPxLinea + 1 ) &lt; $BaseIGVIVAPxLineaCalculado or ($BaseIGVIVAPxLinea - 1) &gt; $BaseIGVIVAPxLineaCalculado)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$BaseIGVIVAPxLinea">
          <!-- PAS20211U210700059 - Excel v7 - OBS-4294 pasa a ERR-3272-->
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3272'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998'] and cbc:TaxableAmount &gt; 0]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="$TributoISCxLinea = 0 and $BaseIGVIVAPxLinea != $BaseIGVIVAPxLineaCalculado" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>

        <!-- Se excluye validacion 3105 para los tipos de operacion de bancos PAS20201U210400041 -->
        <!-- PAS20211U210700059 - Excel v7 - Se agrega el tipo de operacion "0112"-->
        <xsl:if test="$tipoOperacion != '2100' and $tipoOperacion != '2101' and $tipoOperacion != '2102' and $tipoOperacion != '2103' and $tipoOperacion != '2104' and $tipoOperacion != '0112'">
           <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3105'" />
               <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
               <!-- Version 5 excel-->
               <!--xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '7152' or text() = '9997' or text() = '9998']) &lt; 1" /-->
               <xsl:with-param name="expresion" select="count(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998'] and cbc:TaxableAmount &gt; 0]) &lt; 1" />
               <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
           </xsl:call-template>
        </xsl:if>
		
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
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->


    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="linea">
        <xsl:param name="nroLinea"/>

        <xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>

        <xsl:choose>

            <!-- <xsl:when test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '47' or $codigoCargoDescuento = '48' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'"> -->
            <xsl:when test="$codigoCargoDescuento = '47' or $codigoCargoDescuento = '48'">

            	<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>

            </xsl:when>

            <!-- <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01' or $codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'">-->
            <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01'">

	            <xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>

            </xsl:when>

        </xsl:choose>

        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado
        ERROR 2036 -->
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3073'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2954'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4268'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="regexp" select="'^(00|01|47|48)$'"/>
			<!-- <xsl:with-param name="regexp" select="'^(00|01|47|48)$'"/>-->
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3052'"/>
			<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2955'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - Se redondea la variable MontoCalculado a dos decimales -->
        <xsl:variable name="MontoCalculado" select="round(number(concat('0',cbc:BaseAmount)) * number(concat('0',cbc:MultiplierFactorNumeric)) * 100) div 100"/>
        <xsl:variable name="Monto" select="cbc:Amount"/>
        <!-- PAS20211U210700059 - Excel v7 - OBS-4289 pasa a ERR-3290 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3290'" />
            <xsl:with-param name="node" select="cbc:Amount" />
            <xsl:with-param name="expresion" select="cbc:MultiplierFactorNumeric &gt; 0 and (($Monto + 1 ) &lt; $MontoCalculado or ($Monto - 1) &gt; $MontoCalculado)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
            <!--xsl:with-param name="isError" select="false()"/-->
        </xsl:call-template>

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3053'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge ===========================================

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
			<!-- INICIO Información Adicional  - Detracciones: Recursos Hidrobiológicos -->
            <xsl:when test="$codigoConcepto = '3001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 15 or string-length(cbc:Value) &lt; 1 ">		        
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            

				<!-- 
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,14}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

			<xsl:when test="$codigoConcepto = '3002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 100 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            
		        <!-- 
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 150 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
            
		        <!--
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,149}$'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template> -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 100 or string-length(cbc:Value) &lt; 1 ">		        
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>

	            <!-- 
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3135'"/>
		            <xsl:with-param name="node" select="cbc:ValueQuantity"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

	            <xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4281'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4281'"/>
		            <xsl:with-param name="node" select="cbc:ValueQuantity"/>
		            <xsl:with-param name="isGreaterCero" select="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>

		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3115'"/>
					<xsl:with-param name="node" select="cbc:ValueQuantity/@unitCode"/>
					<xsl:with-param name="regexp" select="'^(TNE)$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				</xsl:call-template>
            </xsl:when>

			<!-- FIN Información Adicional  - Detracciones: Recursos Hidrobiológicos -->
        	<!-- INICIO Información Adicional  - Transporte terrestre de pasajeros -->
            <xsl:when test="$codigoConcepto = '3050'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        
		        <xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 20 or string-length(cbc:Value) &lt; 1 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3050 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3050 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>

            </xsl:when>

            <xsl:when test="$codigoConcepto = '3051'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 20 or string-length(cbc:Value) &lt; 3 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3051 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3051 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>

            </xsl:when>

            <xsl:when test="$codigoConcepto = '3052'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 15 or string-length(cbc:Value) &lt; 3 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3052 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3052 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>
		        
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3053'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3054'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 200 or string-length(cbc:Value) &lt; 3 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3054 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3054 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>		        
		        
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3055'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
<!--             	<xsl:call-template name="findElementInCatalog"> -->
<!-- 		            <xsl:with-param name="catalogo" select="'13'"/> -->
<!-- 		            <xsl:with-param name="idCatalogo" select="cbc:Value"/> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		        </xsl:call-template> -->

				<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3056'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
<!-- 				<xsl:call-template name="isTrueExpresion"> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'" /> -->
<!-- 		            <xsl:with-param name="node" select="cbc:Value" /> -->
<!-- 		            <xsl:with-param name="expresion" select="string-length(cbc:Value) &gt; 200 and string-length(cbc:Value) &lt; 3 " /> -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		        </xsl:call-template> -->
		
<!-- 		        <xsl:call-template name="regexpValidateElementIfExist"> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'"/> -->
<!-- 		            <xsl:with-param name="node" select="cbc:Value"/> -->
<!-- 		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>  -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		        </xsl:call-template> -->

				<xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 200 or string-length(cbc:Value) &lt; 3 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3056 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3056 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>	

            </xsl:when>

            <xsl:when test="$codigoConcepto = '3057'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

<!--             	<xsl:call-template name="findElementInCatalog"> -->
<!-- 		            <xsl:with-param name="catalogo" select="'13'"/> -->
<!-- 		            <xsl:with-param name="idCatalogo" select="cbc:Value"/> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		        </xsl:call-template> -->

				<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3058'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
<!--             	<xsl:call-template name="isTrueExpresion"> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'" /> -->
<!-- 		            <xsl:with-param name="node" select="cbc:Value" /> -->
<!-- 		            <xsl:with-param name="expresion" select="string-length(cbc:Value) &gt; 200 and string-length(cbc:Value) &lt; 3 " /> -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		        </xsl:call-template> -->
		
<!-- 		        <xsl:call-template name="regexpValidateElementIfExist"> -->
<!-- 		            <xsl:with-param name="errorCodeValidate" select="'4280'"/> -->
<!-- 		            <xsl:with-param name="node" select="cbc:Value"/> -->
<!-- 		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>  -->
<!-- 		            <xsl:with-param name="isError" select ="false()"/> -->
<!-- 		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/> -->
<!-- 		        </xsl:call-template> -->

				<xsl:choose>
	        		<xsl:when test="string-length(cbc:Value) &gt; 200 or string-length(cbc:Value) &lt; 3 " >
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'" />
				            <xsl:with-param name="node" select="cbc:Value" />
				            <xsl:with-param name="regexp" select="true()" />
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3058 ', cbc:Value)"/>
							<xsl:with-param name="isError" select ="false()"/>
					    </xsl:call-template>
	        		
	        		</xsl:when>
	        		
	        		<xsl:otherwise>
	        			<xsl:call-template name="regexpValidateElementIfExist">
				            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
				            <xsl:with-param name="node" select="cbc:Value"/>
				            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/> <!--  select="'^(?!\s*$)[^\s].{1,}$'" --> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto 3058 ', cbc:Value)"/>
				        </xsl:call-template>
	        		
	        		</xsl:otherwise>
	        	 
	        	</xsl:choose>	

            </xsl:when>


            <xsl:when test="$codigoConcepto = '3059'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '3060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN Información Adicional  - Transporte terrestre de pasajeros -->

            <!-- INICIO Información Adicional  - Beneficio de hospedaje -->
            <xsl:when test="$codigoConcepto = '4000'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'04'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4001'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'04'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3135'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

		        <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4281'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure"/>
		            <xsl:with-param name="regexp" select="'^[0-9]{1,4}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>

		        <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4313'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure/@unitCode"/>
		            <xsl:with-param name="regexp" select="'^(DAY)$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>

            </xsl:when>

            <xsl:when test="$codigoConcepto = '4006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4007'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4008'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4009'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 20 or string-length(cbc:Value) &lt; 3 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
		        <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,19}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <!-- FIN Información Adicional  - Beneficio de hospedaje -->

            <!-- INICIO - Migración de documentos autorizados - Carta Porte Aéreo -->
            <xsl:when test="$codigoConcepto = '4030'">
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
             <xsl:when test="$codigoConcepto = '4031'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4032'">
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
                       <xsl:when test="$codigoConcepto = '4033'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
				
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <!-- FIN - Migración de documentos autorizados - Carta Porte Aéreo -->

            <!-- INICIO Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            <xsl:when test="$codigoConcepto = '4040'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4041'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>

            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4042'">
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

            <xsl:when test="$codigoConcepto = '4043'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
				-->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4044'">
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

            <xsl:when test="$codigoConcepto = '4045'">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>

            <xsl:when test="$codigoConcepto = '4046'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 100 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4047'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4048'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4049'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 20 or string-length(cbc:Value) &lt; 1">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,19}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <!-- FIN Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            <!-- INICIO Migración de documentos autorizados - Pago de regalía petrolera -->
            
            <!--  
            <xsl:when test="$codigoConcepto = '4060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 30 or string-length(cbc:Value) &lt; 3 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,29}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>
                        
            <xsl:when test="$codigoConcepto = '4061'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 10 or string-length(cbc:Value) &lt; 3 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\n]{1,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		         
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,9}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4062'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '4063'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:EndDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            </xsl:when>
            -->
            <!-- FIN Migración de documentos autorizados - Pago de regalía petrolera -->
            <!-- INICIO - Ventas Sector Público -->
            <xsl:when test="$codigoConcepto = '5000'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
				<xsl:choose>
					<xsl:when test="string-length(cbc:Value) &gt; 20 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,19}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 10 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,9}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 30 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:choose>
		        	<xsl:when test="string-length(cbc:Value) &gt; 30 or string-length(cbc:Value) &lt; 1 ">
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
				            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/> 
				            <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
            <!-- FIN - Ventas Sector Público -->
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
				            <!--Excel v6 PAS20211U210400011 - Se agrega modifica expresion -->
                    <!--xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/--> 
				            <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
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
				            <!--Excel v6 PAS20211U210400011 - Se agrega modifica expresion -->
                    <!--xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/--> 
				            <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
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
		            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
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
                    <!--xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/--> 
				            <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
				            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				        </xsl:call-template>
		        	</xsl:otherwise>
		        </xsl:choose>
		        <!-- 
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        -->
            </xsl:when>
<!-- 
            <xsl:when test="$codigoConcepto = '7008'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,30})$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '7009'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){2,29})$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '7010'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){2,29})$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
 -->        
            <!-- Excel v6 PAS20211U210400011 -->
 			      <xsl:when test="$codigoConcepto = '7008' or $codigoConcepto = '7009' or $codigoConcepto = '7010' or $codigoConcepto = '7011'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		          </xsl:call-template>
        	  </xsl:when>
            <!-- Excel v6 PAS20211U210400011 - Validaciones empresas de seguros -->

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
		
            <!-- Versión 5 excel -->
            <xsl:when test="$codigoConcepto = '7021'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4202'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{3}-[0-9]{6}$'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
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
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal ===========================================
    ===========================================================================================================================================
    -->

    <xsl:template match="cac:TaxSubtotal" mode="cabecera">

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
				<!--  PAS20191U210000012 -->
				<xsl:when test="$codigoTributo = '7152'">
                    <xsl:value-of select="'oth'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3003 -->
		<!-- PAS20191U210000012-->
		<xsl:if test="$codigoTributo != '7152'">
			<xsl:call-template name="existAndValidateValueTwoDecimal">
				<xsl:with-param name="errorCodeNotExist" select="'3003'"/>
				<xsl:with-param name="errorCodeValidate" select="'2999'"/>
				<xsl:with-param name="node" select="cbc:TaxableAmount"/>
				<xsl:with-param name="isGreaterCero" select="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
			</xsl:call-template>
		</xsl:if>



        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2048 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>

        <xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3000'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'3007'"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>

        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado
        ERROR 2054 -->
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2054'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>

        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2964 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'2964'"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>

		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado
        ERROR 2052 -->
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2052'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>

        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2961 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2961'"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>

        <!-- cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /Invoice
        ERROR 2352 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>


    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->


<!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:TaxTotal" mode="cabecera">

        <xsl:param name="root"/>

                <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <!-- <xsl:variable name="leyenda" select="$root/cbc:Note/@listID"/>-->

        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3020 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3020'"/>
            <xsl:with-param name="errorCodeValidate" select="'3020'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4022 pasa a ERR-3283-->
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2001']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3283'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <!--xsl:with-param name="isError" select ="false()"/-->
            </xsl:call-template>
        </xsl:if>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4023 pasa a ERR-3284-->
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2002']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3284'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <!--xsl:with-param name="isError" select ="false()"/-->
            </xsl:call-template>
        </xsl:if>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4024 pasa a ERR-3285-->
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2003']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3285'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <!--xsl:with-param name="isError" select ="false()"/-->
            </xsl:call-template>
        </xsl:if>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4244 pasa a ERR-3289-->
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2008']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3289'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <!-- PAS20191U210100194 <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />-->
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount &gt; 0  or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount &gt; 0)"/>
                <!--xsl:with-param name="isError" select ="false()"/-->
            </xsl:call-template>
        </xsl:if>
        <!-- Tributos duplicados por cabebcera -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="cabecera"/>

        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación)
            ERROR 3107 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3107'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']]/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
				<xsl:with-param name="descripcion" select="concat('Error tipoOperacion ', $tipoOperacion)"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2650'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount &gt; 0 and $root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '17']]/cbc:TaxableAmount &gt; 0 " />
			<xsl:with-param name="descripcion" select="concat('Error tipoOperacion ', $tipoOperacion)"/>
        </xsl:call-template>

        <xsl:if test="$root/cbc:Note[@languageLocaleID = '1002']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2416'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
                <!-- PAS20191U210100194 INICIO JOH-->
                <!-- <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" /> -->
                <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0"/>
                <!-- PAS20191U210100194 FIN JOH-->
            </xsl:call-template>
        </xsl:if>

        <!-- <xsl:if test="$root/cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode ='02'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2641'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
            </xsl:call-template>
        </xsl:if>-->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2641'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
            <!-- PAS20191U210100194 JOH INICIO -->
            <!-- <xsl:with-param name="expresion" select="$root/cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and (not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0)" /> -->
		    <xsl:with-param name="expresion" select="$root/cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
		    <!-- PAS20191U210100194 JOH FIN -->
		</xsl:call-template>

        <!-- Validacion de sumatorias -->
        <xsl:variable name="totalBaseExportacion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalBaseExportacionxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="totalBaseExportacionxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseExportacionxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount)"/>
        <!-- PAS20211U210700059 - Excel v7 - OBS-4295 pasa a ERR-3273-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3273'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseExportacion + 1 ) &lt; $totalBaseExportacionxLinea or ($totalBaseExportacion - 1) &gt; $totalBaseExportacionxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
		
		<xsl:variable name="totalBaseExoneradas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalBaseExoneradasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="totalBaseExoneradasxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseExoneradasxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)"/>

        <xsl:variable name="totalDescuentosGlobalesExo" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '05']]/cbc:Amount)"/>
        <xsl:variable name="totalBaseExoneradasxLineaCalc" select="$totalBaseExoneradasxLinea - $totalDescuentosGlobalesExo"/>
        
        <!-- PAS20211U210700059 - Excel v7 - OBS-4297 pasa a ERR-3275-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3275'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="(round(($totalBaseExoneradas + 1 ) * 100) div 100)  &lt; $totalBaseExoneradasxLineaCalc or (round(($totalBaseExoneradas - 1) * 100) div 100)  &gt; $totalBaseExoneradasxLineaCalc" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalBaseInafectas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalBaseInafectasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="totalBaseInafectasxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseInafectasxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)"/>

		<xsl:variable name="totalDescuentosGlobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '06']]/cbc:Amount)"/>
		<xsl:variable name="totalCalculado" select="$totalBaseInafectasxLinea - $totalDescuentosGlobales"/>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4296 pasa a ERR-3274-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3274'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseInafectas + 1 ) &lt; $totalCalculado or ($totalBaseInafectas - 1) &gt; $totalCalculado" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalBaseGratuitas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalBaseGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="totalBaseGratuitasxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseGratuitasxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)"/>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4298 pasa a ERR-3276-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3276'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseGratuitas + 1 ) &lt; $totalBaseGratuitasxLinea or ($totalBaseGratuitas - 1) &gt; $totalBaseGratuitasxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalBaseISC" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalBaseISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount)"/-->
        <xsl:variable name="totalBaseISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ] and cbc:TaxableAmount &gt; 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount > 0 ] ) ]/cac:TaxSubtotal [cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ]]/cbc:TaxableAmount )"/>
        
        <!-- PAS20211U210700059 - Excel v7 - OBS-4303 pasa a ERR-3296 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3296'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseISC + 1 ) &lt; $totalBaseISCxLinea or ($totalBaseISC - 1) &gt; $totalBaseISCxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalBaseOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseOtrosxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount)"/>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4304 pasa a ERR-3297 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3297'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseOtros + 1 ) &lt; $totalBaseOtrosxLinea or ($totalBaseOtros - 1) &gt; $totalBaseOtrosxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalBaseIGV" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIVAP" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIGVxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseIVAPxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <!-- Versión 5 excel -->
        <xsl:variable name="totalBaseIGVxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIVAPxLineav1" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        
        <xsl:variable name="totalDescuentosGlobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '02' or text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="totalCargosGobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '49']]/cbc:Amount)"/>
        <!-- PAS20211U210700059 - Excel v7 - Se redondea las variables totalBaseIGVCalculado y totalBaseIVAPxLinea a dos decimales -->
        <!--xsl:variable name="totalBaseIGVCalculado" select="$totalBaseIGVxLinea - $totalDescuentosGlobales + $totalCargosGobales"/-->
        <!--xsl:variable name="totalBaseIVAPCalculado" select="$totalBaseIVAPxLinea - $totalDescuentosGlobales + $totalCargosGobales"/-->
        <xsl:variable name="totalBaseIGVCalculado" select="round(($totalBaseIGVxLinea - $totalDescuentosGlobales + $totalCargosGobales) * 100) div 100"/>
        <xsl:variable name="totalBaseIVAPCalculado" select="round(($totalBaseIVAPxLinea - $totalDescuentosGlobales + $totalCargosGobales) * 100) div 100"/>
        <xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0">
	        <!-- PAS20211U210700059 - Excel v7 - OBS-4299 pasa a ERR-3277-->
          <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3277'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIGV + 1 ) &lt; $totalBaseIGVCalculado or ($totalBaseIGV - 1) &gt; $totalBaseIGVCalculado" />
              <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>
         <xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0">
	         <!-- PAS20211U210700059 - Excel v7 - OBS-4300 pasa a ERR-3293-->
           <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3293'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIVAP + 1 ) &lt; $totalBaseIVAPCalculado or ($totalBaseIVAP - 1) &gt; $totalBaseIVAPCalculado" />
	            <!--xsl:with-param name="isError" select ="false()"/-->
	         </xsl:call-template>
        </xsl:if>

        <xsl:variable name="totalGratuitas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount"/>
        <!--Versión 5 excel -->
        <!--xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount)"/-->
        <xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0]/cbc:TaxAmount)"/>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4311 pasa a ERR-3302 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3302'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
		<!-- PAS20191U210000012 add or text() = '7152'-->
        <xsl:variable name="totalImpuestos" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'or text() = '1016' or text() = '7152' or text() = '9999' or text() = '2000']]/cbc:TaxAmount)"/>
		
        <!-- PAS20211U210700059 - Excel v7 - OBS-4301 pasa a ERR-3294 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3294'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="(round(($totalImpuestos + 1 ) * 100) div 100) &lt; (round($SumatoriaImpuestos * 100) div 100) or (round(($totalImpuestos - 1) * 100) div 100) &gt; (round($SumatoriaImpuestos * 100) div 100)" />
			      <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalISC" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <!-- Versión 5 excel -->
        <!--xsl:variable name="totalISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/-->
        
        <!-- PAS20211U210700059 - Excel v7 - Se define la variable de los anticipos de ISC y se incluye en la fórmula del total de ISC calculado-->
        <xsl:variable name="anticipoISC" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '20']]/cbc:Amount)"/>
        <!--xsl:variable name="totalISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ] and cbc:TaxableAmount > 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount > 0 ] ) ]/cac:TaxSubtotal [cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ]]/cbc:TaxAmount )"/-->
        <xsl:variable name="totalISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal [ cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ] and cbc:TaxableAmount > 0] and not(cac:TaxSubtotal [ cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '9996'] and cbc:TaxableAmount > 0 ] ) ]/cac:TaxSubtotal [cac:TaxCategory/cac:TaxScheme/cbc:ID [ text() = '2000' ]]/cbc:TaxAmount ) - $anticipoISC"/>
        <!-- PAS20211U210700059 - Excel v7 - Se define variable con total ISC redondeado a 2 decimales para la validación ERR-3298-->
        <xsl:variable name="totalISCxLinear" select="round($totalISCxLinea*100) div 100"/>
        
        <!-- PAS20211U210700059 - Excel v7 - OBS-4305 pasa a ERR-3298 y se usa la variable nueva $totalISCxLinear-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3298'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalISCxLinear or ($totalISC - 1) &gt; $totalISCxLinear" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <xsl:variable name="totalOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount"/>
        <xsl:variable name="totalOtrosxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)"/>

        <!-- PAS20211U210700059 - Excel v7 - OBS-4306 pasa a ERR-3299 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3299'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
            <!--xsl:with-param name="isError" select ="false()"/-->
        </xsl:call-template>
        <!--Versión 5 excel -->
        <!--xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4020'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:Taxmount" />
            <xsl:with-param name="expresion" select="$root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount = 0" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template-->

    <!--Versión 5 excel -->
		<xsl:if test="$totalBaseIGVxLineav1 and $totalBaseIGVxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseIGV) or $totalBaseIGV = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>

		<xsl:if test="$totalBaseIVAPxLineav1 and $totalBaseIVAPxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseIVAP) or $totalBaseIVAP = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>
    
		<xsl:if test="$totalBaseInafectasxLineav1 and $totalBaseInafectasxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseInafectas) or $totalBaseInafectas = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>
    
		<xsl:if test="$totalBaseExoneradasxLineav1 and $totalBaseExoneradasxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseExoneradas) or $totalBaseExoneradas = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>

    		<xsl:if test="$totalBaseExportacionxLineav1 and $totalBaseExportacionxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseExportacion) or $totalBaseExportacion = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>

		<xsl:if test="$totalBaseGratuitasxLineav1 and $totalBaseGratuitasxLineav1 &gt;0">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'2638'" />
          <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
          <!--xsl:with-param name="expresion" select="not($totalBaseGratuitas) or $totalBaseGratuitas = 0" /-->
          <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)" />
       </xsl:call-template>
    </xsl:if>
        <!-- Fin Validacion de sumatorias -->
        
        
        
        
    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->

	<!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="cabecera">
    	<xsl:param name="root"/>
      <xsl:param name="conError" select = "false()" />   

		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
        <xsl:variable name="monedaComprobante" select="$root/cbc:DocumentCurrencyCode"/>
        <xsl:variable name="importeComprobante" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount"/>

        <!-- PAS20211U210700059 - Excel v7 - Se agrega el código "63"-->
        <xsl:if test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3114'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>

        <!-- PAS20211U210700059 - Excel v7 - Se agrega el código "20" y "63"-->
        <xsl:if test="$codigoCargoDescuento = '02' or $codigoCargoDescuento = '03' or $codigoCargoDescuento = '04' or $codigoCargoDescuento = '05' or $codigoCargoDescuento = '06' or $codigoCargoDescuento = '20' or $codigoCargoDescuento = '63'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3114'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>
		
		  <!-- MIGE-Factoring -->
		  <!-- PAS20211U210700120 - será Observación  hasta la fecha (del parametro), luego será error -->
		  <xsl:if test="$codigoCargoDescuento = '62'">
			  <xsl:call-template name="isTrueExpresion">
				  <xsl:with-param name="errorCodeValidate" select="'3114'" />
				  <xsl:with-param name="node" select="cbc:ChargeIndicator" />
				  <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
				  <xsl:with-param name="isError" select ="boolean(number($conError))"/>
				  <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			  </xsl:call-template>

		    <xsl:call-template name="isTrueExpresion">
				  <xsl:with-param name="errorCodeValidate" select="'3262'" />
				  <xsl:with-param name="node" select="cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
				  <xsl:with-param name="expresion" select="$root/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
				  <xsl:with-param name="isError" select ="boolean(number($conError))"/>
			  </xsl:call-template>
      </xsl:if>
		<!-- FIN MIGE-->		
		
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3072'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4291'" />
           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
           <xsl:with-param name="expresion" select="cbc:AllowanceChargeReasonCode[text() = '00' or text() = '01' or text() = '47' or text() = '48']" />
           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'3071'"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>

    <!--Excel v6 PAS20211U210400011 - Se adiciona Percepciones para que valide sin permitir ceros -->
    <xsl:choose>
       <xsl:when test="$codigoCargoDescuento = '62' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
          <xsl:call-template name="regexpValidateElementIfExist">
			      <xsl:with-param name="errorCodeValidate" select="'3025'"/>
			      <xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			      <xsl:with-param name="regexp" select="'^(?=.*[1-9])[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			      <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		      </xsl:call-template>

          <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2968'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>
       </xsl:when>

       <!-- PAS20211U210700059 - Excel v7 - Agrega validación ERR-2968 para el tipo 63 -->       
       <xsl:when test="$codigoCargoDescuento = '63'">
            <xsl:call-template name="validateValueTwoDecimalIfExist">
              <xsl:with-param name="errorCodeValidate" select="'2968'"/>
              <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>
       </xsl:when>       

       <xsl:otherwise>
          <xsl:call-template name="regexpValidateElementIfExist">
			      <xsl:with-param name="errorCodeValidate" select="'3025'"/>
			      <xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			      <xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			      <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		      </xsl:call-template>

          <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2968'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>
       </xsl:otherwise>
    </xsl:choose>
		<xsl:variable name="MontoCalculadoPercepcion" select="cbc:BaseAmount * cbc:MultiplierFactorNumeric"/>
        <xsl:variable name="MontoPercepcion" select="cbc:Amount"/>
			
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
                <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2792'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>

        <!-- MIGE-Factoring - Se agrega al if el codigo 62 -->
        <xsl:if test="$codigoCargoDescuento != '45' and $codigoCargoDescuento != '51' and $codigoCargoDescuento != '52' and $codigoCargoDescuento != '53' and $codigoCargoDescuento != '62'">
	        <xsl:variable name="MontoCalculado" select="number(concat('0',cbc:BaseAmount)) * number(concat('0',cbc:MultiplierFactorNumeric))"/>
	       	<xsl:variable name="Monto" select="cbc:Amount"/>

	        <!-- PAS20211U210700059 - Excel v7 - OBS-4322 pasa a ERR-3307 -->
          <xsl:call-template name="isTrueExpresion">
	            <!-- xsl:with-param name="errorCodeValidate" select="'3226'" /-->
	            <xsl:with-param name="errorCodeValidate" select="'3307'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="cbc:MultiplierFactorNumeric &gt; 0 and (($MontoCalculado + 1 ) &lt; $Monto or ($MontoCalculado - 1) &gt; $Monto)" />
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	            <!--xsl:with-param name="isError" select ="false()"/-->
	        </xsl:call-template>
        </xsl:if>
		
		<!-- MIGE-Factoring -->
		<!-- PAS20211U210700120 - será Observación  hasta la fecha (del parametro), luego será error -->
		<xsl:if test="$codigoCargoDescuento = '62'">


	        <xsl:variable name="MontoCalculado" select="number(concat('0',cbc:BaseAmount)) * number(concat('0',cbc:MultiplierFactorNumeric))"/>
	       	<xsl:variable name="Monto" select="cbc:Amount"/>
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3263'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="cbc:MultiplierFactorNumeric &gt; 0 and (($MontoCalculado + 1 ) &lt; $Monto or ($MontoCalculado - 1) &gt; $Monto)" />
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	            <xsl:with-param name="isError" select ="boolean(number($conError))"/>
	        </xsl:call-template>
        </xsl:if>
		<!-- FIN MIGE-->
		
        <xsl:if test="$codigoCargoDescuento = '45'">
			<xsl:call-template name="isTrueExpresion">
	           <xsl:with-param name="errorCodeValidate" select="'3074'" />
	           <xsl:with-param name="node" select="cbc:Amount" />
	           <xsl:with-param name="expresion" select="cbc:Amount = 0" />
	           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>

			<xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3092'"/>
	            <xsl:with-param name="node" select="cbc:BaseAmount"/>
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>

			<xsl:call-template name="isTrueExpresion">
	           <xsl:with-param name="errorCodeValidate" select="'3092'" />
	           <xsl:with-param name="node" select="cbc:BaseAmount" />
	           <xsl:with-param name="expresion" select="cbc:BaseAmount = 0" />
	           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>
		</xsl:if>

		
		<!-- MIGE-Factoring -->
    <xsl:choose>
	     <xsl:when test="$codigoCargoDescuento = '62'">
          <xsl:call-template name="validateValueTwoDecimalIfExist">
             <xsl:with-param name="errorCodeValidate" select="'3016'"/>
             <xsl:with-param name="node" select="cbc:BaseAmount"/>
             <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>

		      <!-- PAS20211U210700120 - será Observación  hasta la fecha (del parametro), luego será error -->
		      <!-- <xsl:if test="$conError = '1'"> -->
		         <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3264'" />
		            <xsl:with-param name="node" select="cbc:BaseAmount" />
		            <xsl:with-param name="expresion" select="cbc:BaseAmount &gt; $importeComprobante" />
		            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		            <xsl:with-param name="isError" select ="boolean(number($conError))"/>
			     </xsl:call-template>
		      <!-- </xsl:if> -->
		   </xsl:when>

       <!-- PAS20211U210700059 - Excel v7 - Agrega validación ERR-3318 para el tipo 63 -->
       <xsl:when test="$codigoCargoDescuento = '63'">
          <xsl:call-template name="existAndValidateValueTwoDecimal">
             <xsl:with-param name="errorCodeNotExist" select="'3318'"/>
             <xsl:with-param name="errorCodeValidate" select="'3016'"/>
             <xsl:with-param name="node" select="cbc:BaseAmount"/>
             <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>
       </xsl:when> 
      <xsl:otherwise>
          <xsl:call-template name="validateValueTwoDecimalIfExist">
             <xsl:with-param name="errorCodeValidate" select="'3016'"/>
             <xsl:with-param name="node" select="cbc:BaseAmount"/>
             <xsl:with-param name="isGreaterCero" select="false()"/>
             <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
          </xsl:call-template>
       </xsl:otherwise>
    </xsl:choose>		
		<!-- FIN MIGE-->		
		
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">

            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3233'"/>
                <xsl:with-param name="node" select="cbc:BaseAmount"/>
                <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
            </xsl:call-template>

            <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3233'" />
               <xsl:with-param name="node" select="cbc:BaseAmount" />
               <xsl:with-param name="expresion" select="cbc:BaseAmount = 0" />
               <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
            </xsl:call-template>

	        <xsl:if test="$monedaComprobante = 'PEN'">
				<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'2797'" />
		           <xsl:with-param name="node" select="cbc:BaseAmount" />
		           <xsl:with-param name="expresion" select="cbc:BaseAmount &gt; $importeComprobante" />
		           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
			</xsl:if>

			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2798'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="($MontoCalculadoPercepcion + 1 ) &lt; $MontoPercepcion or ($MontoCalculadoPercepcion - 1) &gt; $MontoPercepcion" />
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>

	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2788'"/>
				<xsl:with-param name="node" select="cbc:BaseAmount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>

    <!-- PAS20211U210700059 - Excel v7 - Se agrega validación ERR-3282-->
    <xsl:if test="$codigoCargoDescuento = '04' or $codigoCargoDescuento = '05' or $codigoCargoDescuento = '06' or $codigoCargoDescuento = '20'">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'3282'" />
          <xsl:with-param name="node" select="cbc:Amount" />
          <xsl:with-param name="expresion" select="cbc:Amount &gt; 0 and (not($root/cac:LegalMonetaryTotal/cbc:PrepaidAmount) or $root/cac:LegalMonetaryTotal/cbc:PrepaidAmount &lt;= 0)" />
          <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
       </xsl:call-template>
    </xsl:if>
 
    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:Delivery/cac:Shipment ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:Shipment">
    	<xsl:param name="tipoOperacion" select = "'-'" />

		<xsl:if test="cbc:ID">
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4249'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'20'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Motivo de Traslado)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4155'"/>
            <xsl:with-param name="node" select="cbc:GrossWeightMeasure"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4154'"/>
			<xsl:with-param name="node" select="cbc:GrossWeightMeasure/@unitCode"/>
			<xsl:with-param name="regexp" select="'^(KGM)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<!--
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4125'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		-->

		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4043'"/>
			<xsl:with-param name="idCatalogo" select="cac:ShipmentStage/cbc:TransportModeCode"/>
			<xsl:with-param name="catalogo" select="'18'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<!--
		<xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4134'" />
	            <xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode" />
	            <xsl:with-param name="expresion" select="cac:ShipmentStage/cbc:TransportModeCode" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>
		-->

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Modalidad de Transporte)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo18)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:if test="cbc:ID and cac:ShipmentStage/cbc:TransportModeCode">
		
			<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'4126'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cbc:ID and not(cac:ShipmentStage/cbc:TransportModeCode)">
			<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'4126'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:ID and cac:ShipmentStage/cbc:TransportModeCode = '01'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4286'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:ID and cac:ShipmentStage/cbc:TransportModeCode = '02'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4159'" />
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>

		<xsl:if test="cbc:ID and not(cac:ShipmentStage/cbc:TransportModeCode)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4160'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID">
			<!-- <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4161'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4162'"/>
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(6)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        -->
	        <xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'4161'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4162'"/>
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(6)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	    </xsl:if>
		<!--
	    <xsl:call-template name="existAndRegexpValidateElement">
	        <xsl:with-param name="errorCodeNotExist" select="'4164'"/>
	        <xsl:with-param name="errorCodeValidate" select="'4165'"/>
	        <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
	        <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/>
	        <xsl:with-param name="isError" select ="false()"/>
	    </xsl:call-template>-->

		<xsl:if test="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID and not(cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4164'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName">
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4165'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,99}$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>


		<xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4163'"/>
            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
            <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:if test="$tipoOperacion = '0110' and cac:ShipmentStage/cbc:TransportModeCode = '01' and cac:ShipmentStage/cac:DriverPerson/cbc:ID">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4156'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:variable name="motivoTraslado" select="cbc:ID"/>
        <xsl:variable name="modalidadTransporte" select="cac:ShipmentStage/cbc:TransportModeCode"/>
        <xsl:variable name="numeroPlaca" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>

		<xsl:if test="$modalidadTransporte = '01' and $numeroPlaca">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4157'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<!-- Versión 5 excel -->
		<!--xsl:if test="$modalidadTransporte = '02' and not(cac:ShipmentStage/cac:DriverPerson/cbc:ID)"-->
		<xsl:if test="$modalidadTransporte = '02'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4157'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

    <!--xsl:if test="$motivoTraslado and not($modalidadTransporte) and not(cac:ShipmentStage/cac:DriverPerson/cbc:ID)"-->
    <xsl:if test="$motivoTraslado and not($modalidadTransporte)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4157'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:choose>
			<xsl:when test="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID and (string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID) &gt; 8 or string-length(cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID) &lt; 6 )">
				
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'4167'" />
				    <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name" />
				    <xsl:with-param name="expresion" select="true()" />
				    <xsl:with-param name="isError" select ="false()"/>
				    <xsl:with-param name="descripcion" select="concat(' cbc:LicensePlateID ', cbc:LicensePlateID)"/>
				</xsl:call-template>
			
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4167'"/>
					<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
<!-- 					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{5,}$'"/> -->
					<xsl:with-param name="regexp" select="'^[A-Z0-9\-]{5,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
			</xsl:otherwise>
		
		</xsl:choose>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4170'"/>
			<xsl:with-param name="node" select="cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{5,7}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:if test="$tipoOperacion = '0110' and cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4156'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:variable name="numeroDocumentoId" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>

		<xsl:if test="$motivoTraslado and $modalidadTransporte = '01' and $numeroDocumentoId and not($numeroPlaca)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4158'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$motivoTraslado and $modalidadTransporte = '02' and not($numeroPlaca)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4158'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$motivoTraslado and not($modalidadTransporte) and not($numeroPlaca)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4158'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:variable name="tipoDocumentoConductores" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeID"/>

		<xsl:choose>
       <!--xsl:when test="$tipoDocumentoConductores ='0' or $tipoDocumentoConductores ='A'"-->
       <xsl:when test="$tipoDocumentoConductores ='A'">
			    	<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4174'"/>
	                <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	          </xsl:call-template>
			 </xsl:when>
       <xsl:when test="$tipoDocumentoConductores ='1'">
			 <!--  Si "Tipo de documento de identidad del adquiriente" es "1", el formato del Tag UBL es diferente a numérico de 8 dígitos
       				OBSERV 4207 -->
				    <xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4174'"/>
	                <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	          </xsl:call-template>
			 </xsl:when>
			 <xsl:when test="$tipoDocumentoConductores ='4' or $tipoDocumentoConductores ='7'">
			 <!-- Si "Tipo de documento de identidad del adquiriente" es diferente de "4" y diferente "7", el formato del Tag UBL es diferente a alfanumérico de hasta 15 caracteres
		        	OBSERV 4208 -->
			      <xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4174'"/>
	                <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
	                <!-- <xsl:with-param name="regexp" select="'^.{15}$'"/> -->
					        <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,12}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	          </xsl:call-template>
			 </xsl:when>
		</xsl:choose>
		
		<xsl:if test="cac:ShipmentStage/cac:DriverPerson/cbc:ID">
			<xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4172'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4173'"/>
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(1|4|7|A)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	    </xsl:if>

		<!--
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4161'"/>
            <xsl:with-param name="errorCodeValidate" select="'4162'"/>
            <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(1|4|7|A)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		-->

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		
		<xsl:if test="$motivoTraslado and $modalidadTransporte and not(cac:Delivery/cac:DeliveryAddress/cbc:ID)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4127'"/>
				<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$motivoTraslado and $modalidadTransporte and not(cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4127'"/>
				<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$motivoTraslado and not($modalidadTransporte)">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4135'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryAddress/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4135'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>

		<xsl:if test="cac:Delivery/cac:DeliveryAddress/cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4176'"/>
				<xsl:with-param name="idCatalogo" select="cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4179'"/>
            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,99}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:if test="$motivoTraslado and $modalidadTransporte and not(cac:OriginAddress/cbc:ID)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4128'"/>
				<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

		<xsl:if test="$motivoTraslado and $modalidadTransporte and not(cac:OriginAddress/cac:AddressLine/cbc:Line)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4128'"/>
				<xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

		</xsl:if>

		<xsl:if test="$motivoTraslado and not($modalidadTransporte)">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4136'" />
	            <xsl:with-param name="node" select="cac:OriginAddress/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:OriginAddress/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>

	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4136'" />
	            <xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="expresion" select="cac:OriginAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>

		<xsl:if test="cac:OriginAddress/cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4181'"/>
				<xsl:with-param name="idCatalogo" select="cac:OriginAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>


        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4184'"/>
            <xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,99}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>


        <xsl:if test="$motivoTraslado and $modalidadTransporte">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4129'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryParty/cbc:MarkAttentionIndicator" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryParty/cbc:MarkAttentionIndicator" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Delivery/cac:Shipment ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== cac:PrepaidPayment ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:PrepaidPayment" mode="cabecera">
    	<xsl:param name="root"/>

        <!-- /Invoice/cac:PrepaidPayment/cbc:ID Si "Monto anticipado" existe y no existe el Tag UBL
        OBSERV 3211 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3211'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and not(string(cbc:ID))" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>

        <!-- cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /Invoice
        ERROR 2352 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3212'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:ID)) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3213'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:ID)) = 0" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Anticipo)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
		</xsl:call-template>

		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2503'" />
            <xsl:with-param name="node" select="cbc:PaidAmount" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and cbc:PaidAmount &lt;= 0" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>

        <xsl:if test="cbc:PaidAmount and cbc:PaidAmount &gt; 0">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3220'" />
	            <xsl:with-param name="node" select="$root/cac:LegalMonetaryTotal/cbc:PrepaidAmount" />
	            <xsl:with-param name="expresion" select="not($root/cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0)" />
	        </xsl:call-template>
        </xsl:if>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin cac:PrepaidPayment ===========================================

    ===========================================================================================================================================
    -->
	
	
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:PaymentTerms ===========================================

    ===========================================================================================================================================
    -->	
	
	
    <xsl:template match="cac:PaymentTerms">
		<xsl:param name="root"/>
    <xsl:param name="tipoOperacion" select = "'-'" />
    <xsl:param name="conError" select = "false()" />

		<!-- Versión 5 excel -->
		<xsl:if test="$tipoOperacion !='1001' and $tipoOperacion !='1002' and $tipoOperacion !='1003' and $tipoOperacion !='1004'">
		   <xsl:call-template name="isTrueExpresion">
			   <xsl:with-param name="errorCodeValidate" select="'3128'" />
			   <xsl:with-param name="node" select="cbc:ID" />
			   <xsl:with-param name="expresion" select="cbc:ID/text() = 'Detraccion'" />
		   </xsl:call-template>
		</xsl:if>
    
    <!--xsl:if test="cbc:PaymentMeansID">

			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3033'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="catalogo" select="'54'"/>
			</xsl:call-template>

			<xsl:call-template name="existAndValidateValueTwoDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'3035'"/>
	            <xsl:with-param name="errorCodeValidate" select="'3037'"/>
	            <xsl:with-param name="node" select="cbc:Amount"/>
	        </xsl:call-template>

	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3208'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			</xsl:call-template-->

			<!--
	        <xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'54'"/>
				<xsl:with-param name="propiedad" select="tasa"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="valorPropiedad" select="cbc:PaymentPercent"/>
				<xsl:with-param name="errorCodeValidate" select="'3062'"/>
			</xsl:call-template>
			-->
		<!--/xsl:if-->

		
		<!-- MIGE-Factoring -->
    <!-- PAS20211U210700045 - las validaciones se activarán de acuerdo a la fecha del parámetro -->
    <!-- PAS20211U210700120 - será Observación  hasta la fecha (del parametro), luego será error -->
    <!-- <xsl:if test="$conError = '1'"> -->
    <xsl:call-template name="isTrueExpresion">
	     <xsl:with-param name="errorCodeValidate" select="'3248'" />
	     <xsl:with-param name="node" select="cbc:PaymentMeansID" />
	     <xsl:with-param name="expresion" select="count(key('by-cuotas-in-root', cbc:PaymentMeansID)) &gt; 1" />
       <xsl:with-param name="isError" select ="boolean(number($conError))"/>
	     <xsl:with-param name="descripcion" select="concat('Forma Pago : ', cac:PaymentTerms/cbc:PaymentMeansID)"/>
	  </xsl:call-template>
	  
    <xsl:if test="cbc:ID and cbc:ID='FormaPago'">
    
    	<!-- PASE-8101 PAS20221U210600155 - Valida que dentro de un PaymentTerms que tenga como ID 'FormaPago' no haya mas de un PaymentMeansID -->
      
    	<xsl:call-template name="isTrueExpresion">
        	<xsl:with-param name="errorCodeValidate" select="'3461'" />
	    	<xsl:with-param name="node" select="cbc:PaymentMeansID" />
	    	<xsl:with-param name="expresion" select="count(cbc:PaymentMeansID) &gt; 1" />
        	<xsl:with-param name="isError" select ="boolean(number($conError))"/>       	
		</xsl:call-template>
    
        <xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'3245'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID"/>
			<xsl:with-param name="isError" select ="boolean(number($conError))"/>
		</xsl:call-template>
		
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3246'"/>
            <xsl:with-param name="node" select="cbc:PaymentMeansID"/>
            <xsl:with-param name="regexp" select="'^((Contado)|(Credito)|(Cuota[0-9]{3}))$'"/>
            <xsl:with-param name="isError" select ="boolean(number($conError))"/>
        </xsl:call-template>
		<!-- PAS20211U210700163 -->			
		<xsl:if test="$root/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">		
		<xsl:if test="cbc:PaymentMeansID = 'Credito'">			
       		<xsl:call-template name="isTrueExpresion">
			    <xsl:with-param name="errorCodeValidate" select="'3249'" />
			    <xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
			    <xsl:with-param name="expresion" select="count($root/cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[substring(text(),1,5) = 'Cuota']]) = 0" />
         			<xsl:with-param name="isError" select ="boolean(number($conError))"/>
       		</xsl:call-template>

			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3251'"/>
				<xsl:with-param name="node" select="cbc:Amount"/>
         			<xsl:with-param name="isError" select ="boolean(number($conError))"/>
			</xsl:call-template>	
		  
      			<xsl:call-template name="validateValueTwoDecimalIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3250'"/>
				<xsl:with-param name="node" select="cbc:Amount"/>
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
			</xsl:call-template>   
			
			<xsl:call-template name="isTrueExpresion">
			    <xsl:with-param name="errorCodeValidate" select="'3265'" />
			    <xsl:with-param name="node" select="cbc:Amount" />
			    <xsl:with-param name="expresion" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount &lt; cbc:Amount" />
			    <xsl:with-param name="isError" select ="boolean(number($conError))"/>
       		</xsl:call-template>
       
       		<xsl:call-template name="isTrueExpresion">
			    <xsl:with-param name="errorCodeValidate" select="'2071'" />
			    <xsl:with-param name="node" select="cbc:Amount/@currencyID" />
			    <xsl:with-param name="expresion" select="$root/cbc:DocumentCurrencyCode != cbc:Amount/@currencyID" />
			</xsl:call-template> 
		</xsl:if>
		</xsl:if>		

		<xsl:if test="$root/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
		<xsl:if test="substring(cbc:PaymentMeansID,1,5) = 'Cuota'">
	        <xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3252'" />
				<xsl:with-param name="node" select="cac:PaymentTerms/cbc:ID" />
				<xsl:with-param name="expresion" select="count($root/cac:PaymentTerms[cbc:ID[text() = 'FormaPago'] and cbc:PaymentMeansID[text() = 'Credito']]) = 0" />
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
				<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
	        </xsl:call-template>
	        				
	        <xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3254'"/>
				<xsl:with-param name="node" select="cbc:Amount"/>
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
				<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
			</xsl:call-template>
	
	        <xsl:call-template name="validateValueTwoDecimalIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3253'"/>
				<xsl:with-param name="node" select="cbc:Amount"/>
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
				<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
			</xsl:call-template>   
	        	
	        <xsl:call-template name="isTrueExpresion">
			    <xsl:with-param name="errorCodeValidate" select="'3266'" />
			    <xsl:with-param name="node" select="cbc:Amount" />
			    <xsl:with-param name="expresion" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount &lt; cbc:Amount" />
			    <xsl:with-param name="isError" select ="boolean(number($conError))"/>
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
				<xsl:with-param name="isError" select ="boolean(number($conError))"/>
				<xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
			</xsl:call-template>
	
	        <xsl:call-template name="regexpValidateElementIfExist">
			    <xsl:with-param name="errorCodeValidate" select="'3255'" />
			    <xsl:with-param name="node" select="cbc:PaymentDueDate" />
			    <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
			    <xsl:with-param name="isError" select ="boolean(number($conError))"/>
			    <xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
	        </xsl:call-template> 
	        
	        <xsl:variable name="fechaEmision" select="$root/cbc:IssueDate" />
	        <xsl:variable name="fechaPago" select="cbc:PaymentDueDate" />
	        <!-- PAS20221U210700014 -->
	        <xsl:variable name="cbcIssueDate" select="date:seconds($fechaEmision)" />
			<xsl:variable name="cacPaymentTermscbcPaymentDueDate" select="date:seconds($fechaPago)" />
	        
	        <xsl:call-template name="isTrueExpresion">
			    <xsl:with-param name="errorCodeValidate" select="'3267'" />
			    <xsl:with-param name="node" select="cbc:PaymentDueDate" />
				<!-- PAS20211U210700163 -->
			    <!-- <xsl:with-param name="expresion" select="number(concat(substring($fechaEmision,1,4),substring($fechaEmision,6,2),substring($fechaEmision,9,2))) &gt;= number(concat(substring($fechaPago,1,4),substring($fechaPago,6,2),substring($fechaPago,9,2)))" />-->
			    <!-- PAS20221U210700014 -->
			    <xsl:with-param name="expresion" select="$cbcIssueDate &gt;= $cacPaymentTermscbcPaymentDueDate" />
		        <xsl:with-param name="isError" select ="boolean(number($conError))"/>
		        <xsl:with-param name="descripcion" select="concat('Error en ', cbc:PaymentMeansID)"/>
	        </xsl:call-template>			
		</xsl:if>    
		</xsl:if>
       </xsl:if>	
    <!-- </xsl:if> -->
		<!-- FIN MIGE -->
    
		<!-- Versión 5 excel -->
		<xsl:if test="cbc:ID and cbc:ID='Detraccion'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3127'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansID"/>
			</xsl:call-template>
			
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3033'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="catalogo" select="'54'"/>
			</xsl:call-template>

			<xsl:if test="$tipoOperacion = '1002'">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'3129'" />
					<xsl:with-param name="node" select="cbc:PaymentMeansID" />
					<xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '004'" />
				</xsl:call-template>
			</xsl:if>

			<xsl:if test="$tipoOperacion = '1003'">
				<xsl:call-template name="isTrueExpresion">
					 <xsl:with-param name="errorCodeValidate" select="'3129'" />
					 <xsl:with-param name="node" select="cbc:PaymentMeansID" />
					 <xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '028'" />
				</xsl:call-template>
			</xsl:if>
		
			<xsl:if test="$tipoOperacion = '1004'">
				<xsl:call-template name="isTrueExpresion">
					 <xsl:with-param name="errorCodeValidate" select="'3129'" />
					 <xsl:with-param name="node" select="cbc:PaymentMeansID" />
					 <xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '027'" />
				</xsl:call-template>
			</xsl:if>
				
			<xsl:call-template name="existAndValidateValueTwoDecimal">
				<xsl:with-param name="errorCodeNotExist" select="'3035'"/>
				<xsl:with-param name="errorCodeValidate" select="'3037'"/>
				<xsl:with-param name="node" select="cbc:Amount"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3208'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Codigo de detraccion)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>

			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo54)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>		

    <!-- PAS20211U210700059 - Excel v7 - Se agrega ERR-3310 y ERR-3311-->	

	
		<xsl:if test="cbc:ID = 'Percepcion'">
			<xsl:call-template name="existAndValidateValueTwoDecimal">
			   <xsl:with-param name="errorCodeNotExist" select="'3310'"/>
			   <xsl:with-param name="errorCodeValidate" select="'3311'"/>
			   <xsl:with-param name="node" select="cbc:Amount"/>
			   <!--xsl:with-param name="isGreaterCero" select="false()"/-->
			</xsl:call-template>
		</xsl:if>

		<!-- Versión 5 excel-->
		<xsl:if test="cbc:Amount and cbc:ID = 'Percepcion'">
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2788'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			</xsl:call-template>
		</xsl:if>
		
    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:PaymentTerms ===========================================

    ===========================================================================================================================================
    -->

    <!--
    ===========================================================================================================================================

    =========================================== Template cac:PaymentMeans ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:PaymentMeans">
		<xsl:param name="tipoOPeracion"/>
		<xsl:param name="codigoProducto"/>

		  <!-- Versión 5 excel -->
      <!--xsl:if test="$codigoProducto"-->
	    <xsl:if test="cbc:ID and cbc:ID='Detraccion'">
      	<xsl:call-template name="existElement">
			   	 <xsl:with-param name="errorCodeNotExist" select="'3034'"/>
			  	 <xsl:with-param name="node" select="cac:PayeeFinancialAccount/cbc:ID"/>
			  </xsl:call-template>
      </xsl:if>

        <xsl:if test="$tipoOPeracion = '0302'">
	    	<!-- <xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3173'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansCode"/>
			</xsl:call-template>
			-->

			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3175'"/>
				<xsl:with-param name="node" select="cbc:PaymentID"/>
			</xsl:call-template>

        </xsl:if>

        <xsl:if test="cbc:PaymentMeansCode">
        	<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3174'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansCode"/>
				<xsl:with-param name="catalogo" select="'59'"/>
			</xsl:call-template>
        </xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Medio de pago)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo59)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:PaymentMeans ===========================================

    ===========================================================================================================================================
    -->



</xsl:stylesheet>
