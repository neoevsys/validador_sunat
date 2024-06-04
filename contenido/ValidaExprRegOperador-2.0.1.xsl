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
     <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>
	 <xsl:key name="by-subinvoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine/cac:SubInvoiceLine" use="number(concat(cbc:ID, ../cbc:ID))"/>
	 <!--<xsl:key name="by-subinvoiceLine-id-total" match="*[local-name()='Invoice']/cac:InvoiceLine/cac:SubInvoiceLine" use="number(concat(cbc:ID, ../cbc:ID))"/>-->
	 <xsl:key name="by-tributos-in-root" match="*[local-name()='Invoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
	 <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>
	<!-- key tributos duplicados por sublinea JFB-->
    <xsl:key name="by-tributos-in-subline" match="cac:InvoiceLine/cac:SubInvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../../cbc:ID,'-', ../../cbc:ID)"/>
	<!-- key codigo de leyenda root -->
	<xsl:key name="by-note-in-root" match="*[local-name()='Invoice']/cbc:Note" use="@languageLocaleID"/>
	<xsl:key name="by-note-in-invoiceline" match="*[local-name()='Invoice']/cac:InvoiceLine/cbc:Note" use="concat(../cbc:ID, '-', @languageLocaleID)"/>

	
	<xsl:template match="/*">
		 <!-- 
        ==============================================================================|=============================================================
        Variables  
        ===========================================================================================================================================
        -->
        
        <xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
        <xsl:variable name="tipoOperacion" select="cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        <xsl:variable name="nroLinea" select="cbc:ID"/>	
		<!-- JFB-->
        <xsl:variable name="monedaComprobante" select="cac:LegalMonetaryTotal/cbc:PayableAmount/@currencyID"/>
        
        
        <!-- 
        ==============================================================================|=============================================================
        validaciones
        ===========================================================================================================================================
        -->
               
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="$cbcUBLVersionID"/>
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
		
		
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1035'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroSerie != substring(cbc:ID, 1, 4)" />
        </xsl:call-template>
        
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1036'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroComprobante != substring(cbc:ID, 6)" />
        </xsl:call-template>
        
         
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<xsl:with-param name="regexp" select="'^([F][A-Z0-9]{3})-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1004'"/>
            <xsl:with-param name="errorCodeValidate" select="'1003'"/>
            <xsl:with-param name="node" select="cbc:InvoiceTypeCode"/>
            <xsl:with-param name="regexp" select="'^(34)$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cac:LegalMonetaryTotal/cbc:PayableAmount/@currencyID"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
		
		<!-- jfl -->
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2337'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not(ancestor-or-self::cac:PaymentTerms/cbc:Amount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not (ancestor-or-self::cac:PaymentTerms/cbc:Amount)]" />
        </xsl:call-template>


        <!-- Inicio - PAS20201U210400026 - Error 3006 de DAE tipo 34. -->
        <xsl:apply-templates select="cbc:Note" mode="cabecera"/>
        
        <!--
		<xsl:if test="cbc:Note/@languageLocaleID != '-'">
              <xsl:call-template name="findElementInCatalog">
			      <xsl:with-param name="errorCodeValidate" select="'3027'"/>
    			  <xsl:with-param name="idCatalogo" select="cbc:Note/@languageLocaleID"/>
    			  <xsl:with-param name="catalogo" select="'52'"/>
			  </xsl:call-template>
       </xsl:if> 
	   
	   <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4362'" />
            <xsl:with-param name="node" select="cbc:Note" />
            <xsl:with-param name="expresion" select="count(cbc:Note/@languageLocaleID) &gt; 1" />
            <xsl:with-param name="isError" select ="false()"/>
       </xsl:call-template>
         
        <xsl:choose>
        	<xsl:when test="(string-length(cbc:Note) &gt; 500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3006'" />
		            <xsl:with-param name="node" select="cbc:Note" />
		            <xsl:with-param name="expresion" select="true()" />
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'3006'" />
					<xsl:with-param name="errorCodeValidate" select="'3006'" />
					<xsl:with-param name="node" select="cbc:Note" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'3006'" />
					<xsl:with-param name="errorCodeValidate" select="'3006'" />
					<xsl:with-param name="node" select="cbc:Note" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
				</xsl:call-template>
        	</xsl:otherwise>
        </xsl:choose>
		-->
		
		<!-- Fin - PAS20201U210400026 - Error 3006 de DAE tipo 34. -->
		
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
        Datos del AccountingSupplierParty
        ===========================================================================================================================================
        -->
        <xsl:apply-templates select="cac:AccountingSupplierParty">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
		
		<!--
        ===========================================================================================================================================
        Datos del AccountingCustomerParty
        ===========================================================================================================================================
        -->
		<xsl:apply-templates select="cac:AccountingCustomerParty">
          <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
          <xsl:with-param name="root" select="."/>
       </xsl:apply-templates>
        
		
		<!--
        ===========================================================================================================================================
        Datos del TaxTotal Cabecera
        ===========================================================================================================================================
        -->
        
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2956'"/>
			<xsl:with-param name="node" select="cac:TaxTotal" />
	    </xsl:call-template>
	    
	    <xsl:call-template name="isTrueExpresion">
        	<xsl:with-param name="errorCodeValidate" select="'2278'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9997']) = 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
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
        <!--<xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
        </xsl:apply-templates>-->
        
		<!--
        ===========================================================================================================================================
        Datos del LegalMonetaryTotal
        ===========================================================================================================================================
        -->
		 
		 
		 <xsl:variable name="totalValorVenta" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
		 <xsl:variable name="totalValorVentaParticipe" select="sum(cac:InvoiceLine/cbc:LineExtensionAmount)"/>
		 
		 <xsl:variable name="totalPrecioVenta" select="sum(cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount)"/>
		 <xsl:variable name="totalCargos" select="sum(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount)"/>
         <xsl:variable name="totalAnticipo" select="sum(cac:LegalMonetaryTotal/cbc:PrepaidAmount)"/>
		 <xsl:variable name="totalDescuentos" select="sum(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount)"/>
         <xsl:variable name="totalRedondeo" select="sum(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)"/>
		 <xsl:variable name="cargosGlobalesAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '45' or text() = '50']]/cbc:Amount)"/>
		 <xsl:variable name="DescuentoGlobalesAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '03']]/cbc:Amount)"/>
		 <xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)"/>
		 <xsl:variable name="totalDescuentosxLinea" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '03']]/cbc:Amount)"/>
		 <xsl:variable name="totalCargosxLinea" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '45' or text() = '50']]/cbc:Amount)"/>
		 <xsl:variable name="SumatoriaImpuesto" select="cac:TaxTotal/cbc:TaxAmount"/>
		 <xsl:variable name="SumatoriaCargos" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
		 <xsl:variable name="SumatoriaDescuentos" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>
		 		 
		<xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta + $totalCargos - $totalDescuentos - $totalAnticipo + $totalRedondeo"/>
		<xsl:variable name="totalImporte" select="sum(cac:LegalMonetaryTotal/cbc:PayableAmount)"/>
		<xsl:variable name="totalValorVentaCalculado" select="$totalValorVentaxLinea - $DescuentoGlobalesAfectaBI + $cargosGlobalesAfectaBI"/>
		<xsl:variable name="totalImporteDAE" select="$totalValorVenta + $SumatoriaImpuesto + $SumatoriaCargos - $SumatoriaDescuentos"/>
		<xsl:variable name="nroLinea" select="cbc:ID"/>
		
		<xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2487'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
        </xsl:call-template>
		
		<xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2488'"/>
            <xsl:with-param name="errorCodeValidate" select="'2488'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
       </xsl:call-template>
       
	   <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4309'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount" />
			<xsl:with-param name="expresion" select="($totalValorVenta + 1 ) &lt; $totalValorVentaParticipe or ($totalValorVenta - 1) &gt; $totalValorVentaParticipe" />
			<xsl:with-param name="isError" select ="false()"/>
       </xsl:call-template>
		 
		
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4307'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount" />
			<xsl:with-param name="expresion" select="($totalDescuentos + 1 ) &lt; $totalDescuentosxLinea or ($totalDescuentos - 1) &gt; $totalDescuentosxLinea" />
			<xsl:with-param name="isError" select ="false()"/>
       </xsl:call-template>
       
       <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4308'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount" />
            <xsl:with-param name="expresion" select="($totalCargos + 1 ) &lt; $totalCargosxLinea or ($totalCargos - 1) &gt; $totalCargosxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4312'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="($totalImporte + 1 ) &lt; $totalImporteDAE or ($totalImporte - 1) &gt; $totalImporteDAE" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
		<xsl:variable name="SumatoriaIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
        
        <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			 <xsl:call-template name="isTrueExpresion">
		         <xsl:with-param name="errorCodeValidate" select="'4290'" />
		         <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
		         <xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $SumatoriaIGVLinea or ($SumatoriaIGV - 1) &gt; $SumatoriaIGVLinea" />
		         <xsl:with-param name="isError" select ="false()"/>
		     </xsl:call-template>
        </xsl:if>
		
				
		<!--
        ===========================================================================================================================================
        Invoice Line
        ===========================================================================================================================================
        -->
		
		<xsl:apply-templates select="cac:InvoiceLine">
			<xsl:with-param name="root"/>            			
		</xsl:apply-templates>
		
		
		
	<!-- Retornamos el comprobante al flujo necesario para lotes -->
        <xsl:copy-of select="."/>	
	</xsl:template>
	
	
	 <!--
    ===========================================================================================================================================

    =========================================== Template cbc:Note ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cbc:Note" mode="cabecera">

		<xsl:if test="@languageLocaleID">
            <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'"/>
				<xsl:with-param name="idCatalogo" select="@languageLocaleID"/>
				<xsl:with-param name="catalogo" select="'52'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4362'" />
            <xsl:with-param name="node" select="@languageLocaleID" />
            <xsl:with-param name="expresion" select="count(key('by-note-in-root', @languageLocaleID)) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Leyenda: ', @languageLocaleID)"/>
            <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
         
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/>
            <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/> 
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="expresion" select="string-length(text()) &gt; 500 or string-length(text()) &lt; 0 "/>
            <xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
        </xsl:call-template>
        
	  </xsl:template>
	
	
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

    =========================================== Fin - Template cac:AccountingSupplierParty ===========================================

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
	   <xsl:variable name="nroLinea" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'3090'" />
             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
             <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <xsl:call-template name="existElementNoVacio">
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
		                <xsl:with-param name="errorCodeValidate" select="'2801'"/>
		                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
		            </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="(cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='4') or (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='7') or
					   (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='0') or (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='A') or 
					   (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='B') or (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='C') or
					   (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='D') or (cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='E')">
					       <xsl:call-template name="regexpValidateElementIfExist">
		                     <xsl:with-param name="errorCodeValidate" select="'2802'"/>
		                     <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		                     <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
		                   </xsl:call-template>
		            </xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>   
				
		 <xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2015'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
		
		 <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
              <xsl:call-template name="findElementInCatalog">
			      <xsl:with-param name="errorCodeValidate" select="'2800'"/>
    			  <xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
    			  <xsl:with-param name="catalogo" select="'06'"/>
			  </xsl:call-template>
         </xsl:if>  
		
			 
     <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
     </xsl:call-template>
	 
	 <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2021'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
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
   
	</xsl:template> 

    <!--
    ===========================================================================================================================================

    =========================================== FIN Template cac:AccountingCustomerParty ===========================================

    ===========================================================================================================================================
    -->	

  <!--
    ===========================================================================================================================================

    =========================================== Template cac:DespatchDocumentReference ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:DespatchDocumentReference">
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
	 
       <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2364'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        

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
    
    <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4010'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4010'"/>
	            <xsl:with-param name="node" select="cbc:ID"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,30}$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	  </xsl:call-template>
	  
      <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2365'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
       </xsl:call-template>
     
       <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4009'"/>
	            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
	            <xsl:with-param name="regexp" select="'^(05|99)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
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

    =========================================== inicio Template cac:InvoiceLine ===========================================

    ===========================================================================================================================================
    -->
    
     <xsl:template match="cac:InvoiceLine">
     <xsl:param name="root"/>
	 <xsl:variable name="nroLinea" select="cbc:ID"/>
	 
	 <xsl:variable name="totalValorVentaxLinea" select="cbc:LineExtensionAmount"/>
     <xsl:variable name="DsctosAfectanBIxLinea" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
     <xsl:variable name="CargosAfectanBIxLinea" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
     <xsl:variable name="SumatoriaValorVentaxLinea" select="sum(cac:SubInvoiceLine/cbc:LineExtensionAmount) - $DsctosAfectanBIxLinea +$CargosAfectanBIxLinea "/>
	 
               
     <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
            <xsl:with-param name="errorCodeValidate" select="'2023'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
     </xsl:call-template>
        
     <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
     </xsl:call-template>

	 <xsl:if test="cac:Item/cbc:Description">
	     <xsl:choose>
	     	<xsl:when test="string-length(cac:Item/cbc:Description) &gt; 1500 or string-length(cac:Item/cbc:Description) &lt; 3 " >
	     		<!-- xsl:when test="cac:Item/cbc:Description and (string-length(cac:Item/cbc:Description) &gt; 1500)"-->
				<xsl:call-template name="isTrueExpresion">
				    <xsl:with-param name="errorCodeValidate" select="'4350'" />
				    <xsl:with-param name="node" select="cac:Item/cbc:Description" />
				    <xsl:with-param name="expresion" select="true()" />
				    <xsl:with-param name="isError" select ="false()"/>
				    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
				</xsl:call-template>
		    </xsl:when>
	     	<xsl:otherwise>
				<xsl:call-template name="existAndRegexpValidateElement">
				       <xsl:with-param name="errorCodeNotExist" select="'4350'" />
				       <xsl:with-param name="errorCodeValidate" select="'4350'"/>
				       <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
				       <xsl:with-param name="isError" select ="false()"/>
				       <xsl:with-param name="regexp" select="'^(?!\s*$)[^\n\t\r\f]{3,}$'"/> 
				       <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
				</xsl:call-template>
	     	</xsl:otherwise>
	     </xsl:choose>
     </xsl:if>
	 
	 <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
    </xsl:call-template>
	
	<xsl:call-template name="isTrueExpresion">
		<xsl:with-param name="errorCodeValidate" select="'4354'" />
		<xsl:with-param name="node" select="cbc:LineExtensionAmount" />
		<xsl:with-param name="expresion" select="($totalValorVentaxLinea + 1) &lt; $SumatoriaValorVentaxLinea or ($totalValorVentaxLinea - 1 ) &gt; $SumatoriaValorVentaxLinea"/>
		<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
		<xsl:with-param name="isError" select ="false()"/>
    </xsl:call-template>
	 
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
     
     	<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3105'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9997']]) &lt; 1" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
	 
	  <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
			<xsl:with-param name="cntLineaProd" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
      </xsl:apply-templates>
      
	  <!--inicio OriginatorParty -->
	  
	    <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2490'" />
            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:OriginatorParty/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
	  
	   <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2491'"/>
            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
       </xsl:call-template>
	 
	   
	   <xsl:if test="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
			 <xsl:choose>
		       	<xsl:when test="(string-length(cac:OriginatorParty/cac:PartyIdentification/cbc:ID) &gt; 11) or (string-length(cac:OriginatorParty/cac:PartyIdentification/cbc:ID) &lt; 11)">
			        <xsl:call-template name="isTrueExpresion">
			            <xsl:with-param name="errorCodeValidate" select="'2489'" />
			            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
			            <xsl:with-param name="expresion" select="true()" />
			            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			        </xsl:call-template>
		       	</xsl:when>
		       	<xsl:otherwise>
			        <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2489'" />
						<xsl:with-param name="errorCodeValidate" select="'2489'" />
						<xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
						<xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
					</xsl:call-template>
		       	</xsl:otherwise>
	       </xsl:choose>
	  </xsl:if>
	  
	  <xsl:variable name="codigoDocumento" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	  <xsl:if test="$codigoDocumento ='4' or $codigoDocumento ='7' or $codigoDocumento ='0' or $codigoDocumento ='A' or $codigoDocumento ='B' or $codigoDocumento ='C'
	   				or $codigoDocumento ='D' or $codigoDocumento ='E'">
	         <xsl:choose>
	        	<xsl:when test="(string-length(cac:OriginatorParty/cac:PartyIdentification/cbc:ID) &gt; 15)">
			        <xsl:call-template name="isTrueExpresion">
			            <xsl:with-param name="errorCodeValidate" select="'2489'" />
			            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
			            <xsl:with-param name="expresion" select="true()" />
			            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			        </xsl:call-template>
	        	</xsl:when>
	        	<xsl:otherwise>
			        <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2489'" />
						<xsl:with-param name="errorCodeValidate" select="'2489'" />
						<xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
						<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
					</xsl:call-template>
					
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2489'" />
						<xsl:with-param name="errorCodeValidate" select="'2489'" />
						<xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID" />
						<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
						<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
					</xsl:call-template>
	        	</xsl:otherwise>
	        </xsl:choose>
	  </xsl:if>
	  
	  <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2516'"/>
            <xsl:with-param name="node" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>            
       </xsl:call-template>
	   
	    <xsl:if test="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
              <xsl:call-template name="findElementInCatalog">
			      <xsl:with-param name="errorCodeValidate" select="'2016'"/>
    			  <xsl:with-param name="idCatalogo" select="cac:OriginatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
    			  <xsl:with-param name="catalogo" select="'06'"/>
			  </xsl:call-template>
         </xsl:if>
		 
		 <xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
			<xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>

		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2480'"/>
            <xsl:with-param name="node" select="cac:ItemPriceExtension"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
	  
	   <xsl:call-template name="existAndValidateValueTwoDecimal">
           <xsl:with-param name="errorCodeNotExist" select="'2481'"/>
           <xsl:with-param name="errorCodeValidate" select="'2481'"/>
           <xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount"/>
           <xsl:with-param name="isGreaterCero" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
       </xsl:call-template>
       
       <!-- Inicio - PAS20201U210400026 - Error 3006 de DAE tipo 34. -->
       <!--
       <xsl:choose>
        	<xsl:when test="(string-length(cbc:Note) &gt; 500)">
		        <xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3006'" />
		            <xsl:with-param name="node" select="cbc:Note" />
		            <xsl:with-param name="expresion" select="true()" />
		        </xsl:call-template>
        	</xsl:when>
        	<xsl:otherwise>
		        <xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'3006'" />
					<xsl:with-param name="errorCodeValidate" select="'3006'" />
					<xsl:with-param name="node" select="cbc:Note" />
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,}$'" />
				</xsl:call-template>
				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'3006'" />
					<xsl:with-param name="errorCodeValidate" select="'3006'" />
					<xsl:with-param name="node" select="cbc:Note" />
					<xsl:with-param name="regexp" select="'^[^\t\n\r]{0,}$'"/>
				</xsl:call-template>
        	</xsl:otherwise>
       </xsl:choose>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4362'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(cbc:Note/@languageLocaleID) &gt; 1" />
            <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
        -->
        <xsl:apply-templates select="cbc:Note" mode="linea">
        	<xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        <!-- Fin - PAS20201U210400026 - Error 3006 de DAE tipo 34. -->
        
        <xsl:variable name="totalBase" select="cac:ItemPriceExtension/cbc:Amount" />
        <xsl:variable name="totalComision" select="cbc:LineExtensionAmount" />
        <xsl:variable name="totalIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)" />
        <xsl:variable name="totalISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)" />
        <xsl:variable name="totalDescuentos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '03']/cbc:Amount)"/>
        <xsl:variable name="totalCargosFise" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '50']/cbc:Amount)"/>
        <xsl:variable name="totalCargos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '45']/cbc:Amount)"/>
        
		<xsl:variable name="totalBaseLine" select="$totalComision + $totalIGV + $totalISC + $totalCargos + $totalCargosFise - $totalDescuentos" />

		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4348'" />
			<xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount" />
			<xsl:with-param name="expresion" select="($totalBase + 1 ) &lt; $totalBaseLine or ($totalBase - 1) &gt; $totalBaseLine" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:variable name="totalISC" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
		<xsl:variable name="totalSubLineISC" select="sum(cac:SubInvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)" />

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4359'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalSubLineISC or ($totalISC - 1 ) &gt; $totalSubLineISC" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
		<xsl:variable name="totalVenta" select="sum(cac:SubInvoiceLine/cbc:LineExtensionAmount)" />
		<xsl:variable name="totalSubLineISC" select="sum(cac:SubInvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)" />
		<xsl:variable name="totalDescuentos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '02']/cbc:Amount)"/>
        <xsl:variable name="totalCargos" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '49']/cbc:Amount)"/>
        <xsl:variable name="sumatoriaImpuestosxLinea" select="(round((($totalVenta + $ totalSubLineISC + $totalCargos - $totalDescuentos)*0.18)*100) div 100)" />

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4360'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $sumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1 ) &gt; $sumatoriaImpuestosxLinea" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]">
     		<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4360'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxAmount &lt; 0 or cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxAmount &gt; 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
	  
	  <!--fin OriginatorParty -->
       
      <xsl:apply-templates select="cac:SubInvoiceLine" mode="linea">
            <xsl:with-param name="root" select="."/>
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

    =========================================== Begin Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
	
	 <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
		<xsl:param name="cntLineaProd"/>
        <xsl:param name="root"/>
        <xsl:param name="valorVenta"/>
		
		<!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3021 -->
		
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<xsl:variable name="totalImpuestosxLinea" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '2000' or text() = '9999']]/cbc:TaxAmount)"/>
		<xsl:if test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '7152' or text() = '1016' or text() = '2000' or text() = '9999']">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4293'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="(round(($totalImpuestosxLinea + 1 )*100) div 100) &lt; $SumatoriaImpuestosxLinea or (round(($totalImpuestosxLinea - 1 )*100) div 100) &gt; $SumatoriaImpuestosxLinea" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	    </xsl:if>
		
		<xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
		   <xsl:with-param name="cntLineaProd" select="$cntLineaProd"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
		
   </xsl:template>

