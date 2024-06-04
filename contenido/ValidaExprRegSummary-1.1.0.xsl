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
    
    <!-- key comprobantes duplicados por linea -->
    <xsl:key name="by-bills-in-line" match="sac:SummaryDocumentsLine" use="concat(cbc:DocumentTypeCode, '-', substring(cbc:ID,1,4), '-', number(substring(cbc:ID,6)), '-', cac:Status/cbc:ConditionCode )"/>
    
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
        
        <!-- /SummaryDocuments/cbc:UBLVersionID  No existe el Tag UBL o es vacío
        ERROR  2075-->
        <!-- /SummaryDocuments/cbc:UBLVersionID  El valor del Tag UBL es diferente de "2.0"
        ERROR  2074-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:CustomizationID  El valor del Tag UBL es diferente de "1.1"
        ERROR  2072-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2072'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(1.1)$'"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ID  El valor del Tag UBL es diferente al nombre del archivo
        ERROR  2220-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2220'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$idFilename != cbc:ID" />
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ReferenceDate  El valor del Tag UBL es mayor a la "Fecha de generación del resumen"
        ERROR  4036-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2346'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$fechaEnvioFile != translate(cbc:IssueDate,'-','')" />
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:ReferenceDate El valor del Tag UBL es mayor a la "Fecha de generación del resumen"
        ERROR 4036 -->
        <!-- PAS20191U210100273 Cambio de codigo de error de ERR-4036 a ERR-2671 -->
		<xsl:call-template name="isDateBefore">
            <xsl:with-param name="errorCodeValidate" select="'2671'"/>
            <xsl:with-param name="startDateNode" select="cbc:IssueDate"/>
            <xsl:with-param name="endDateNode" select="cbc:ReferenceDate"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cbc:IssueDate  El valor del Tag UBL es mayor que el día de hoy
        ERROR  2236
        -->
        <xsl:call-template name="isDateAfterToday">
            <xsl:with-param name="errorCodeValidate" select="'2236'"/>
            <xsl:with-param name="startDateNode" select="cbc:IssueDate"/>
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
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID  El valor del Tagl UBL es diferente al RUC del nombre del archivo
        ERROR  1034-->
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
        
        Datos del detalle o Ítem del Resumen
        
        ===========================================================================================================================================
        -->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'0158'" />
            <xsl:with-param name="node" select="sac:SummaryDocumentsLine[last()]/cbc:LineID" />
            <xsl:with-param name="expresion" select="count(sac:SummaryDocumentsLine) &gt; 500" />
            <xsl:with-param name="descripcion" select="concat('No se deben de enviar mas de 500 comprobantes para el resumen: ', cbc:ID)"/>
        </xsl:call-template>

        <xsl:apply-templates select="sac:SummaryDocumentsLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem del Resumen
        
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

        <!--/SummaryDocuments/cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID  No existe el Tag UBL o es vacío
        ERROR  2217-->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2217'"/>
            <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID  No existe el Tag UBL o es vacío
        ERROR  2219-->
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cbc:AdditionalAccountID  El valor del Tag UBL es diferente a 6 (RUC)
        ERROR  2218-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2219'"/>
            <xsl:with-param name="errorCodeValidate" select="'2218'"/>
            <xsl:with-param name="node" select="cbc:AdditionalAccountID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/> <!-- de tres a 1000 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName  No existe el Tag UBL o es vacío
        ERROR  2229-->
        <!-- /SummaryDocuments/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName  El formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres  (se considera cualquier carácter incluido espacio, no permite "whitespace character": salto de línea, fin de línea, tab, etc.)
        ERROR  2228-->
        
        <!-- 
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2229'"/>
            <xsl:with-param name="errorCodeValidate" select="'2228'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,100}$'"/> 
        </xsl:call-template>
        -->
        
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
    
    =========================================== fin Template sac:SummaryDocumentsLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="sac:SummaryDocumentsLine">
    
        <xsl:param name="root"/>
        
        <xsl:variable name="nroLinea" select="cbc:LineID"/>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID  El valor del Tag UBL es menor a 1 (uno)
        ERROR  2239-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2239'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="cbc:LineID &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID   El formato del Tag UBL es numérico hasta 5 dígitos
        ERROR  2238-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2238'"/>
            <xsl:with-param name="errorCodeValidate" select="'2238'"/>
            <xsl:with-param name="node" select="cbc:LineID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,5}$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
               
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:LineID  El valor del Tag UBL no puede repetirse en /SummaryDocuments
        ERROR  2752-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:LineID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:LineID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:Status/cbc:ConditionCode  No existe el Tag UBL
        ERROR  2522-->
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2522'"/>
            <xsl:with-param name="node" select="cac:Status/cbc:ConditionCode"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:Status/cbc:ConditionCode  El valor del Tag UBL es diferente al listado
        ERROR  2896-->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'19'"/>
            <xsl:with-param name="idCatalogo" select="cac:Status/cbc:ConditionCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2896'"/>
        </xsl:call-template>
        
        
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:ID El "Tipo de Comprobante", "Serie y número de correlativo del documento" y "codigo de operación del ítem" no debe repetirse en /SummaryDocuments
        ERROR  3094 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3094'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-bills-in-line', concat(cbc:DocumentTypeCode, '-', substring(cbc:ID,1,4), '-', number(substring(cbc:ID,6)), '-', cac:Status/cbc:ConditionCode ))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:ID El comprobante no debe ser emitido y editado en el mismo envio
        ERROR  3095 -->
        
        <xsl:if test="cac:Status/cbc:ConditionCode ='1'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3095'" />
                <xsl:with-param name="node" select="cbc:ID" />
                <xsl:with-param name="expresion" select="count(key('by-bills-in-line', concat(cbc:DocumentTypeCode, '-', substring(cbc:ID,1,4), '-', number(substring(cbc:ID,6)), '-', '2' ))) > 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
        </xsl:if>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:ID El comprobante no debe ser editado y anulado en el mismo envio
        ERROR  3096-->
        
        <xsl:if test="cac:Status/cbc:ConditionCode ='2'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3096'" />
                <xsl:with-param name="node" select="cbc:ID" />
                <xsl:with-param name="expresion" select="count(key('by-bills-in-line', concat(cbc:DocumentTypeCode, '-', substring(cbc:ID,1,4), '-', number(substring(cbc:ID,6)), '-', '3' ))) > 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
        </xsl:if>

        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:DocumentTypeCode  El Tag UBL es vacío
        ERROR  2242-->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:DocumentTypeCode  El valor del Tag UBL es diferente a 03, 07, 08
        ERROR  2241-->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2242'"/>
            <xsl:with-param name="errorCodeValidate" select="'2241'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^03|07|08$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:ID  No existe el Tag UBL
        ERROR  2512-->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cbc:ID  "Si ""Tipo de documento"" es 03, 07 o 08, el formato del Tag UBL es diferente: ^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$"
        ERROR  2513-->

        <!-- PAS20201U210400026 Se permite la baja de numero de documento 0 (Ej. baja de BA20-0)-->
        
        <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2512'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <xsl:choose>
           <xsl:when test="cac:Status/cbc:ConditionCode ='3'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'2513'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3}|[\d]{1,4})-([0-9]{1,8})$'"/>
                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
              </xsl:call-template>
           </xsl:when>
           <xsl:otherwise>   
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'2513'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3}|[\d]{1,4})-(?!0+$)([0-9]{1,8})$'"/>
                 <!--xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$'"/> -->
                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
              </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount  No existe el Tag UBL
        ERROR  2252-->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount  El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR  2251-->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2252'"/>
            <xsl:with-param name="errorCodeValidate" select="'2251'"/>
            <xsl:with-param name="node" select="sac:TotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
          <!-- Total valor de venta-operaciones gravadas -->
        <xsl:variable name="totVentaOperGravadas">
            <xsl:choose>
                <xsl:when test="sac:BillingPayment[cbc:InstructionID='01']/cbc:PaidAmount">
                    <xsl:value-of select="sac:BillingPayment[cbc:InstructionID='01']/cbc:PaidAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Total valor de venta-operaciones exoneradas -->
        <xsl:variable name="totVentaOperExoneradas">
            <xsl:choose>
                <xsl:when test="sac:BillingPayment[cbc:InstructionID='02']/cbc:PaidAmount">
                    <xsl:value-of select="sac:BillingPayment[cbc:InstructionID='02']/cbc:PaidAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Total valor de venta - operaciones no gravadas -->
        <!-- Total valor de venta - operaciones inafectas -->
        <xsl:variable name="totVentaOperInafectas">
            <xsl:choose>
                <xsl:when test="sac:BillingPayment[cbc:InstructionID='03']/cbc:PaidAmount">
                    <xsl:value-of select="sac:BillingPayment[cbc:InstructionID='03']/cbc:PaidAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- PAS20191U210100194  Total Operaciones Exportacion -->
         <xsl:variable name="totVentaOperExportacion">
            <xsl:choose>
                <xsl:when test="sac:BillingPayment[cbc:InstructionID='04']/cbc:PaidAmount">
                    <xsl:value-of select="sac:BillingPayment[cbc:InstructionID='04']/cbc:PaidAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- PAS20191U210100194 -->
        
        <!-- Total valor de venta - operaciones gratuitas -->
        <xsl:variable name="totVentaOperGratuitas">
            <xsl:choose>
                <xsl:when test="sac:BillingPayment[cbc:InstructionID='05']/cbc:PaidAmount">
                    <xsl:value-of select="sac:BillingPayment[cbc:InstructionID='05']/cbc:PaidAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Importe total de sumatoria otros cargos del item -->
        <xsl:variable name="totOtrosCargos">
            <xsl:choose>
                <xsl:when test="cac:AllowanceCharge/cbc:Amount">
                    <xsl:value-of select="cac:AllowanceCharge/cbc:Amount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Total IGV -->
        <xsl:variable name="totIGV">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
         
         
         <!-- Total IGV -->
        <xsl:variable name="totIVAP">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Total ISC --> 
        <xsl:variable name="totISC">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Total otros tributos --> 
        <xsl:variable name="totOtrosTributos">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
		<!-- Total ICBPER --> 
        <xsl:variable name="totICBPER">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='7152']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='7152']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Importe total de la venta, cesion en uso o del servicio prestado -->
        <xsl:variable name="totVentaOservicioPrestado" select="sac:TotalAmount"/>
        
        <!-- 
        
            SI el campo Importe total de la venta, cessión en uso o del servicio prestado no está vacío validar:
            
            Total valor de venta-operaciones gravadas + Total valor de venta-operaciones no gravadas + Total valor de venta-operaciones exoneradas + 
            Total IGV + Total ISC + Total otros tributos + Total otros Cargos” - 5 menor igual " Importe total de la venta, cesión en uso o del servicio prestado".
            Y
            "Total valor de venta-operaciones gravadas + Total valor de venta-operaciones no gravadas + 
            Total valor de venta-operaciones exoneradas + Total IGV + Total ISC + Total otros tributos + Total otros Cargos”  + 5 mayor igual " 
            Importe total de la venta, cesión en uso o del servicio prestado".
         -->
        <xsl:if test="$totVentaOservicioPrestado">
            <!-- PAS20191U210100194 -->
            <!-- <xsl:variable name="sumaCargosTributos" select="number($totOtrosTributos) + number($totIGV) + number($totISC) + number($totOtrosCargos) + number($totICBPER) + number($totVentaOperInafectas) + number($totVentaOperExoneradas) + number($totVentaOperGravadas)"/>  -->
            <xsl:variable name="sumaCargosTributos" select="number($totOtrosTributos) + number($totIGV) + number($totISC) + number($totOtrosCargos) + number($totICBPER) + number($totVentaOperInafectas) + number($totVentaOperExoneradas) + number($totVentaOperGravadas)+ number($totVentaOperExportacion) + number($totIVAP)"/>
            
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4027'" />
                <xsl:with-param name="node" select="sac:TotalAmount" />
                <xsl:with-param name="expresion" select="($totVentaOservicioPrestado + 5 ) &lt; $sumaCargosTributos or ($totVentaOservicioPrestado - 5) &gt; $sumaCargosTributos" />
                <xsl:with-param name="isError" select ="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                <xsl:with-param name="line" select ="$nroLinea"/>
            </xsl:call-template>
        </xsl:if>
        
                
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:TotalAmount@currencyID  Si algún Tag UBL es diferente en /SummaryDocuments/sac:SummaryDocumentsLine/
        ERROR  2071-->
        <!-- PAS20191U210100194 ya se encontraba corregido -->        
        <xsl:variable name="monedaComprobante" select="sac:TotalAmount/@currencyID"/>
        <xsl:variable name="nodosConMonedaDiferente" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::sac:SUNATPerceptionSummaryDocumentReference)]"/>
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="$nodosConMonedaDiferente" />
            <xsl:with-param name="expresion" select="count($nodosConMonedaDiferente)>0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty  Si campo Importe total de la venta > 700 nuevos soles
        ERROR  2514-->
        <!-- <xsl:if test="sac:TotalAmount &gt; 700"> PASE PAS20191U210100194 ohs-->
        <!-- Versión 5 excel se vuelve a dejar solo como mayor-->
        <!--xsl:if test="sac:TotalAmount &gt;= 700"-->
        <xsl:if test="sac:TotalAmount &gt; 700">        
            
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2514'"/>
                <xsl:with-param name="node" select="cac:AccountingCustomerParty"/>
            </xsl:call-template>
            
        </xsl:if>
        
        <xsl:apply-templates select="cac:AccountingCustomerParty">
		    <xsl:with-param name="nroLinea" select="$nroLinea"/>
		</xsl:apply-templates>
        
        <xsl:for-each select="sac:BillingPayment">
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount  No existe el Tag UBL
            ERROR  2255-->
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount  El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
            ERROR  2254-->
            <xsl:call-template name="existAndValidateValueTwoDecimal">
                <xsl:with-param name="errorCodeNotExist" select="'2255'"/>
                <xsl:with-param name="errorCodeValidate" select="'2254'"/>
                <xsl:with-param name="node" select="cbc:PaidAmount"/>
                <xsl:with-param name="isGreaterCero" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:PaidAmount  El valor del Tag UBL es cero (0)
            ERROR  2260-->
            <!-- PAS20191U210100194 INICIO JOH-->
            <!-- <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2260'" />
                <xsl:with-param name="node" select="cbc:PaidAmount" />
                <xsl:with-param name="expresion" select="cbc:PaidAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template> -->
            <!-- PAS20191U210100194 FIN JOH-->
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID  No existe el Tag UBL
            ERROR  2257-->
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2257'"/>
                <xsl:with-param name="node" select="cbc:InstructionID"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID  El Tag UBL no existe en el listado
            ERROR  2256-->
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'11'"/>
                <xsl:with-param name="idCatalogo" select="cbc:InstructionID"/>
                <xsl:with-param name="errorCodeValidate" select="'2256'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:BillingPayment/cbc:InstructionID  El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
            ERROR  2357-->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2357'" />
                <xsl:with-param name="node" select="cbc:InstructionID" />
                <xsl:with-param name="expresion" select="count(key('by-BillingPayment-in-line', concat(cbc:InstructionID,'-', $nroLinea))) > 1" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
        </xsl:for-each>
        
        <xsl:for-each select="cac:AllowanceCharge">
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:ChargeIndicator  El valor del Tag UBL es diferente de "true"
            ERROR  2263-->
            <xsl:call-template name="existAndRegexpValidateElement">
                <xsl:with-param name="errorCodeNotExist" select="'2263'"/>
                <xsl:with-param name="errorCodeValidate" select="'2263'"/>
                <xsl:with-param name="node" select="cbc:ChargeIndicator"/>
                <xsl:with-param name="regexp" select="'^true$'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:ChargeIndicator  El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
            ERROR  2411-->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2411'" />
                <xsl:with-param name="node" select="cbc:ChargeIndicator" />
                <xsl:with-param name="expresion" select="count(key('by-ChargeIndicator-in-line', concat(cbc:ChargeIndicator,'-', $nroLinea))) > 1" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:Amount  El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
            ERROR  2261-->
            <xsl:call-template name="existAndValidateValueTwoDecimal">
                <xsl:with-param name="errorCodeNotExist" select="'2261'"/>
                <xsl:with-param name="errorCodeValidate" select="'2261'"/>
                <xsl:with-param name="node" select="cbc:Amount"/>
                <xsl:with-param name="isGreaterCero" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
            
            <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AllowanceCharge/cbc:Amount  El valor del Tag UBL es cero (0)
            ERROR  2266-->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2266'" />
                <xsl:with-param name="node" select="cbc:Amount" />
                <xsl:with-param name="expresion" select="cbc:Amount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                <!-- PAS20191U210100194 INICIO JOH-->
                <xsl:with-param name="isError" select ="false()"/>
                <xsl:with-param name="line" select ="$nroLinea"/>
                <!-- PAS20191U210100194 FIN JOH-->
            </xsl:call-template>
        
        </xsl:for-each>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID  Debe existir un Tag UBL con valor "1000" y otro con valor "2000" en cada /SummaryDocuments/sac:SummaryDocumentsLine
        ERROR  2278-->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2278'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID[text()='1000' or text()='1016']]/cbc:Name" />
            <!-- PAS20201U210400026 Se agrega el IVAP-->
            <xsl:with-param name="expresion" select="count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']) = 0 and count(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']) = 0" />
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
        
        
        
        <!-- Valida percepcion  si es diferente de boleta o es diferente de alta y tiene percepcion error solo se acepta info
             de percepcion para altas de boleta y bajas -->
        <xsl:if test="sac:SUNATPerceptionSummaryDocumentReference and (cbc:DocumentTypeCode!='03' or cac:Status/cbc:ConditionCode='2')">
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="'2986'" />
                <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', $nroLinea, '. Solo se acepta informacion de percepcion para nuevas boletas: el codigo de operacion es: ', cac:Status/cbc:ConditionCode,' y debe de ser 1.')" />
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="sac:SUNATPerceptionSummaryDocumentReference and cbc:DocumentTypeCode='03'">
        
            <!-- Si existe  informacion de percepcion, El tag UBL /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID, para la linea esta vacío
            ERROR 2679
            -->
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2679'"/>
                <xsl:with-param name="node" select="cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
            </xsl:call-template>
        
            <xsl:apply-templates select="sac:SUNATPerceptionSummaryDocumentReference">
                <xsl:with-param name="parent_position" select="$nroLinea"/>
                <!-- inicio PAS20191U210100194  -->
                <xsl:with-param name="totalVenta" select="$totVentaOservicioPrestado"/>
                <xsl:with-param name="moneda" select="$monedaComprobante"/>
                <!-- fin PAS20191U210100194 -->
            </xsl:apply-templates>
        </xsl:if>
        
		<!--PAS20191U210100273 INICIO-->
		<!-- Se separa ERR-2512 en ERR-2582 y ERR-2583 -->
        <xsl:if test="cac:BillingReference and not(cbc:DocumentTypeCode='07' or cbc:DocumentTypeCode='08')">
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="'2582'" />
                <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', $nroLinea, '. Solo se acepta informacion de comprobantes de referencia para notas (Credito o debito): el tipo de comprobante es: ', cbc:DocumentTypeCode,' y debe de ser 07 o 08.')" />
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="not(cac:BillingReference) and (cbc:DocumentTypeCode='07' or cbc:DocumentTypeCode='08') and cac:Status/cbc:ConditionCode!='3'">
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="'2583'" />
                <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', $nroLinea, '. Si tipo de comprobante es nota, debe existir informacion del tipo de documento que modifica)')"/>
            </xsl:call-template>
        </xsl:if>
        <!--PAS20191U210100273 FIN -->
        
        <xsl:if test="cac:BillingReference">
            <xsl:apply-templates select="cac:BillingReference">
                <xsl:with-param name="nroLinea" select="$nroLinea"/>
                <xsl:with-param name="tipoope" select="cac:Status/cbc:ConditionCode"/>
				</xsl:apply-templates>
        </xsl:if>
        
          
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
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID  El valor del Tag UBL no debe repetirse en el /SummaryDocuments/sac:SummaryDocumentsLine
        ERROR  2355-->
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
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cbc:TaxAmount  El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR  2048-->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount  El valor del Tag UBL es diferente al Tag anterior
        ERROR  2344-->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2344'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number(cac:TaxSubtotal/cbc:TaxAmount) != number(cbc:TaxAmount)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID  No existe el Tag UBL o es vacío
        ERROR  2269-->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2269'"/>
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID  El valor del Tag UBL es diferente al listado
        ERROR  2268-->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2268'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name  No existe el Tag UBL o es vacío
        ERROR  2271-->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2271'"/>
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        <xsl:choose>
            <xsl:when test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000'">
        
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name  Si "Código de tributo" es 1000, el valor del Tag UBL es diferente a "IGV"
                ERROR  2276-->
                <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'2276'" />
                    <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                    <xsl:with-param name="expresion" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '1000']/cbc:Name != 'IGV'" />
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. cbc:Name debe de ser IGV')"/>
                </xsl:call-template>
        
            </xsl:when>
            
            <xsl:when test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '1016'">
        
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name  Si "Código de tributo" es 1000, el valor del Tag UBL es diferente a "IGV"
                ERROR  2276-->
                <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'3051'" />
                    <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                    <xsl:with-param name="expresion" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '1016']/cbc:Name != 'IVAP'" />
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. cbc:Name debe de ser IVAP')"/>
                </xsl:call-template>
        
            </xsl:when>
        
            <xsl:when test="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'">
            
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name  Si "Código de tributo" es 2000, el valor del Tag UBL es diferente a "ISC"
                ERROR  2275-->
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
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:AccountingCustomerParty">
        <xsl:param name="nroLinea"/>
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID  Si existe tag de "adquiriente o usuario", no existe el Tag UBL
        ERROR  2014-->
        <!-- numero de documento -->
        
        <!-- <xsl:call-template name="existElement"> PAS20191U210100194-->
         <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2014'"/>
            <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
        </xsl:call-template>
        
        
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID  
        Si existe tag de "adquiriente o usuario", el formato del Tag UBL es diferente a alfanumérico  de 4 a 20 caracteres
        ERROR  2018-->
        <xsl:choose>
        
            <xsl:when test="cbc:AdditionalAccountID ='6'">
                <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2017'"/>
                    <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
                    <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="cbc:AdditionalAccountID ='1'">
                <xsl:call-template name="regexpValidateElementIfExist">
                    <!-- PAS20191U210100194 <xsl:with-param name="errorCodeValidate" select="'2027'"/>  -->
                    <xsl:with-param name="errorCodeValidate" select="'4207'"/> 
                    <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
                    <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
                    <xsl:with-param name="isError" select ="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                    <xsl:with-param name="line" select ="$nroLinea"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- Ajustado en PAS20221U210600001 ERR-2018 pasa a OBS-4208 y se redefine la validacion-->

            <!-- PAS20191U210100194 Ya se encontraba el - en la expresion regular -->
            <!--xsl:otherwise>
                <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2018'"/>
                    <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
                    <xsl:with-param name="regexp" select="'^[\d\w-]{1,20}$'"/>
                    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                </xsl:call-template>
            </xsl:otherwise-->
            
            <xsl:when test="(cbc:AdditionalAccountID ='4') or (cbc:AdditionalAccountID ='7') or
							(cbc:AdditionalAccountID ='0') or (cbc:AdditionalAccountID ='A') or 
							(cbc:AdditionalAccountID ='B') or (cbc:AdditionalAccountID ='C') or
							(cbc:AdditionalAccountID ='D') or (cbc:AdditionalAccountID ='E') or
              				(cbc:AdditionalAccountID ='F') or (cbc:AdditionalAccountID ='G')">            
                <xsl:choose>
        	         <xsl:when test ="cbc:CustomerAssignedAccountID and (string-length(cbc:CustomerAssignedAccountID) &gt; 15 or string-length(cbc:CustomerAssignedAccountID) &lt; 1 )">
		                  <xsl:call-template name="isTrueExpresionIfExist">
		                     <xsl:with-param name="errorCodeValidate" select="'4208'" />
		                     <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID" />
		                     <xsl:with-param name="expresion" select="true()" />
		                     <xsl:with-param name="isError" select ="false()"/>
		                     <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
		                     <xsl:with-param name="line" select ="$nroLinea"/>
                      </xsl:call-template>
        	         </xsl:when>
        	         <xsl:otherwise>		
		                  <xsl:call-template name="regexpValidateElementIfExist">
		                     <xsl:with-param name="errorCodeValidate" select="'4208'"/>
		                     <xsl:with-param name="node" select="cbc:CustomerAssignedAccountID"/>
		                     <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{0,}$'"/> 
		                     <xsl:with-param name="isError" select ="false()"/>
		                     <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
                         <xsl:with-param name="line" select ="$nroLinea"/>
		                  </xsl:call-template>
        	         </xsl:otherwise>
               </xsl:choose>
            
            </xsl:when>
        
        </xsl:choose>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty/cbc:AdditionalAccountID  Si existe tag de "adquiriente o usuario", no existe el Tag UBL
        ERROR  2015-->
        <xsl:if test="cbc:CustomerAssignedAccountID">
       		<!-- Tipo de documento -->
	        <xsl:call-template name="existElementNoVacio">
	            <xsl:with-param name="errorCodeNotExist" select="'2015'"/>
	            <xsl:with-param name="node" select="cbc:AdditionalAccountID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
	        </xsl:call-template>
        
        	<!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:AccountingCustomerParty/cbc:AdditionalAccountID  Si existe tag de "adquiriente o usuario", el Tag UBL es diferente al listado o guión 
	        ERROR  2015-->
	        <xsl:if test="cbc:AdditionalAccountID != '-'">
	            <xsl:call-template name="findElementInCatalog">
	                <xsl:with-param name="catalogo" select="'06'"/>
	                <xsl:with-param name="idCatalogo" select="cbc:AdditionalAccountID"/>
	                <xsl:with-param name="errorCodeValidate" select="'2016'"/>
	                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. ')"/>
	            </xsl:call-template>
	        </xsl:if>
        </xsl:if>


    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template sac:SUNATPerceptionSummaryDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->    
    
    <xsl:template match="sac:SUNATPerceptionSummaryDocumentReference">
        <xsl:param name="parent_position"/>
        
        <!-- inicio PAS20191U210100194  -->
        <xsl:param name="totalVenta"/>
        <xsl:param name="moneda"/>
        
        <!-- fin PAS20191U210100194  -->
        
        <!-- catalogo 22 
            01  PERCEPCION VENTA INTERNA    TASA 2%
            02  PERCEPCION A LA ADQUISICION DE COMBUSTIBLE  TASA 1%
            03  PERCEPCION REALIZADA AL AGENTE DE PERCEPCION CON TASA ESPECIAL  TASA 0.5%
         -->    
         <!-- Regimen de percepcion debe de pertenecer al catalogo 22-->
         <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATPerceptionSystemCode El valor del Tag UBL es diferente al listado 
        ERROR 2517 -->
         <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'22'"/>
            <xsl:with-param name="idCatalogo" select="sac:SUNATPerceptionSystemCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2517'"/>
         </xsl:call-template>
         
         <!-- Tasa de percepción debe de pertenecer al catalogo 22-->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATPerceptionPercent El valor del Tag UBL es diferente a la tasa del listado para el "Regimen de percepción" 
        ERROR 2891 -->
        
         <xsl:call-template name="findElementInCatalogProperty">
            <xsl:with-param name="catalogo" select="'22'"/>
            <xsl:with-param name="propiedad" select="'tasa'"/>
            <xsl:with-param name="idCatalogo" select="sac:SUNATPerceptionSystemCode"/>
            <xsl:with-param name="valorPropiedad" select="number(sac:SUNATPerceptionPercent)"/>
            <xsl:with-param name="errorCodeValidate" select="'2891'"/>
         </xsl:call-template>
         
         
         
        <!--/SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/cbc:TotalInvoiceAmount    El valor del Tag UBL es menor o igual a cero (0) 
        ERROR 2893 -->
        <!-- Monto total de la percepción tiene que ser mayor que cero-->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/cbc:TotalInvoiceAmount El formato del Tag UBL es diferente a númerico de 12 enteros y 2 decimales 
        ERROR 2893 -->
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2893'"/>
            <xsl:with-param name="errorCodeValidate" select="'2893'"/>
            <xsl:with-param name="node" select="cbc:TotalInvoiceAmount"/>
            <xsl:with-param name="isGreaterCero" select="true()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $parent_position,'. Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
        </xsl:call-template>
        
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATTotalCashed El formato del Tag UBL es diferente a númerico de 12 enteros y 2 decimales 
        ERROR 2895 -->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATTotalCashed    El valor del Tag UBL es menor o igual a cero (0) 
        ERROR 2895 -->
        
        <!-- Monto total a cobrar incluida la percepción  tiene que ser mayor que cero -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2895'"/>
            <xsl:with-param name="errorCodeValidate" select="'2895'"/>
            <xsl:with-param name="node" select="sac:SUNATTotalCashed"/>
            <xsl:with-param name="isGreaterCero" select="true()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $parent_position,'. Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
        </xsl:call-template>
        
        <!-- Base imponible percepción -->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/cbc:TaxableAmount El formato del Tag UBL es diferente a númerico de 12 enteros y 2 decimales 
        ERROR 2897 -->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/cbc:TaxableAmount    El valor del Tag UBL es menor o igual a cero (0) 
        ERROR 2897 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2897'"/>
            <xsl:with-param name="errorCodeValidate" select="'2897'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="true()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $parent_position,'. Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
        </xsl:call-template>
        
        <!-- PAS20191U210100194  <xsl:variable name="sumaTotalCobrarMasPercepcion" select="number(cbc:TaxableAmount) + number(cbc:TotalInvoiceAmount)"/>  -->
        <!-- inicio PAS20191U210100194  -->
        <xsl:variable name="sumaTotalCobrarMasPercepcion" select="number($totalVenta) + number(cbc:TotalInvoiceAmount)"/>
        
        <xsl:variable name="montoPercepcion" select="(number(cbc:TaxableAmount) * number(sac:SUNATPerceptionPercent)) div 100"/>
        
        <xsl:if test="$moneda='PEN'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2608'" />
                <xsl:with-param name="node" select="cbc:TotalInvoiceAmount" />
                <xsl:with-param name="expresion" select="(cbc:TotalInvoiceAmount + 1 ) &lt; $montoPercepcion or (cbc:TotalInvoiceAmount - 1) &gt; $montoPercepcion" />
                             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $parent_position,'. Monto de la percepción no coincide: ',cbc:TotalInvoiceAmount, ' es diferente a la base imponible percepcion por la tasa: ', $montoPercepcion)" />
            </xsl:call-template>
        </xsl:if>             
        
        <xsl:if test="$moneda='PEN'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2608'" />
                <xsl:with-param name="node" select="sac:SUNATTotalCashed" />
                <xsl:with-param name="expresion" select="(sac:SUNATTotalCashed + 1 ) &lt; $sumaTotalCobrarMasPercepcion or (sac:SUNATTotalCashed - 1) &gt; $sumaTotalCobrarMasPercepcion" />
                             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $parent_position,'. Monto total a cobrar incluida la percepción: ',sac:SUNATTotalCashed, ' es diferente a la suma del Monto de la percepción y el Importe de la venta: ', $sumaTotalCobrarMasPercepcion)" />
            </xsl:call-template>
        </xsl:if>        
        <!-- fin PAS20191U210100194  -->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATTotalCashed    La suma de "Monto total de la percepción" más "Base imponible percepción" es diferente al Tag UBL con una tolerancia de más/meno uno 
        ERROR 4027 -->
        <!-- PAS20191U210100194
         <xsl:if test="number(number(sac:SUNATTotalCashed) + 1) &lt; number($sumaTotalCobrarMasPercepcion) or number(number(sac:SUNATTotalCashed) - 1) &gt; number($sumaTotalCobrarMasPercepcion)">
            <xsl:call-template name="addWarning">
                <xsl:with-param name="warningCode" select="'4027'" />
                <xsl:with-param name="warningMessage" select="concat('Error en la linea: ', $parent_position,'. Monto total a cobrar incluida la percepción no coincide: ',sac:SUNATTotalCashed, ' es diferente a la suma del Monto total de la percepción y la Base imponible percepción: ', $sumaTotalCobrarMasPercepcion)" />
            </xsl:call-template>
        </xsl:if> -->
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/cbc:TotalInvoiceAmount@currencyID
        El valor de la propiedad no existe o es diferente "PEN"
        ERROR 2685 -->
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2685'"/>
            <xsl:with-param name="errorCodeValidate" select="'2685'"/>
            <xsl:with-param name="node" select="cbc:TotalInvoiceAmount/@currencyID"/>
            <xsl:with-param name="regexp" select="'^(PEN)$'"/>
        </xsl:call-template>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/sac:SUNATPerceptionSummaryDocumentReference/sac:SUNATTotalCashed@currencyID
        El valor del Tag UBL es diferente "PEN"
        ERROR 2690 -->
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2690'"/>
            <xsl:with-param name="errorCodeValidate" select="'2690'"/>
            <xsl:with-param name="node" select="sac:SUNATTotalCashed/@currencyID"/>
            <xsl:with-param name="regexp" select="'^(PEN)$'"/>
        </xsl:call-template>
        
        
        
    </xsl:template>
    
        <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template sac:SUNATPerceptionSummaryDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    
    
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:BillingReference =========================================== 
    
    ===========================================================================================================================================
    -->
    
   <xsl:template match="cac:BillingReference">
        <xsl:param name="nroLinea"/>
        <xsl:param name="tipoope"/>
				
        <xsl:variable name="tipoComprobanteReferencia" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode"/>
        <xsl:variable name="comprobanteModificaID" select="cac:InvoiceDocumentReference/cbc:ID"/>
        
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode  Si "Tipo de documento" es 07 o 08, no existe el Tag UBL
        ERROR  2512-->
        <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode  Si "Tipo de documento" es 07 o 08, el valor del Tag UBL es diferente a "03" o "12"
        ERROR  2513-->
        

        <!-- Si el comprobante es una nota de crédito o nota de debito 
        el campo no debe de estar vacio 
        SI tipo de comprobante es  07 ó 08 validar:
        Tipo de comprobante que modifica = 03 ó 12 -->

		<xsl:if test="$tipoope != '3'">
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2583'"/>
				<xsl:with-param name="errorCodeValidate" select="'2513'"/>
				<xsl:with-param name="node" select="$tipoComprobanteReferencia"/>
				<!-- Versión 5 excel-->
        <!--xsl:with-param name="regexp" select="'^(12|03)$'"/-->
        <xsl:with-param name="regexp" select="'^(12|03|16|55)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, '. El tipo de comprobante relacionado debe de ser 12 (ticket) o 03 (boleta)')"/>
			</xsl:call-template>

		
        <!-- 
            Número de serie de la boleta de venta que modifica + Tipo de comprobante que modifica   
            Si el tipo de documento a modificar es boleta debe de tener el formato de boleta    
            SI Tipo de comprobante que modifica = 03 validar:
            El campo debe de tener el siguiente formato: B###(donde # representa caracteres numéricos)
            seguido por un guion y segui por un numero como máximo de 8 dígitos
         -->
        
      <!-- Versión 5 excel-->
      <!--xsl:when test="$tipoComprobanteReferencia = '12'"-->
      <xsl:if test="$tipoComprobanteReferencia = '12' or $tipoComprobanteReferencia = '16' or $tipoComprobanteReferencia = '55'">
                <!-- 20 caracteres alfanumericos incluido el guion opcional el correlativo de 10 numeros -->
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID  Si "Tipo de documento" es 07 o 08, no existe el Tag UBL
                ERROR  2524-->
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID  "Si ""Tipo de documento que modifica"" es 12, el formato del Tag UBL es diferente a: ^(?!0+-)[a-zA-Z0-9]{1,20}-(?!0+$)([0-9]{1,20})$"
                ERROR  2897-->
          <xsl:call-template name="existAndRegexpValidateElement">
               <xsl:with-param name="errorCodeNotExist" select="'2524'"/>
               <!-- PAS20191U210100194 <xsl:with-param name="errorCodeValidate" select="'2117'"/> -->
               <xsl:with-param name="errorCodeValidate" select="'2920'"/>
               <xsl:with-param name="node" select="$comprobanteModificaID"/>
               <!-- PAS20191U210100194 <xsl:with-param name="regexp" select="'(?!0+-)^[a-zA-Z0-9]{1,20}-(?!0+$)([0-9]{1,20})$'"/> -->
               <!-- Versión 5 excel-->
               <!--xsl:with-param name="regexp" select="'(?!0+-)^[a-zA-Z0-9-]{1,20}-(?!0+$)([0-9]{1,20})$'"/-->
               <xsl:with-param name="regexp" select="'^[a-zA-Z0-9-]{1,20}-[a-zA-Z0-9-]{1,20}$'"/> 
               <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
          </xsl:call-template>
      </xsl:if>      
                <!-- Inicia con la letra B seguidos por tres caracteres alfanumericos seguidos por un guion
                     seguidos por 8 caracteres numericos pero todos los caracteres no deben ser 0  -->
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID  Si "Tipo de documento" es 07 o 08, no existe el Tag UBL
                ERROR  2524-->
                <!-- /SummaryDocuments/sac:SummaryDocumentsLine/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID  "Si ""Tipo de documento que modifica"" es diferente a 12, el formato del Tag UBL es diferente a: ^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$"
                ERROR  2920-->
      <xsl:if test="$tipoComprobanteReferencia = '03'">
					<xsl:call-template name="existAndRegexpValidateElement">
					     <xsl:with-param name="errorCodeNotExist" select="'2524'"/>
					     <xsl:with-param name="errorCodeValidate" select="'2920'"/>
					     <xsl:with-param name="node" select="$comprobanteModificaID"/>
					     <!--PAS20191U210100194 <xsl:with-param name="regexp" select="'^([B](?!0+-)[A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$|^(?!0+-)([0-9]{1,4})-(?!0+$)([0-9]{1,8})$'"/>  -->
					     <xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$|^(?!0+-)([0-9]{1,4})-(?!0+$)([0-9]{1,8})$|^(EB01)-(?!0+$)([0-9]{1,8})$'"/>
					     <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
					</xsl:call-template>
			</xsl:if>
    </xsl:if>
            
    </xsl:template>
    
    
     <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:BillingReference =========================================== 
    
    ===========================================================================================================================================
    -->

</xsl:stylesheet>
