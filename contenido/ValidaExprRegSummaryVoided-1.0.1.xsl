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
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='VoidedDocuments']/sac:VoidedDocumentsLine" use="cbc:LineID"/>
    
    
    <!-- key comprobantes duplicados por linea -->
    <xsl:key name="by-Billing-in-line" match="sac:VoidedDocumentsLine/sac:BillingPayment" use="concat(cbc:LineID,cbc:DocumentTypeCode,sac:DocumentSerialID, number(sac:DocumentNumberID))"/>
        
    
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
        
        <!-- /VoidedDocuments/cbc:UBLVersionID No existe el Tag UBL
        ERROR 2075 -->
        
        <!-- /VoidedDocuments/cbc:UBLVersionID El valor del Tag UBL es diferente a "2.0"
        ERROR 2074 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
        </xsl:call-template>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>

        <!-- /VoidedDocuments/cbc:CustomizationID El valor del Tag UBL es diferente a "1.0"
        ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2072'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(1.0)$'"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cbc:ID El ID del nombre del archivo es diferente al Tag UBL
        ERROR 2220 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2220'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$idFilename != cbc:ID" />
        </xsl:call-template>

        <!-- /VoidedDocuments/cbc:IssueDate No existe el Tag UBL
        ERROR 2299 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2299'"/>
            <xsl:with-param name="node" select="cbc:IssueDate"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cbc:IssueDate La fecha del nombre del archivo es diferente al tag UBL
        ERROR 2346 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2346'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$fechaEnvioFile != translate(cbc:IssueDate,'-','')" />
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cbc:IssueDate El valor del Tag UBL es mayor a la fecha de envío
        ERROR 2301 -->
        <xsl:call-template name="isDateAfterToday">
            <xsl:with-param name="errorCodeValidate" select="'2301'"/>
            <xsl:with-param name="startDateNode" select="cbc:IssueDate"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cbc:ReferenceDate No existe el Tag UBL
        ERROR 2303 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2303'"/>
            <xsl:with-param name="node" select="cbc:ReferenceDate"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cbc:ReferenceDate El valor del Tag UBL es mayor a "Fecha de generación de la comunicación"
        ERROR 4036 -->
        <xsl:call-template name="isDateBefore">
            <xsl:with-param name="errorCodeValidate" select="'2671'"/>
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
        
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID El RUC del nombre del archivo es diferente al Tag UBL
        ERROR 2221 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2221'" />
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
        
        Datos del detalle o Ítem del Resumen
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="sac:VoidedDocumentsLine">
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
    
    
    
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID No existe el Tag UBL
        ERROR 2217 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2217'"/>
            <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID No existe el Tag UBL
        ERROR 2288 -->
        
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID El valor del Tag UBL es diferente de "6" (RUC)
        ERROR 2287 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2288'"/>
            <xsl:with-param name="errorCodeValidate" select="'2287'"/>
            <xsl:with-param name="node" select="cbc:AdditionalAccountID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/> <!-- de tres a 1000 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 2229 -->
        
        <!-- /VoidedDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres
        ERROR 2228 -->
        <!--xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2229'"/>
            <xsl:with-param name="errorCodeValidate" select="'2228'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,100}$'"/--> <!-- de tres a 1000 caracteres que no inicie por espacio -->
        <!--/xsl:call-template-->
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2229'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2228'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$).{0,}$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2228'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="expresion" select="string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 100 or string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 3 "/>
        </xsl:call-template>
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingSupplierParty ======================================================
    
    ===========================================================================================================================================
    -->
    
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template sac:VoidedDocumentsLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="sac:VoidedDocumentsLine">
    
        <xsl:param name="root"/>
        
        <xsl:variable name="nroLinea" select="cbc:LineID"/>
        
        
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:LineID No existe el Tag UBL o es vacío
        ERROR 2307 -->
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:LineID El formato del Tag UBL es numérico hasta 5 dígitos
        ERROR 2305 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2307'"/>
            <xsl:with-param name="errorCodeValidate" select="'2305'"/>
            <xsl:with-param name="node" select="cbc:LineID"/>
            <xsl:with-param name="regexp" select="'^(?!0+(\d+)$)\d{1,5}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:LineID El valor del Tag UBL es menor a 1
        ERROR 2306 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2306'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="cbc:LineID &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:LineID El valor del Tag UBL no debe repetirse en el /VoidedDocuments
        ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:LineID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:DocumentTypeCode No existe el Tag UBL o es vacío
        ERROR 2309 -->
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/cbc:DocumentTypeCode El valor del Tag UBL es diferente a "01", "07", "08"
        ERROR 2308 
        Se quita boleta para las bajas a partir del 01/01/2018
        -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2309'"/>
            <xsl:with-param name="errorCodeValidate" select="'2308'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^01|07|08|14|30|34|42$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentSerialID No existe el Tag UBL o es vacío
        ERROR 2311 -->
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentSerialID "El formato del Tag UBL es diferente a [BF][A-Z0-9]{3}"
        ERROR 2310 
        Se quita boleta para las bajas a partir del 01/01/2018
        -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2311'"/>
            <xsl:with-param name="errorCodeValidate" select="'2310'"/>
            <xsl:with-param name="node" select="sac:DocumentSerialID"/>
            <xsl:with-param name="regexp" select="'(^[FS][A-Z0-9]{3}$)|(^[\d]{1,4}$)'"/>