<!--
    ===========================================================================================================================================

    ===========================================End  Template cac:TaxTotal ===========================================

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
			<xsl:with-param name="regexp" select="'^(1000|9997|2000)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
   </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal ===========================================

    ===========================================================================================================================================
    -->		
	
	<!--
    ===========================================================================================================================================

    =========================================== inicio Template cac:SubInvoiceLine ===========================================

    ===========================================================================================================================================
    -->
	<xsl:template match="cac:SubInvoiceLine" mode="linea">
        <xsl:param name="root"/>
		<xsl:param name="nroLinea"/>
		<xsl:variable name="nroSubLinea" select="cbc:ID"/>	
		
		<xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount"/>
        <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount"/>
        <xsl:variable name="CantidadItem" select="cbc:InvoicedQuantity"/>
        <xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '00' or text() = '07']]/cbc:Amount)"/>
        <xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '47' or text() = '54']]/cbc:Amount)"/>
        <xsl:variable name="ValorVentaxItemCalculado" select="($ValorVentaUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/>
		
		
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2492'"/>
            <xsl:with-param name="errorCodeValidate" select="'2492'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
       </xsl:call-template>
	 
	    <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2493'" />
            <xsl:with-param name="node" select="cbc:ID" />
			<xsl:with-param name="expresion" select="count(key('by-subinvoiceLine-id', number(concat(cbc:ID, $nroLinea)))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>	
		
		<xsl:if test="cbc:InvoicedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
                <xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
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
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[\s\S].{0,}'"/> 
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2068'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2486'"/>
            <xsl:with-param name="errorCodeValidate" select="'2486'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
       </xsl:call-template>

        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2494'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
        </xsl:call-template>

       <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2495'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
       </xsl:call-template>	
        <!-- inicio JFB -->
        <xsl:variable name="importeTotal" select="cac:ItemPriceExtension/cbc:Amount"/>
		<xsl:variable name="importeComision" select="cbc:LineExtensionAmount"/>
		<xsl:variable name="importeIGV_ISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '2000']]/cbc:TaxAmount)"/>
		
        <xsl:variable name="totalImporteCalculado" select="$importeComision + $importeIGV_ISC"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4349'" />
            <xsl:with-param name="node" select="cac:ItemPriceExtension/cbc:Amount" />
            <xsl:with-param name="expresion" select="($importeTotal + 1 ) &lt; $totalImporteCalculado or ($importeTotal - 1 ) &gt; $totalImporteCalculado" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2584'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '9997']) = 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4365'" />
				<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubTotal/cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubTotal/cbc:TaxAmount = 0" />
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<!--  -->
		
		<xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4355'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="(($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
	    <!--  -->		   
    <!-- inicio JFB -->
    
    <xsl:variable name="totalImporteIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
    <xsl:variable name="totalImporteISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
    
    <xsl:variable name="importeSubImpuesto" select="cac:TaxTotal/cbc:TaxAmount"/>
    <xsl:variable name="sumaSubImpuesto" select="$totalImporteIGV + $totalImporteISC"/>
     
     <xsl:call-template name="isTrueExpresion">
         <xsl:with-param name="errorCodeValidate" select="'4356'" />
         <xsl:with-param name="node" select="cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
         <xsl:with-param name="expresion" select="($importeSubImpuesto + 1 ) &lt; $sumaSubImpuesto or ($importeSubImpuesto - 1 ) &gt; $sumaSubImpuesto" />
         <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
         <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>
	  
    <xsl:apply-templates select="cac:TaxTotal" mode="sublinea">
	  <xsl:with-param name="root" select="."/>
	  <xsl:with-param name="nroLinea" select="$nroLinea"/>
	  <xsl:with-param name="nroSubLinea" select="$nroSubLinea"/>
	</xsl:apply-templates>
	
	<xsl:apply-templates select="cac:AllowanceCharge" mode="sublinea">
	  <xsl:with-param name="root" select="."/>
	</xsl:apply-templates>
	
	<xsl:call-template name="existElement">
		<xsl:with-param name="errorCodeNotExist" select="'2482'"/>
		<xsl:with-param name="node" select="cac:ItemPriceExtension"/>
		<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
    </xsl:call-template>
	
	<xsl:apply-templates select="cac:ItemPriceExtension" mode="sublinea">
	  <xsl:with-param name="root" select="."/>
	</xsl:apply-templates>
		 
	
   </xsl:template>	
   
   
   <!--
    ===========================================================================================================================================

    =========================================== inicio Template cac:SubInvoiceLine ===========================================

    ===========================================================================================================================================
    -->
	
	<!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal sublinea ===========================================

    ===========================================================================================================================================
    -->
	
   <xsl:template match="cac:TaxTotal" mode="sublinea">
      <xsl:param name="root"/>
	  <xsl:param name="nroLinea"/>
	  <xsl:param name="nroSubLinea"/>
	  
         <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2496'"/>
            <xsl:with-param name="errorCodeValidate" select="'2496'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
       </xsl:call-template>
	   
	   <xsl:apply-templates select="cac:TaxSubtotal" mode="sublinea">
           <xsl:with-param name="root" select="."/>
		   <xsl:with-param name="nroLinea" select="$nroLinea"/>
		   <xsl:with-param name="nroSubLinea" select="$nroSubLinea"/>
        </xsl:apply-templates>
	     
   </xsl:template>

 <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal sublinea ===========================================

    ===========================================================================================================================================
    -->	
	
	<!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxSubTotal sublinea ===========================================

    ===========================================================================================================================================
    -->	
	   
   <xsl:template match="cac:TaxSubtotal" mode="sublinea">
     <xsl:param name="root"/> 
	 <xsl:param name="nroLinea"/>
	 <xsl:param name="nroSubLinea"/>
	 
	 <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
	 <xsl:variable name="taxableAmount" select="cbc:TaxableAmount"/>
	 
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
				<xsl:when test="$codigoTributo = '7152'">
                    <xsl:value-of select="'oth'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
      </xsl:variable>
	  
	   <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2497'"/>
            <xsl:with-param name="errorCodeValidate" select="'2497'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
       </xsl:call-template>
	   
	   <xsl:if test="$codigoTributo != '2000'">
	      <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3210'" />
              <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
              <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea,'codigo tributo: ', $codigoTributo)"/>
           </xsl:call-template>
        </xsl:if>
	   
	      <xsl:if test="$codigoTributo = '2000' and cbc:TaxAmount &gt; 0 "> 
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
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2498'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
	    </xsl:call-template>
				
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2499'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxCategory/cac:TaxScheme/cbc:ID) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:if test="$codigoTributo = '1000'">
			<xsl:call-template name="existAndValidateValueTwoDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2590'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2590'"/>
	            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Sublinea: ',$nroSubLinea, ' Taxableamount: ', $taxableAmount)"/>
	        </xsl:call-template>
		</xsl:if>
	   
	   <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2497'"/>
            <xsl:with-param name="errorCodeValidate" select="'2497'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
       </xsl:call-template>
	   
	   <xsl:if test="$codigoTributo = '1000' or $codigoTributo = '9997' ">
				<xsl:call-template name="findElementInCatalogProperty">
					<xsl:with-param name="catalogo" select="'07'"/>
					<xsl:with-param name="propiedad" select="$codTributo"/>
					<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
					<xsl:with-param name="valorPropiedad" select="'1'"/>
					<xsl:with-param name="errorCodeValidate" select="'2040'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2036'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(1000|9997|2000)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<!-- INICIO JFB -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2499'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-subline', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea,'-', $nroSubLinea))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' sublinea: ', $nroSubLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2498'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
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
		
	 <!-- FIN JFB-->   
	     
   </xsl:template>
	   
	<!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxSubTotal sublinea ===========================================

    ===========================================================================================================================================
    -->	
	
	<!--
    ===========================================================================================================================================

    =========================================== Template cac:TaxTotal Cabecera ===========================================

    ===========================================================================================================================================
    -->

    <xsl:template match="cac:TaxTotal" mode="cabecera">

        <xsl:param name="root"/>
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
		
		<xsl:variable name="totalISC" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <xsl:variable name="totalISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
		<xsl:variable name="totalImpuestos" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '2000']]/cbc:TaxAmount)"/>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4305'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalISCxLinea or ($totalISC - 1) &gt; $totalISCxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4301'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="(round(($totalImpuestos + 1 ) * 100) div 100) &lt; (round($SumatoriaImpuestos * 100) div 100) or (round(($totalImpuestos - 1) * 100) div 100) &gt; (round($SumatoriaImpuestos * 100) div 100)" />
			<xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		 <!-- Tributos de la cabecera-->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
		                
    </xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:TaxTotal ===========================================

    ===========================================================================================================================================
    -->
	
	
	<!--
    ===========================================================================================================================================
    =========================================== Template cabecera cac:TaxTotal/cac:TaxSubtotal ===========================================
    ===========================================================================================================================================
    -->

    <xsl:template match="cac:TaxSubtotal" mode="cabecera">
	     <xsl:param name="root"/>

        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
		<xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
		<xsl:variable name="SumatoriaIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
		<xsl:variable name="MontoBaseIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
		<xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
		<xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)"/>
		<xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
		<xsl:variable name="SumatoriaIGVCalculado" select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18"/>
        
		
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
				<xsl:when test="$codigoTributo = '7152'">
                    <xsl:value-of select="'oth'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
    </xsl:call-template>
		
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
		
		<xsl:if test="$codigoTributo != '1000' and $codigoTributo != '9997' and $codigoTributo != '2000'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3007'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="true()" />
			</xsl:call-template>
        </xsl:if>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
	  
	  <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI" />
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'" />
			<xsl:with-param name="isError" select="false()" />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)" />
	 </xsl:call-template>
	
	<xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
        <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
    </xsl:call-template>
	
	 <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
     </xsl:call-template>
	
   <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2036'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(1000|9997|2000)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
   
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

    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	</xsl:call-template>

  </xsl:template>
  
  
  <!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge cabecera ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="cabecera">
    	<xsl:param name="root"/>
		<xsl:param name="nroLinea"/>

		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
        <xsl:variable name="monedaComprobante" select="$root/cbc:DocumentCurrencyCode"/>
        <xsl:variable name="importeComprobante" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount"/>
        
        <xsl:if test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '52'">
        	<xsl:if test="cbc:ChargeIndicator and cbc:ChargeIndicator !='true'">
	        	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3114'" />
		            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	        </xsl:if>
        </xsl:if>
        
        <xsl:if test="$codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'">
        	<xsl:if test="cbc:ChargeIndicator and cbc:ChargeIndicator !='false'">
	        	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'3114'" />
		            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode" />
		            <xsl:with-param name="expresion" select="true()" />
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
	        </xsl:if>
        </xsl:if>
		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3073'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
		
		 <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4268'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="regexp" select="'^(02|03|45|49|50|52)$'"/>
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
		
		<xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2955'"/>
            <xsl:with-param name="errorCodeValidate" select="'2955'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:if test="cbc:MultiplierFactorNumeric &gt; 0">
        	<xsl:variable name="Monto" select="cbc:Amount"/>
        	
        	<xsl:variable name="MontoBase">
	            <xsl:choose>
				   <xsl:when test="cbc:BaseAmount &gt; 0">
	                 <xsl:value-of select="cbc:BaseAmount" />
	               </xsl:when>
	               <xsl:otherwise>
	                 <xsl:text>0</xsl:text>
	               </xsl:otherwise>
	             </xsl:choose> 
	        </xsl:variable>
        	
        	<xsl:variable name="MontoCalculado" select=" $MontoBase * cbc:MultiplierFactorNumeric"/>
        	
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4289'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="($Monto + 1 ) &lt; $MontoCalculado or ($Monto - 1) &gt; $MontoCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3053'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        

    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge ===========================================

    ===========================================================================================================================================
    -->
	
	 <!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge sublinea===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="sublinea">
    	<xsl:param name="root"/>

		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
        <xsl:variable name="monedaComprobante" select="$root/cbc:DocumentCurrencyCode"/>
        <xsl:variable name="importeComprobante" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount"/>
		
		<xsl:if test="$codigoCargoDescuento = '47' or $codigoCargoDescuento = '54'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2585'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoCargoDescuento = '00' or  $codigoCargoDescuento = '07'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'2585'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>
		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2586'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
		
		 <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4357'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="regexp" select="'^(00|47|07|54)$'"/>
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
		
		<!-- -->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2587'"/>
			<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:variable name="MontoCalculado" select="number(concat('0',cbc:BaseAmount)) * number(concat('0',cbc:MultiplierFactorNumeric))"/>
        <xsl:variable name="Monto" select="cbc:Amount"/>

        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4358'" />
            <xsl:with-param name="node" select="cbc:Amount" />
            <xsl:with-param name="expresion" select="cbc:MultiplierFactorNumeric &gt; 0 and (($Monto + 1 ) &lt; $MontoCalculado or ($Monto - 1) &gt; $MontoCalculado)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
            <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2588'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2589'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>

        

    </xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge sublinea===========================================

    ===========================================================================================================================================
    -->
	
	
	 <!--
    ===========================================================================================================================================

    =========================================== Template cac:AllowanceCharge sublinea===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cac:ItemPriceExtension" mode="sublinea">
    	<xsl:param name="root"/>
		 
		 <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2483'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
 
 
	</xsl:template>
    <!--
    ===========================================================================================================================================

    =========================================== fin Template cac:Allowancecharge sublinea===========================================

    ===========================================================================================================================================
    -->

	<!--
    ===========================================================================================================================================

    =========================================== Template cbc:Note ===========================================

    ===========================================================================================================================================
    -->
    <xsl:template match="cbc:Note" mode="linea">
		<xsl:param name="nroLinea"/>
		
		<xsl:if test="@languageLocaleID">
            <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'"/>
				<xsl:with-param name="idCatalogo" select="@languageLocaleID"/>
				<xsl:with-param name="catalogo" select="'52'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Leyenda: ', @languageLocaleID)"/>
			</xsl:call-template>
        </xsl:if>
                
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4362'" />
            <xsl:with-param name="node" select="@languageLocaleID" />
            <xsl:with-param name="expresion" select="count(key('by-note-in-invoiceline', concat($nroLinea, '-', @languageLocaleID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Leyenda: ', @languageLocaleID)"/>
            <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, 'Leyenda : ', @languageLocaleID)"/> 
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3006'"/>
            <xsl:with-param name="node" select="text()"/>
            <xsl:with-param name="expresion" select="string-length(text()) &gt; 500 or string-length(text()) &lt; 0 "/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, 'Leyenda : ', @languageLocaleID)"/>
        </xsl:call-template>

	</xsl:template>

    <!--
    ===========================================================================================================================================

    =========================================== fin Template cbc:Note ======================================================

    ===========================================================================================================================================
    -->
	
	
</xsl:stylesheet>