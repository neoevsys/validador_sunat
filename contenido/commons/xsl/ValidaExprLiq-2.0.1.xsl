<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:regexp="http://exslt.org/regular-expressions" xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:dp="http://www.datapower.com/extensions" xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
	<!-- <xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" /> -->
	<xsl:include href="sunat_archivos/sfs/VALI/commons/error/validate_utils.xsl" dp:ignore-multiple="yes"/>
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
	<!-- SFS -->
	<xsl:param name="nombreArchivoEnviado"/>
	<xsl:template match="/*">
		
	</xsl:template>
	<!-- =========================================================================================================================================== =========================================== fin Template cac:PaymentMeans =========================================== =========================================================================================================================================== -->
</xsl:stylesheet>