<!--             <xsl:with-param name="regexp" select="'^[FS][A-Z0-9]{3}$'"/> -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <xsl:choose>
        
            <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentSerialID Si "Tipo de documento" es 01, el valor del Tag UBL empieza con un valor diferente a "F"
            ERROR 2345 -->
            <xsl:when test="cbc:DocumentTypeCode='01'">
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2311'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2345'"/>
                    <xsl:with-param name="node" select="sac:DocumentSerialID"/>
                    <xsl:with-param name="regexp" select="'(^[F][A-Z0-9]{3}$)|(^[\d]{1,4}$)'"/>
<!--                     <xsl:with-param name="regexp" select="'^[F][A-Z0-9]{3}$'"/> -->
                    <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentSerialID Si "Tipo de documento" es 03, el valor del Tag UBL empieza con un valor diferente a "B"
            ERROR 2345 
            Se quita boleta para las bajas a partir del 01/01/2018
            -->
                    
            <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentSerialID Si "Tipo de documento" es 14, el valor del Tag UBL empieza con un valor diferente a "S"
            ERROR 2345 -->
            <xsl:when test="cbc:DocumentTypeCode='14'">
                <xsl:call-template name="existAndRegexpValidateElement">
                    <xsl:with-param name="errorCodeNotExist" select="'2311'"/>
                    <xsl:with-param name="errorCodeValidate" select="'2345'"/>
                    <xsl:with-param name="node" select="sac:DocumentSerialID"/>
                    <xsl:with-param name="regexp" select="'(^[S][A-Z0-9]{3}$)|(^[\d]{1,4}$)'"/>
<!--                     <xsl:with-param name="regexp" select="'^[S][A-Z0-9]{3}$'"/> -->
                    <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentNumberID No existe el Tag UBL o es vacío
        ERROR 2313 -->
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentNumberID El formato del Tag UBL es numérico de hasta 8 dígitos
        ERROR 2312 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2313'"/>
            <xsl:with-param name="errorCodeValidate" select="'2312'"/>
            <xsl:with-param name="node" select="sac:DocumentNumberID"/>
            <xsl:with-param name="regexp" select="'^\d{1,8}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:DocumentNumberID El "Tipo de documento" concatenado con "Serie del documento dado de baja" concatenado con el Tag UBL no debe repertirse en el /VoidedDocuments
        ERROR 2348 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="count(key('by-Billing-in-line', concat(cbc:LineID,cbc:DocumentTypeCode,sac:DocumentSerialID, number(sac:DocumentNumberID)))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:VoidReasonDescription No existe el Tag UBL o es vacío
        ERROR 2315 -->
        
        <!-- /VoidedDocuments/sac:VoidedDocumentsLine/sac:VoidReasonDescription La longitud del Tag UBL es menor a 3
        ERROR 2314 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2315'"/>
            <xsl:with-param name="node" select="sac:VoidReasonDescription"/>
        </xsl:call-template>
        
        <xsl:if test="string-length(sac:VoidReasonDescription) &lt; 3">
        	<xsl:call-template name="isTrueExpresion">
	            <!-- Excel versión 5 -->
              <!--xsl:with-param name="errorCodeValidate" select="'2314'" /-->
              <xsl:with-param name="errorCodeValidate" select="'4203'" />
	            <xsl:with-param name="node" select="sac:VoidReasonDescription"/>
	            <xsl:with-param name="expresion" select="true()" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2315'"/>
            <xsl:with-param name="errorCodeValidate" select="'2314'"/>
            <xsl:with-param name="node" select="sac:VoidReasonDescription"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
            <!-- Ini PAS20171U210300071 -->
			<xsl:with-param name="isError" select ="false()"/>
			<!-- Fin PAS20171U210300071 -->
        </xsl:call-template>
  
    </xsl:template>
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template sac:VoidedDocumentsLine =========================================== 
    
    ===========================================================================================================================================
    -->
    

</xsl:stylesheet>
