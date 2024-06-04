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
    
	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />

    <!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='Invoice']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <xsl:key name="by-document-additional-reference" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>
    
    <!-- key Numero de sublineas duplicados fin -->
    <xsl:key name="by-invoiceSubLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine/cac:SubInvoiceLine" use="number(concat(cbc:ID, ../cbc:ID))"/>

    <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>
    
    <!-- key tributos duplicados por sublinea -->
    <xsl:key name="by-tributos-in-subline" match="cac:InvoiceLine/cac:SubInvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../../cbc:ID,'-', ../../cbc:ID)"/>

    <!-- key tributos duplicados por cabecera -->
    <xsl:key name="by-tributos-in-root" match="*[local-name()='Invoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>

    <!-- key AdditionalMonetaryTotal duplicados -->
    <xsl:key name="by-AdditionalMonetaryTotal" match="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal" use="cbc:ID"/>

    <!-- key identificador de prepago duplicados -->
    <xsl:key name="by-idprepaid-in-root" match="*[local-name()='Invoice']/cac:PrepaidPayment" use="cbc:ID"/>

    <xsl:key name="by-document-additional-anticipo" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '02' or text() = '03']]" use="cbc:DocumentStatusCode"/>


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

        <xsl:variable name="monedaComprobante" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount/@currencyID"/>

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
			<xsl:with-param name="regexp" select="'^([F][A-Z0-9]{3}|[0-9]{4})-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1004'"/>
            <xsl:with-param name="errorCodeValidate" select="'1003'"/>
            <xsl:with-param name="node" select="cbc:InvoiceTypeCode"/>
            <xsl:with-param name="regexp" select="'^42$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2472'"/>
			<xsl:with-param name="node" select="cac:InvoicePeriod/cbc:StartDate"/>
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2473'"/>
			<xsl:with-param name="node" select="cac:InvoicePeriod/cbc:EndDate"/>
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2474'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listID"/>
		</xsl:call-template>
		
		<xsl:if test="cbc:InvoiceTypeCode/@listID !='01' and cbc:InvoiceTypeCode/@listID !='02'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2475'" />
	            <xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listID" />
	            <xsl:with-param name="expresion" select="true()" />
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount/@currencyID"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
        
        <!--  La moneda de los totales de línea y totales de comprobantes (excepto para los totales de Percepción (2001) y Detracción (2003)) es diferente al valor del Tag UBL ERROR 2337 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2337'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not(ancestor-or-self::cac:PaymentTerms/cbc:Amount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not (ancestor-or-self::cac:PaymentTerms/cbc:Amount)]" />
        </xsl:call-template>
        
        <!--
        ===========================================================================================================================================
        Datos del Emisor
        ===========================================================================================================================================
        -->

        <xsl:apply-templates select="cac:AccountingSupplierParty">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
	    
	    <!--
        ===========================================================================================================================================
        Datos del cliente o receptor
        ===========================================================================================================================================
        -->
	    
	    <xsl:apply-templates select="cac:AccountingCustomerParty">
          <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
          <xsl:with-param name="root" select="."/>
       </xsl:apply-templates>
       
       <!--
        ===========================================================================================================================================
        Datos del detalle del documento
        ===========================================================================================================================================
        -->
       
       <xsl:apply-templates select="cac:InvoiceLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2487'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2488'"/>
            <xsl:with-param name="errorCodeValidate" select="'2488'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalFacturado" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
		<xsl:variable name="totalProcesado" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
		<xsl:variable name="importeTotal" select="sum(cac:InvoiceLine/cac:ItemPriceExtension/cbc:Amount)"/>
		
        <xsl:variable name="totalImporteCalculado" select="$totalProcesado - $importeTotal"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4363'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="($totalFacturado + 1 ) &lt; $totalImporteCalculado or ($totalFacturado - 1 ) &gt; $totalImporteCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

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

    ============================================ Template cac:AccountingSupplierParty =========================================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AccountingSupplierParty">
    	<xsl:param name="tipoOperacion" select = "'-'" />
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3089'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1008'"/>
            <xsl:with-param name="errorCodeValidate" select="'1007'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'1037'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
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
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4338'"/>
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:AccountingSupplierParty ======================================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AccountingCustomerParty ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:AccountingCustomerParty">
        <xsl:param name="tipoOperacion" select = "'-'" />
        <xsl:param name="root"/>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>

        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2014'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
        
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID != '-'">
	        <xsl:choose>
	            <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
	            	<xsl:if test="(string-length(cac:Party/cac:PartyIdentification/cbc:ID) &gt; 11) or (string-length(cac:Party/cac:PartyIdentification/cbc:ID) &lt; 11)">
	            		<xsl:call-template name="isTrueExpresion">
				            <xsl:with-param name="errorCodeValidate" select="'2017'" />
				            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
				            <xsl:with-param name="expresion" select="true()" />
				        </xsl:call-template>
	            	</xsl:if>
					<xsl:call-template name="regexpValidateElementIfExist">
			             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
			             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
			             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
			         </xsl:call-template>
				</xsl:when>
				<xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='1'">
					<xsl:call-template name="regexpValidateElementIfExist">
		                <xsl:with-param name="errorCodeValidate" select="'4207'"/>
		                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
		                <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="regexpValidateElementIfExist">
		                <xsl:with-param name="errorCodeValidate" select="'4208'"/>
		                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
		                <xsl:with-param name="isError" select ="false()"/>
		            </xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		
		<xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2015'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'2800'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="catalogo" select="'06'"/>
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
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2022'" />
					<xsl:with-param name="errorCodeValidate" select="'2022'" />
					<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        
        <xsl:if test="cac:Party/cac:PartyName/cbc:Name">
	        <xsl:choose>
	        	<xsl:when test="cac:Party/cac:PartyName/cbc:Name and (string-length(cac:Party/cac:PartyName/cbc:Name) &gt; 1500)">
			        <xsl:call-template name="isTrueExpresion">
			            <xsl:with-param name="errorCodeValidate" select="'4099'" />
			            <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name" />
			            <xsl:with-param name="expresion" select="true()" />
			            <xsl:with-param name="isError" select ="false()"/>
			        </xsl:call-template>
	        	</xsl:when>
	        	<xsl:otherwise>
			        <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'4099'" />
						<xsl:with-param name="errorCodeValidate" select="'4099'" />
						<xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name" />
						<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
						<xsl:with-param name="isError" select ="false()"/>
					</xsl:call-template>
	        	</xsl:otherwise>
	        </xsl:choose>
        </xsl:if>
        
        <xsl:if test="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4231'"/>
				<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
        
    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:AccountingCustomerParty ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:InvoiceLine ===========================================

    ===========================================================================================================================================
    -->

	<xsl:template match="cac:InvoiceLine">

		<xsl:param name="root"/>

        <xsl:variable name="nroLinea" select="cbc:ID"/>

        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        
        <xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2023'" />
			<xsl:with-param name="errorCodeValidate" select="'2023'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2752'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>
		
		<xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2476'"/>
			<xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID !='1' and cac:Item/cac:SellersItemIdentification/cbc:ID !='2'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2477'" />
	            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
	            <xsl:with-param name="expresion" select="true()" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID ='1'">
        	<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'2478'"/>
				<xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID ='1'">
        	<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID !='1' and cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID !='2'">
	        	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2479'" />
		            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	        </xsl:if>
        </xsl:if>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID ='2'">
        	<xsl:call-template name="existElementNoVacio">
				<xsl:with-param name="errorCodeNotExist" select="'3195'" />
				<xsl:with-param name="node" select="cac:TaxTotal" />
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3026'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
        </xsl:apply-templates>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2480'"/>
            <xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2481'"/>
            <xsl:with-param name="errorCodeValidate" select="'2481'"/>
            <xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:variable name="totalBase" select="cac:ItemPriceExtension/cbc:Amount" />
        <xsl:variable name="totalComision" select="cbc:LineExtensionAmount" />
        <xsl:variable name="totalIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" />
        <xsl:variable name="totalDescuentosAfecta" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)"/>
        <xsl:variable name="totalDescuentos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)"/>
        <xsl:variable name="totalCargosAfecta" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)"/>
        <xsl:variable name="totalCargos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)"/>
        
		<xsl:variable name="totalBaseLine" select="$totalComision + $totalIGV + $totalCargos + $totalCargosAfecta - $totalDescuentos - $totalDescuentosAfecta" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4348'" />
			<xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount" />
			<xsl:with-param name="expresion" select="($totalBase + 1 ) &lt; $totalBaseLine or ($totalBase - 1) &gt; $totalBaseLine" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID = '1'">
        	<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4364'" />
				<xsl:with-param name="node" select="cbc:ID" />
				<xsl:with-param name="expresion" select="count(cac:SubInvoiceLine/cbc:ID) = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
			<xsl:variable name="sumatoriaImpuestosxSubLinea" select="sum(cac:SubInvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" />
	
			<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'4360'" />
					<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
					<xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $sumatoriaImpuestosxSubLinea or ($totalImpuestosxLinea - 1 ) &gt; $sumatoriaImpuestosxSubLinea" />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
			</xsl:if>
        </xsl:if>
        
        <xsl:apply-templates select="cac:SubInvoiceLine" mode="sublinea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="indInsFinanciera" select="cac:Item/cac:SellersItemIdentification/cbc:ID/@schemeID"/>
        </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera">
        	<xsl:with-param name="root" select="$root"/>
        	<xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        
        <xsl:if test="cac:SubInvoiceLine">
	        <xsl:variable name="totalComisionxLinea" select="cbc:LineExtensionAmount" />
			<xsl:variable name="SumatoriaComisionxLinea" select="sum(cac:SubInvoiceLine/cbc:LineExtensionAmount)" />
	
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4354'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($totalComisionxLinea + 1) &lt; $SumatoriaComisionxLinea or ($totalComisionxLinea - 1 ) &gt; $SumatoriaComisionxLinea" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
        </xsl:if>
		
		<xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID ='2'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2042'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']) = 0" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
			<xsl:variable name="sumatoriaImpuestosxLinea" select="(round(((cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)*0.18)*100) div 100)" />
	
			<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
				<xsl:call-template name="isTrueExpresion">
					<xsl:with-param name="errorCodeValidate" select="'4360'" />
					<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
					<xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $sumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1 ) &gt; $sumatoriaImpuestosxLinea" />
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
			</xsl:if>
			
        </xsl:if>

	</xsl:template>

	<!--
    ===========================================================================================================================================

    =========================================== fin Template cac:InvoiceLine ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        <xsl:param name="valorVenta"/>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'3031'"/>
			<xsl:with-param name="errorCodeValidate" select="'3031'"/>
			<xsl:with-param name="node" select="cac:TaxSubtotal/cbc:TaxableAmount"/>
			<xsl:with-param name="isGreaterCero" select="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        
        <xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
		   <xsl:with-param name="cntLineaProd" select="$cntLineaProd"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>

    </xsl:template>
    
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal ===========================================

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
                <xsl:when test="$codigoTributo = '2000'">
                    <xsl:value-of select="'isc'"/>
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
    
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2036'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(1000)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@listName"/>
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>
    
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:SubInvoiceLine ===========================================

    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:SubInvoiceLine" mode="sublinea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        <xsl:param name="indInsFinanciera"/>
        
        <xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2023'" />
			<xsl:with-param name="errorCodeValidate" select="'2023'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2752'" />
			<xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-invoiceSubLine-id', number(concat(cbc:ID, $nroLinea)))) &gt; 1" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')" />
		</xsl:call-template>
		
		<xsl:if test="$indInsFinanciera = '1'">
		
			<xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'2484'"/>
	            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
			
			<xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'2516'"/>
	            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2485'"/>
				<xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
				<xsl:with-param name="regexp" select="'^(6)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'2482'"/>
	            <xsl:with-param name="node" select="cac:ItemPriceExtension"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
        </xsl:if>
        
        <xsl:choose>
        	<xsl:when test="cac:Item/cbc:Description and (string-length(cac:Item/cbc:Description) &gt; 1500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'4350'" />
		            <xsl:with-param name="node" select="cac:Item/cbc:Description" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'4350'" />
					<xsl:with-param name="errorCodeValidate" select="'4350'" />
					<xsl:with-param name="node" select="cac:Item/cbc:Description" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'4350'" />
					<xsl:with-param name="errorCodeValidate" select="'4350'" />
					<xsl:with-param name="node" select="cac:Item/cbc:Description" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
					<xsl:with-param name="isError" select ="false()"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'2486'"/>
			<xsl:with-param name="errorCodeValidate" select="'2486'"/>
			<xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
			<xsl:with-param name="isGreaterCero" select="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:apply-templates select="cac:TaxTotal" mode="sublinea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="nroSubLinea" select="cbc:ID"/>
        </xsl:apply-templates>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'2483'"/>
			<xsl:with-param name="errorCodeValidate" select="'2483'"/>
			<xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount"/>
			<xsl:with-param name="isGreaterCero" select="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

		<xsl:variable name="importeTotal" select="cac:ItemPriceExtension/cbc:Amount"/>
		<xsl:variable name="importeComision" select="cbc:LineExtensionAmount"/>
		<xsl:variable name="importeIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
		
        <xsl:variable name="totalImporteCalculado" select="$importeComision + $importeIGV"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4349'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="($importeTotal + 1 ) &lt; $totalImporteCalculado or ($importeTotal - 1 ) &gt; $totalImporteCalculado" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

    </xsl:template>
    
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:SubInvoiceLine ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template - sublinea cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxTotal" mode="sublinea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="nroSubLinea"/>
        <xsl:param name="root"/>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
			<xsl:with-param name="errorCodeNotExist" select="'2497'"/>
			<xsl:with-param name="errorCodeValidate" select="'2497'"/>
			<xsl:with-param name="node" select="cbc:TaxAmount"/>
			<xsl:with-param name="isGreaterCero" select="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
		</xsl:call-template>
        
        <xsl:if test="cbc:TaxAmount &lt; 0">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2497'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount"/>
	            <xsl:with-param name="expresion" select="true()" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:apply-templates select="cac:TaxSubtotal" mode="sublinea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
           <xsl:with-param name="nroSubLinea" select="$nroSubLinea"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>

    </xsl:template>
    
    <!--
    ===========================================================================================================================================

    =========================================== fin Template - sublinea cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template - sublinea cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxSubtotal" mode="sublinea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="nroSubLinea"/>
        <xsl:param name="root"/>
		
		<xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2590'"/>
            <xsl:with-param name="errorCodeValidate" select="'2590'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
        </xsl:call-template>
        
        <xsl:variable name="importeImpuesto" select="cbc:TaxAmount" />
        <xsl:variable name="importeBase" select="cbc:TaxableAmount" />
		<xsl:variable name="importeCalculado" select="$importeBase*0.18" />

		<xsl:if test="$importeImpuesto &gt; 0">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4365'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($importeImpuesto + 1 ) &lt; $importeCalculado or ($importeImpuesto - 1 ) &gt; $importeCalculado" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2036'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(1000)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-subline', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea,'-', $nroSubLinea))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>
    
    <!--
    ===========================================================================================================================================

    =========================================== fin Template - sublinea cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->
    
    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="cabecera">
    	<xsl:param name="root"/>
    	<xsl:param name="nroLinea"/>
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3073'" />
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
        <xsl:if test="cbc:AllowanceChargeReasonCode ='47' or cbc:AllowanceChargeReasonCode ='48'">
        	<xsl:if test="cbc:ChargeIndicator and cbc:ChargeIndicator !='true'">
	        	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3114'" />
		            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	        </xsl:if>
        </xsl:if>
        
        <xsl:if test="cbc:AllowanceChargeReasonCode ='00' or cbc:AllowanceChargeReasonCode ='01'">
        	<xsl:if test="cbc:ChargeIndicator and cbc:ChargeIndicator !='false'">
	        	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3114'" />
		            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	        </xsl:if>
        </xsl:if>
		
		<xsl:if test="cbc:AllowanceChargeReasonCode !='00' and cbc:AllowanceChargeReasonCode !='01' and cbc:AllowanceChargeReasonCode !='47' and cbc:AllowanceChargeReasonCode !='48'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4268'" />
	            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
	            <xsl:with-param name="expresion" select="true()" />
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2955'"/>
            <xsl:with-param name="errorCodeValidate" select="'2955'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge ===========================================

    ===========================================================================================================================================
    -->

</xsl:stylesheet>