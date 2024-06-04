<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" 
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#" 
    xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" 
    xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
    xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" 
    xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" 
    xmlns:dp="http://www.datapower.com/extensions" 
    extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">

    <!-- xsl:include href="../../../commons/error/validate_utils.xsl" dp:ignore-multiple="yes" / -->
    <xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
    
    
    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='SummaryDocuments']/sac:SummaryDocumentsLine" use="cbc:LineID"/>
    
    <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:LineID)"/>
    
    <!-- key BillingPayment duplicados por linea -->
    <xsl:key name="by-BillingPayment-in-line" match="sac:SummaryDocumentsLine/sac:BillingPayment" use="concat(cbc:InstructionID,'-', ../cbc:LineID)"/>
    
    <!-- key ChargeIndicator duplicados por linea -->
    <xsl:key name="by-ChargeIndicator-in-line" match="sac:SummaryDocumentsLine/cac:AllowanceCharge" use="concat(cbc:ChargeIndicator,'-', ../cbc:LineID)"/>
    
    <xsl:template match="/*">
    
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
        <!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->
        
        <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="idFilename" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 16)"/>
        
        <xsl:variable name="fechaEnvioFile" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 8)"/>
        
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del Resumen  
        
        ===========================================================================================================================================
        -->
        
        <!-- /SummaryDocuments/cbc:UBLVersionID No existe el Tag UBL
        ERROR 2075 -->
        
        <!-- /SummaryDocuments/cbc:UBLVersionID El valor del Tag UBL es diferente de "2.0"
        ERROR 2074 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:CustomizationID El valor del Tag UBL es diferente de "1.0"
        ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2072'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(1.0)$'"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ID El valor del Tag UBL es diferente al nombre del archivo
        ERROR 2220 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2220'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$idFilename != cbc:ID" />
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:IssueDate No existe el Tag UBL
        ERROR 2231 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2231'"/>
            <xsl:with-param name="node" select="cbc:IssueDate"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:IssueDate La fecha del nombre del archivo es diferente al tag UBL
        ERROR 2346 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2346'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$fechaEnvioFile != translate(cbc:IssueDate,'-','')" />
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ReferenceDate No existe el Tag UBL
        ERROR 2234 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2234'"/>
            <xsl:with-param name="node" select="cbc:ReferenceDate"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ReferenceDate El valor del Tag UBL es mayor a la "Fecha de generación del resumen"
        ERROR 4036 -->
        <xsl:call-template name="isDateBefore">
            <xsl:with-param name="errorCodeValidate" select="'4036'"/>
            <xsl:with-param name="startDateNode" select="cbc:IssueDate"/>
            <xsl:with-param name="endDateNode" select="cbc:ReferenceDate"/>
        </xsl:call-template>
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Datos del Resumen
        
        ===========================================================================================================================================
        -->
        
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del Emisor
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="cac:AccountingSupplierParty"/>
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID El valor del Tagl UBL es diferente al RUC del nombre del archivo
        ERROR 1034 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID" />
        </xsl:call-template>
        
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
        
        <xsl:apply-templates select="cac:AccountingCustomerParty">
            <xsl:with-param name="root" select="."/>
            <xsl:with-param name="tipoComprobante" select="$tipoComprobante"/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        fin Datos del cliente o receptor
        
        ===========================================================================================================================================
        -->
        
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem del Resumen
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="sac:SummaryDocumentsLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem del Resumen
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Totales del Resumen
        
        ===========================================================================================================================================
        -->

        <!-- /DebitNote/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation El Tag UBL no debe repetirse en el /DebitNote
        ERROR 2427 -->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2427'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation" />
            <xsl:with-param name="expresion" select="count(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation) &gt; 1" />
        </xsl:call-template>

        <!-- sac:AdditionalMonetaryTotal -->
        <xsl:apply-templates select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal"/>
        
        <!-- Tributos duplicados por cabecera -->
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera"/>
        
        <!-- Tributos de la cabecera-->
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Totales del Resumen
        
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
    
    ============================================ Template cac:AccountingSupplierParty =========================================================
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AccountingSupplierParty">
    
    
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID No existe el Tag UBL o es vacío
        ERROR 2217 Ya se valida 1034 -->
        <!-- 
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'1034'"/>
            <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
        </xsl:call-template> -->
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID No existe el Tag UBL o es vacío
        ERROR 2219 -->
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID El valor del Tag UBL es diferente a 6 (RUC)
        ERROR 2218 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2219'"/>
            <xsl:with-param name="errorCodeValidate" select="'2218'"/>
            <xsl:with-param name="node" select="cbc:AdditionalAccountID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/> <!-- de tres a 1000 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 2229 -->
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres
        ERROR 2228 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2229'"/>
            <xsl:with-param name="errorCodeValidate" select="'2228'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,100}$'"/> <!-- de tres a 1000 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingSupplierParty ======================================================
    
    ===========================================================================================================================================
    -->
    
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template sac:SummaryDocumentsLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="sac:SummaryDocumentsLine">
    
        <xsl:param name="root"/>
        
        <xsl:variable name="nroLinea" select="cbc:LineID"/>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID El formato del Tag UBL es numérico hasta 5 dígitos
        ERROR 2238 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2238'"/>
            <xsl:with-param name="errorCodeValidate" select="'2238'"/>
            <xsl:with-param name="node" select="cbc:LineID"/>
            <xsl:with-param name="regexp" select="'^(?!0+(\d+)$)\d{1,5}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID El valor del Tag UBL es menor a 1 (uno)
        ERROR 2239 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2239'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="cbc:LineID &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID El valor del Tag UBL no puede repetirse en /SummaryDocuments
        ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:LineID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:DocumentTypeCode No existe el Tag UBL o es vacío
        ERROR 2242 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:DocumentTypeCode El valor del Tag UBL es diferente a 03, 07 o 08
        ERROR 2241 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2242'"/>
            <xsl:with-param name="errorCodeValidate" select="'2241'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^03|07|08$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:DocumentSerialID No existe el Tag UBL o es vacío
        ERROR 2244 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:DocumentSerialID "El formato del Tag UBL es diferente a:[B][A-Z0-9]{3}"
        ERROR 2243 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2244'"/>
            <xsl:with-param name="errorCodeValidate" select="'2243'"/>
            <xsl:with-param name="node" select="sac:DocumentSerialID"/>
            <xsl:with-param name="regexp" select="'^[B][A-Z0-9]{3}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            <!-- Ini PAS20171U210300071 -->
			<xsl:with-param name="isError" select ="false()"/>
			<!-- Fin PAS20171U210300071 -->
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:StartDocumentNumberID No existe el Tag UBL o es vacío
        ERROR 2246 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:StartDocumentNumberID El formato del Tag UBL es diferente a numérico de hasta 8 dígitos
        ERROR 2245 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2246'"/>
            <xsl:with-param name="errorCodeValidate" select="'2245'"/>
            <xsl:with-param name="node" select="sac:StartDocumentNumberID"/>
            <xsl:with-param name="regexp" select="'^\d{1,8}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:StartDocumentNumberID El valor del Tag UBL es menor a 1 (uno)
        ERROR 2249 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2249'" />
            <xsl:with-param name="node" select="sac:StartDocumentNumberID" />
            <xsl:with-param name="expresion" select="sac:StartDocumentNumberID &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:EndDocumentNumberID No existe el Tag UBL o es vacío
        ERROR 2248 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:EndDocumentNumberID El formato del Tag UBL es diferente a numérico de hasta 8 dígitos
        ERROR 2247 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2248'"/>
            <xsl:with-param name="errorCodeValidate" select="'2247'"/>
            <xsl:with-param name="node" select="sac:EndDocumentNumberID"/>
            <xsl:with-param name="regexp" select="'^\d{1,8}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:EndDocumentNumberID El valor del Tag UBL debe ser mayor o igual a "Número de comprobante de inicio de rango"
        ERROR 2900 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2900'" />
            <xsl:with-param name="node" select="sac:EndDocumentNumberID" />
            <xsl:with-param name="expresion" select="sac:StartDocumentNumberID &gt; sac:EndDocumentNumberID" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount No existe el Tag UBL
        ERROR 2252 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR 2251 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2252'"/>
            <xsl:with-param name="errorCodeValidate" select="'2251'"/>
            <xsl:with-param name="node" select="sac:TotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount El valor del Tag UBL es menor a 0
        ERROR 2253 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2253'" />
            <xsl:with-param name="node" select="sac:TotalAmount" />
            <xsl:with-param name="expresion" select="sac:TotalAmount &lt;= 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            <!-- Ini PAS20171U210300071 -->
			<xsl:with-param name="isError" select ="false()"/>
			<!-- Fin PAS20171U210300071 -->
        </xsl:call-template>        
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount@currencyID Si algún Tag UBL es diferente en /SummaryDocuments/sac:SummaryDocumentsLine/
        ERROR 2071 -->
        <xsl:variable name="monedaComprobante" select="sac:TotalAmount/@currencyID"/>
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante]" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <xsl:for-each select="sac:BillingPayment">
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount No existe el Tag UBL
            ERROR 2255 -->
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
            ERROR 2254 -->
            <xsl:call-template name="existAndValidateValueTwoDecimal">
                <xsl:with-param name="errorCodeNotExist" select="'2255'"/>
                <xsl:with-param name="errorCodeValidate" select="'2254'"/>
                <xsl:with-param name="node" select="cbc:PaidAmount"/>
                <xsl:with-param name="isGreaterCero" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount El valor del Tag UBL es menor de cero (0)
            ERROR 2260 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2260'" />
                <xsl:with-param name="node" select="cbc:PaidAmount" />
                <xsl:with-param name="expresion" select="cbc:PaidAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                <!-- Ini PAS20171U210300071 -->
				<xsl:with-param name="isError" select ="false()"/>
				<!-- Fin PAS20171U210300071 -->
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID No existe el Tag UBL
            ERROR 2257 -->
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2257'"/>
                <xsl:with-param name="node" select="cbc:InstructionID"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID El Tag UBL no existe en el listado
            ERROR 2256 -->
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'11'"/>
                <xsl:with-param name="idCatalogo" select="cbc:InstructionID"/>
                <xsl:with-param name="errorCodeValidate" select="'2256'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
            ERROR 2357 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2357'" />
                <xsl:with-param name="node" select="cbc:InstructionID" />
                <xsl:with-param name="expresion" select="count(key('by-BillingPayment-in-line', concat(cbc:InstructionID,'-', $nroLinea))) > 1" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
        </xsl:for-each>
        
        
        
        
        <xsl:for-each select="cac:AllowanceCharge">
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:ChargeIndicator No existe el Tag UBL
            ERROR 2264 -->
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:ChargeIndicator El valor del Tag UBL es diferente de "true"
            ERROR 2263 -->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2264'"/>
                <xsl:with-param name="errorCodeValidate" select="'2263'"/>
                <xsl:with-param name="node" select="cbc:ChargeIndicator"/>
                <xsl:with-param name="regexp" select="'^true$'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:ChargeIndicator El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
            ERROR 2411 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2411'" />
                <xsl:with-param name="node" select="cbc:ChargeIndicator" />
                <xsl:with-param name="expresion" select="count(key('by-ChargeIndicator-in-line', concat(cbc:ChargeIndicator,'-', $nroLinea))) > 1" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:Amount No existe el Tag UBL
            ERROR 2262 -->
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:Amount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
            ERROR 2261 -->
            <xsl:call-template name="existAndValidateValueTwoDecimal">
                <xsl:with-param name="errorCodeNotExist" select="'2262'"/>
                <xsl:with-param name="errorCodeValidate" select="'2261'"/>
                <xsl:with-param name="node" select="cbc:Amount"/>
                <xsl:with-param name="isGreaterCero" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:Amount El valor del Tag UBL es menor de cero (0)
            ERROR 2266 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2266'" />
                <xsl:with-param name="node" select="cbc:Amount" />
                <xsl:with-param name="expresion" select="cbc:Amount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                <!-- Ini PAS20171U210300071 -->
				<xsl:with-param name="isError" select ="false()"/>
				<!-- Fin PAS20171U210300071 -->
            </xsl:call-template>
        
        </xsl:for-each>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name Debe existir un Tag UBL con valor "IGV" y otro con valor "ISC" en cada /SummaryDocuments/sac:SummaryDocumentsLine
        ERROR 2278 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2278'" />
	    <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name" />
	    <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name[text()='IGV']) != 1 or count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name[text()='ISC']) != 1 " />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>

        <!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
        
        <!-- Tributos duplicados por linea -->
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
          
    </xsl:template>
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template sac:SummaryDocumentsLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:TaxTotal/cac:TaxSubtotal" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
        ERROR 2355 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2355'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
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
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        
        <xsl:variable name="tipoOperacion" select="$root/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID"/>
        
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cbc:TaxAmount No existe el Tag UBL
        ERROR 2274 -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cbc:TaxAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 2343 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2274'"/>
            <xsl:with-param name="errorCodeValidate" select="'2343'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
            
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount No existe el Tag UBL o es diferente al tag anterior
        ERROR 2344 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2344'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number(cac:TaxSubtotal/cbc:TaxAmount) != number(cbc:TaxAmount)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID No existe el Tag UBL
        ERROR 2269 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2269'"/>
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL es diferente al Catálogo 5
        ERROR 2268 -->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2268'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL
        ERROR 2271 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2271'"/>
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <xsl:choose>
            <xsl:when test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000'">
        
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name Si "Código de tributo" es 1000, el valor del Tag UBL es diferente a "IGV"
                ERROR 2276 -->
                <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'2276'" />
                    <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                    <xsl:with-param name="expresion" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '1000']/cbc:Name != 'IGV'" />
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. cbc:Name debe de ser IGV')"/>
                </xsl:call-template>
        
            </xsl:when>
        
            <xsl:when test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'">
            
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name Si "Código de tributo" es 2000, el valor del Tag UBL es diferente a "ISC"
                ERROR 2275 -->
                <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'2275'" />
                    <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                    <xsl:with-param name="expresion" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '2000']/cbc:Name != 'ISC'" />
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                </xsl:call-template>
            </xsl:when>
           
        </xsl:choose>
       
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    

</xsl:stylesheet>
