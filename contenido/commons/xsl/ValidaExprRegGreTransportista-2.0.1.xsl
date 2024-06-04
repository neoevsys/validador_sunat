<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:dyn="http://exslt.org/dynamic"                                                                                                                           
  xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"                                                              
  xmlns:func="http://exslt.org/functions"                                                                                  
  xmlns="urn:oasis:names:specification:ubl:schema:xsd:DespatchAdvice-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
  xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">                                                                                                                                                                                  
  <!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->

  <!-- Inicio: SFS -->
  <!-- <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
  <xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" /> -->
  <xsl:include href="sunat_archivos/sfs/VALI/commons/error/validate_utils.xsl" dp:ignore-multiple="yes"/>
  <!-- Ruta Desarrollo MS -->
  <!-- <xsl:include href="/cpeses/data/trabajo/sunat_archivos/sfs/VALI/commons/error/validate_utils.xsl" dp:ignore-multiple="yes"/> -->
  <!-- Ruta Calidad y Produccion MS -->
  <!-- <xsl:include href="/cpe/data/sunat_archivos/sfs/VALI/commons/error/validate_utils.xsl" dp:ignore-multiple="yes"/> -->
  <!-- Fin: SFS -->
  
  <!-- key Tipo y Numero de documento relacionado duplicados -->  
  <xsl:key name="by-document-additional-reference" match="*[local-name()='DespatchAdvice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
  
  <!-- key Conductores secundarios duplicados -->  
  <xsl:key name="by-conductores" match="*[local-name()='DespatchAdvice']/cac:Shipment/cac:ShipmentStage/cac:DriverPerson[cbc:JobTitle[text() = 'Secundario']]/cac:IdentityDocumentReference" use="cbc:ID"/>
 
  <!-- key Numero de lineas duplicados -->
  <xsl:key name="by-despatchLine-id" match="*[local-name()='DespatchAdvice']/cac:DespatchLine" use="number(cbc:ID)"/>

  <!-- Inicio: SFS -->
  <xsl:param name="nombreArchivoEnviado"/>
  <!-- Fin: SFS -->
  <xsl:template match="/*">
    
     <!-- Variables -->
	 <!-- Inicio: SFS -->
     <!-- <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
     <xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>
     <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
     <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/> -->
	 
	 <xsl:variable name="numeroRuc" select="substring($nombreArchivoEnviado, 1, 11)"/>
	 <xsl:variable name="tipoComprobante" select="substring($nombreArchivoEnviado, 13, 2)"/>
	 <xsl:variable name="numeroSerie" select="substring($nombreArchivoEnviado, 16, 4)"/>
	 <xsl:variable name="numeroComprobante" select="substring($nombreArchivoEnviado, 21, string-length($nombreArchivoEnviado) - 24)"/>
	 
	 <!-- Fin: SFS -->
	 
     <!-- Version del UBL -->
     
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2111'"/>
        <xsl:with-param name="errorCodeValidate" select="'2110'"/>
        <xsl:with-param name="node" select="cbc:UBLVersionID"/>
        <xsl:with-param name="regexp" select="'^(2.1)$'"/>
     </xsl:call-template>
     
     <!-- Version de la Estructura del Documento -->
     
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2113'"/>
        <xsl:with-param name="errorCodeValidate" select="'2112'"/>
        <xsl:with-param name="node" select="cbc:CustomizationID"/>
        <xsl:with-param name="regexp" select="'^(2.0)$'"/>
     </xsl:call-template>
         
         
     <!-- Numeracion, conformada por serie y numero correlativo -->
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'1001'"/>
        <xsl:with-param name="node" select="cbc:ID"/>
        <xsl:with-param name="regexp" select="'^[V][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
     </xsl:call-template>
     
     <!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->
     <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML-->
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'1034'" />
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        <xsl:with-param name="expresion" select="$numeroRuc != cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
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
     
     <!-- Fecha de emision: patron YYYY-MM-DD --> 
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3436'"/>
        <xsl:with-param name="node" select="cbc:IssueDate"/>
        <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
     </xsl:call-template>

     <!--xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'2329'" />
        <xsl:with-param name="node" select="cbc:IssueDate" />
        <xsl:with-param name="expresion" select="number(translate(substring(date:date(),1,10),'-','')) &lt; number(translate(cbc:IssueDate,'-',''))" />
     </xsl:call-template-->

     <!-- Hora de emision: patron HH:MM:SS -->     
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'3437'"/>
        <xsl:with-param name="errorCodeValidate" select="'3438'"/>
        <xsl:with-param name="node" select="cbc:IssueTime"/>
        <xsl:with-param name="regexp" select="'^[0-9]{2}:[0-9]{2}:[0-9]{2}?$'"/>
     </xsl:call-template>
     
     <!-- Tipo Comprobante -->     
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'1050'"/>
        <xsl:with-param name="errorCodeValidate" select="'1051'"/>
        <xsl:with-param name="node" select="cbc:DespatchAdviceTypeCode"/>
        <xsl:with-param name="regexp" select="'^(31)$'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cbc:DespatchAdviceTypeCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cbc:DespatchAdviceTypeCode/@listName"/>
         <xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4253'"/>
        <xsl:with-param name="node" select="cbc:DespatchAdviceTypeCode/@listURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

        
     <!--  Observaciones  -->
     <xsl:apply-templates select="cbc:Note"/>

     
     <!--  DATOS DEL TRANSPORTISTA (emisor) -->    
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2678'"/>
        <xsl:with-param name="errorCodeValidate" select="'2511'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
        <xsl:with-param name="regexp" select="'^(6)$'"/>
     </xsl:call-template>            
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
         <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Documento de identidad - Transportista'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Documento de identidad - Transportista'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4257'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Documento de identidad - Transportista'"/>
     </xsl:call-template>

     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
     </xsl:call-template>

		 <xsl:choose>
        <xsl:when test="string-length(cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 1 ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4338'" />
              <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="'Nombre/Razon social del transportista'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(translate(cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4338'"/>
              <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="'Nombre/Razon social del transportista'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>				
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4338'"/>
              <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="'Nombre/Razon social del transportista'"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>

     <!-- Registro MTC del transportista -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'4391'"/>
        <xsl:with-param name="errorCodeValidate" select="'4392'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:CompanyID"/>
        <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{1,20})$'"/>
        <xsl:with-param name="isError" select="false()"/>
     </xsl:call-template>     

     <xsl:if test="count(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:CompanyID[text() != '']) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3353'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:CompanyID"/>
           <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity) &gt; 1"/>
           <xsl:with-param name="descripcion" select="'Existe mas de un Registro de MTC del transportista'"/>
        </xsl:call-template>     
     </xsl:if>  

     <!-- Autorizaciones especiales Transportista -->
     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID != ''">
        <xsl:choose>          
           <xsl:when test="(string-length(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID) &gt; 50 or string-length(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID) &lt; 3) " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4396'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4396'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4396'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose>  
     </xsl:if> 
     
     <xsl:if test="count(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID[text() != '']) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3353'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID"/>
           <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity) &gt; 1"/>
           <xsl:with-param name="descripcion" select="'Existe mas de una Autorizacion especial del transportista'"/>
        </xsl:call-template>     
     </xsl:if>     
     
     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID != ''">
        <!-- Si existe Numero de Autorizacion especial, debe existir la entidad emisora -->
        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4394'"/>
			     <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Autorizacion especial del transportista'"/>
		    </xsl:call-template>
     </xsl:if>

     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeID != ''">

		    <xsl:call-template name="findElementInCatalog">
			     <xsl:with-param name="errorCodeValidate" select="'4395'"/>
			     <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeID"/>
           <xsl:with-param name="catalogo" select="'D37'"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Autorizacion especial del transportista'"/>
		    </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4397'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeID"/>
           <xsl:with-param name="expresion" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID = ''"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Autorizacion especial del transportista'"/>
        </xsl:call-template> 
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Entidad Autorizadora)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Entidad Autorizadora - Autorizacion especial del transportista'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Entidad Autorizadora - Autorizacion especial del transportista'"/>
     </xsl:call-template>
     

     <!-- DOCUMENTOS RELACIONADOS -->  

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '31' or text() = '65' or text() = '66' or text() = '67' or text() = '68' or text() = '69']]) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3345'"/>
           <xsl:with-param name="node" select="cac:AdditionalDocumentReference/cbc:DocumentType" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() != '-']]) &gt; 2" />
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '31' or text() = '65' or text() = '66' or text() = '67' or text() = '68' or text() = '69']]) = 0
                and count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and substring(cbc:ID, 1, 1) != '0' and substring(cbc:ID, 1, 1) != '1' and substring(cbc:ID, 1, 1) != '2' and substring(cbc:ID, 1, 1) != '3' 
                and substring(cbc:ID, 1, 1) != '4' and substring(cbc:ID, 1, 1) != '5' and substring(cbc:ID, 1, 1) != '6' and substring(cbc:ID, 1, 1) != '7' and substring(cbc:ID, 1, 1) != '8' and substring(cbc:ID, 1, 1) != '9'] ) = 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3346'"/>
           <xsl:with-param name="node" select="cac:AdditionalDocumentReference/cbc:DocumentType" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() != '-']]) &gt; 1" />
        </xsl:call-template>
     </xsl:if>
     
     <xsl:apply-templates select="cac:AdditionalDocumentReference">
        <xsl:with-param name="root" select="."/>
     </xsl:apply-templates>
     

     <!-- DATOS DEL REMITENTE -->

     <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'3383'"/>
       <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID"/>
     </xsl:call-template>

     <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'2541'"/>
       <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
     </xsl:call-template>  

     <xsl:call-template name="findElementInCatalog">
        <xsl:with-param name="errorCodeValidate" select="'2542'"/>
        <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
        <xsl:with-param name="catalogo" select="'06'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
       <xsl:with-param name="errorCodeValidate" select="'4255'"/>
       <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
       <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
       <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Remitente'"/>       
    </xsl:call-template>

    <xsl:call-template name="regexpValidateElementIfExist">
       <xsl:with-param name="errorCodeValidate" select="'4256'"/>
       <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
       <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
       <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Remitente'"/>
    </xsl:call-template>

    <xsl:call-template name="regexpValidateElementIfExist">
       <xsl:with-param name="errorCodeValidate" select="'4257'"/>
       <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
       <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
       <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Remitente'"/>
    </xsl:call-template>
       
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'2560'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID"/>
        <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
     </xsl:call-template>

    <xsl:choose>
       <xsl:when test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeID = '1'">
          <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'3384'"/>
             <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
             <xsl:with-param name="descripcion" select="'Numero de DNI invalido'"/>
          </xsl:call-template>
       </xsl:when>
       <xsl:when test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID/@schemeID = '6'">        
          <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'3384'"/>
             <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
             <xsl:with-param name="descripcion" select="'Numero de RUC invalido'"/>
          </xsl:call-template>
       </xsl:when>
       <xsl:otherwise>
          <xsl:choose>        	
             <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID) &lt; 1 " >
                <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'3384'"/>
                   <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="descripcion" select="'Longitud del numero de documento invalido'"/>
                </xsl:call-template>
             </xsl:when>
             <xsl:otherwise>					
                <xsl:call-template name="regexpValidateElementIfExist">
                   <xsl:with-param name="errorCodeValidate" select="'3384'"/>
                   <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID"/>
                   <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/>
                   <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/> 
                </xsl:call-template>        		
             </xsl:otherwise>
          </xsl:choose>       
       </xsl:otherwise>
     </xsl:choose>   
     
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'3387'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
     </xsl:call-template>
 
     <xsl:choose>          
        <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 1 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4422'"/>
              <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(translate(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4422'"/>
              <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4422'"/>
              <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>  


     <!-- DATOS DEL DESTINATARIO -->

     <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'2759'"/>
       <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
     </xsl:call-template>  

		 <xsl:call-template name="findElementInCatalog">
		    <xsl:with-param name="errorCodeValidate" select="'2760'"/>
		    <xsl:with-param name="idCatalogo" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
        <xsl:with-param name="catalogo" select="'06'"/>
		 </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Destinatario'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Destinatario'"/>
     </xsl:call-template>

    <xsl:call-template name="regexpValidateElementIfExist">
       <xsl:with-param name="errorCodeValidate" select="'4257'"/>
       <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
       <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
       <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del Destinatario'"/>
    </xsl:call-template>


    <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'2757'"/>
       <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
    </xsl:call-template>  
                   
    <xsl:choose>
       <xsl:when test="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '1'">
          <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'2758'"/>
             <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
             <xsl:with-param name="descripcion" select="'Numero de DNI invalido'"/>
          </xsl:call-template>
       </xsl:when>
       <xsl:when test="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">        
          <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'2758'"/>
             <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
             <xsl:with-param name="descripcion" select="'Numero de RUC invalido'"/>
          </xsl:call-template>
       </xsl:when>
       <xsl:otherwise>
          <xsl:choose>        	
             <xsl:when test="string-length(cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &lt; 1 " >
                <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'2758'"/>
                   <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="descripcion" select="'Longitud del numero de documento invalido'"/>
                </xsl:call-template>
             </xsl:when>
             <xsl:otherwise>					
                <xsl:call-template name="regexpValidateElementIfExist">
                   <xsl:with-param name="errorCodeValidate" select="'2758'"/>
                   <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                   <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/>
                   <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/> 
                </xsl:call-template>        		
             </xsl:otherwise>
          </xsl:choose>       
       </xsl:otherwise>
     </xsl:choose>    

     <!-- Nombre/razon social del Destinatario  --> 
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'2761'"/>
        <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
     </xsl:call-template>
 
     <xsl:choose>          
        <xsl:when test="string-length(cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 1 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4152'"/>
              <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(translate(cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4152'"/>
              <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>        
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4152'"/>
              <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>  
  

     <!-- LINEAS DE LA GUIA -->

     <xsl:if test="(count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '12' or text() = '48' or text() = '50' or text() = '52']]) &gt; 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0)
                or (count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48' or text() = '50' or text() = '52' or text() = '82']]) = 0 )">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3435'"/>
           <xsl:with-param name="node" select="cac:DespatchLine/cbc:DeliveredQuantity" />
           <xsl:with-param name="expresion" select="count(cac:DespatchLine[cbc:DeliveredQuantity &gt; 0]) = 0" />
        </xsl:call-template>
        
        <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '80']]) &gt; 0 ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3352'"/>
              <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7022']" />
              <xsl:with-param name="expresion" select="count(cac:DespatchLine/cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '7020']]) = 0" />
           </xsl:call-template>                
        </xsl:if>        
     </xsl:if>

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and substring(cbc:ID, 1, 1) != '0' and substring(cbc:ID, 1, 1) != '1' and substring(cbc:ID, 1, 1) != '2' and substring(cbc:ID, 1, 1) != '3' 
                         and substring(cbc:ID, 1, 1) != '4' and substring(cbc:ID, 1, 1) != '5' and substring(cbc:ID, 1, 1) != '6' and substring(cbc:ID, 1, 1) != '7' and substring(cbc:ID, 1, 1) != '8' and substring(cbc:ID, 1, 1) != '9'] ) &gt; 0
                or (count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '04'] and substring(cbc:ID, 1, 1) != '0' and substring(cbc:ID, 1, 1) != '1' and substring(cbc:ID, 1, 1) != '2' and substring(cbc:ID, 1, 1) != '3' 
                         and substring(cbc:ID, 1, 1) != '4' and substring(cbc:ID, 1, 1) != '5' and substring(cbc:ID, 1, 1) != '6' and substring(cbc:ID, 1, 1) != '7' and substring(cbc:ID, 1, 1) != '8' and substring(cbc:ID, 1, 1) != '9'] ) &gt; 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) &gt; 0)
                or (count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() = '52']]) &gt; 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) &gt; 0)">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4434'"/>
           <xsl:with-param name="node" select="cac:DespatchLine/cbc:DeliveredQuantity" />
           <xsl:with-param name="expresion" select="count(cac:DespatchLine[cbc:DeliveredQuantity &gt; 0]) &gt; 0" />
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
     </xsl:if>    
     
     <xsl:apply-templates select="cac:DespatchLine">
        <xsl:with-param name="root" select="."/> 
     </xsl:apply-templates>  
     
     <!-- PUNTO DE PARTIDA --> 

     <!-- Ubigeo de partida -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2775'"/>
        <xsl:with-param name="errorCodeValidate" select="'2776'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
        <xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de partida'"/> 
     </xsl:call-template>            

     <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3363'"/>
				<xsl:with-param name="idCatalogo" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de partida'"/>
		 </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de partida'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de partida'"/>
     </xsl:call-template>

     <!-- Direccion completa y detallada de partida -->
     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and substring(cbc:ID, 1, 1) != '0' and substring(cbc:ID, 1, 1) != '1' and substring(cbc:ID, 1, 1) != '2' and substring(cbc:ID, 1, 1) != '3' 
                         and substring(cbc:ID, 1, 1) != '4' and substring(cbc:ID, 1, 1) != '5' and substring(cbc:ID, 1, 1) != '6' and substring(cbc:ID, 1, 1) != '7' and substring(cbc:ID, 1, 1) != '8' and substring(cbc:ID, 1, 1) != '9'] ) = 0
              and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTransbordoProgramado']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2577'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
           <xsl:with-param name="descripcion" select="'Direccion punto de partida'"/>
        </xsl:call-template>  
     </xsl:if>
     
     <xsl:choose>          
        <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &gt; 500 or string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &lt; 3 " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4076'"/>
             <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
             <xsl:with-param name="descripcion" select="'Longitud de la direccion invalida'"/>
           </xsl:call-template>
        </xsl:when>

        <xsl:when test="string-length(translate(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line,' ','')) = 0 " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4076'"/>
             <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
             <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
           </xsl:call-template>
        </xsl:when>
           
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4076'"/>
              <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
           </xsl:call-template>            
        </xsl:otherwise>
     </xsl:choose> 
 
     <!-- Punto de georreferencia de partida -->
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:LocationCoordinate/cbc:LatitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de partida - Latitud'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:LocationCoordinate/cbc:LongitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de partida - Longitud'"/>
     </xsl:call-template>

     <!-- PUNTO DE LLEGADA --> 

     <!-- Ubigeo de llegada -->
     <xsl:if test="not(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID) or cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID = ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'2775'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09']]) = 0" />
           <xsl:with-param name="descripcion" select="'Ubigeo punto de llegada'"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                         or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) &gt; 0 ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4431'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Ubigeo punto de llegada'"/>
        </xsl:call-template>  
     </xsl:if>

     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2776'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
           <xsl:with-param name="descripcion" select="'Ubigeo punto de llegada'"/> 
        </xsl:call-template>            
   
        <xsl:call-template name="findElementInCatalog">
   				<xsl:with-param name="errorCodeValidate" select="'3368'"/>
   				<xsl:with-param name="idCatalogo" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
   				<xsl:with-param name="catalogo" select="'13'"/>
   		 </xsl:call-template>
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de llegada'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Ubigeo punto de llegada'"/>
     </xsl:call-template>

     <!-- Direccionn completa y detallada de llegada -->
     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09']]  ) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTransbordoProgramado']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2574'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
           <xsl:with-param name="descripcion" select="'Direccion punto de llegada'"/>
        </xsl:call-template>  
     </xsl:if>

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) &gt; 0  
               and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTransbordoProgramado']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4178'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Direccion punto de llegada'"/>
        </xsl:call-template>  
     </xsl:if>
     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line != ''">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line) &gt; 500 or string-length(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line) &lt; 3 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4068'"/>
                <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="'Longitud de la direccion invalida'"/>
              </xsl:call-template>
           </xsl:when>
   
           <xsl:when test="string-length(translate(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line,' ','')) = 0 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4068'"/>
                <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
              </xsl:call-template>
           </xsl:when>
              
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4068'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
     </xsl:if>

     <!-- Punto de georreferencia de llegada -->
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:LocationCoordinate/cbc:LatitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de llegada - Latitud'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="/cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:LocationCoordinate/cbc:LongitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de llegada - Longitud'"/>
     </xsl:call-template>     
     

     <!-- VEHICULO PRINCIPAL -->
     <!-- Placa -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'2566'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
        <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
     </xsl:call-template>

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2567'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{6,8})$'"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Tarjeta Unica de Circulacion Electronica -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'4399'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
        <xsl:with-param name="isError" select="false()"/>
        <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
     </xsl:call-template>

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3355'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{10,15})$'"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Autorizaciones especiales Vehiculo principal -->

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID != ''">
        <xsl:choose>          
           <xsl:when test="(string-length(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID) &gt; 50 or string-length(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID) &lt; 3) " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Vehiculo principal - Longitud de autorizacion invalido'"/>
              </xsl:call-template>      
           </xsl:when>

           <xsl:when test="string-length(translate(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Vehiculo principal - Caracteres invalidos'"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Vehiculo principal - Caracteres invalidos'"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose>  
     </xsl:if> 
     
     <xsl:if test="count(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID[text() != '']) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3356'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="expresion" select="count(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference) &gt; 1"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>     
     </xsl:if>    

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID != ''">
        <!-- Si existe Numero de Autorizacion especial, debe existir la entidad emisora -->
        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4403'"/>
			     <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID/@schemeID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
		    </xsl:call-template>
     </xsl:if>

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID/@schemeID != ''">

		    <xsl:call-template name="findElementInCatalog">
			     <xsl:with-param name="errorCodeValidate" select="'4407'"/>
			     <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID/@schemeID"/>
           <xsl:with-param name="catalogo" select="'D37'"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
		    </xsl:call-template>

        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4405'"/>
			     <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
		    </xsl:call-template>    
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Entidad Autorizadora)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Entidad Autorizadora - Autorizacion vehiculo principal'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Entidad Autorizadora - Autorizacion vehiculo principal'"/>
     </xsl:call-template>

     <!-- Vehiculos secundarios -->

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'4389'" />
        <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment/cbc:ID" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment) &gt; 2" />
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Vehiculos secundarios'"/>
     </xsl:call-template>

     <xsl:apply-templates select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment">
        <xsl:with-param name="root" select="."/>
     </xsl:apply-templates>      


     <!-- CONDUCTORES PRINCIPAL y SECUNDARIOS -->     

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3357'" />
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle[text()='Principal']) &lt; 1" />
     </xsl:call-template>

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3358'" />
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle[text()='Principal']) &gt; 1" />
     </xsl:call-template>

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'4376'" />
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle[text()='Secundario']) &gt; 2" />
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:if test="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson[cbc:JobTitle[text() = 'Secundario'] and cac:IdentityDocumentReference/cbc:ID[text() != '']]) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4411'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle[text() = 'Secundario']" />
           <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson[cbc:JobTitle[text() = 'Principal'] and cac:IdentityDocumentReference/cbc:ID[text() != '']]) = 0" />
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
     </xsl:if>
     
     <xsl:apply-templates select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson">
        <xsl:with-param name="root" select="."/>
     </xsl:apply-templates>


     <!-- DATOS DEL TRASLADO -->

     <!-- Fecha Inicio de traslado -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'3406'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
        <xsl:with-param name="descripcion" select="'Fecha de inicio de traslado'"/>        
     </xsl:call-template>
  
     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate">                
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3343'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="expresion" select="number(translate(cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate,'-','')) &lt; number(translate(cbc:IssueDate,'-',''))" />
           <xsl:with-param name="descripcion" select="'Fecha de inicio de traslado'"/>
        </xsl:call-template>
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3407'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
           <xsl:with-param name="descripcion" select="'Fecha de inicio de traslado'"/>
        </xsl:call-template>            
     </xsl:if>
     
     <!-- Peso bruto -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'2880'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:GrossWeightMeasure"/>
     </xsl:call-template>
     
     <xsl:call-template name="validateValueThreeDecimalIfExist">
       <xsl:with-param name="errorCodeValidate" select="'2523'"/>
       <xsl:with-param name="node" select="cac:Shipment/cbc:GrossWeightMeasure"/>
     </xsl:call-template>    
     
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'2881'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:GrossWeightMeasure/@unitCode"/>
     </xsl:call-template>    
         
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'2523'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:GrossWeightMeasure/@unitCode"/>
        <xsl:with-param name="regexp" select="'^(KGM)|(TNE)$'"/>
     </xsl:call-template>

     <!-- Anotacion opcional sobre los bienes a transportar -->
     <xsl:if test="(count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                         or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) &gt; 0) 
               or count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text()='82']]) &gt; 0  ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4429'"/>
           <xsl:with-param name="node" select="cac:DespatchLine/cac:Item/cbc:Description"/>
           <xsl:with-param name="expresion" select="count(cac:DespatchLine[cbc:ID = 0 and cac:Item/cbc:Description[text() != '']]) = 0"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Anotacion sobre los bienes a transportar'"/>
        </xsl:call-template>  
     </xsl:if>

     <xsl:if test="(count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '04'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                         or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) &gt; 0) 
               or count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '03' or text()='12' or text()='48']]) &gt; 0  ">
        
        <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) &gt; 0">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4429'"/>
              <xsl:with-param name="node" select="cac:DespatchLine/cac:Item/cbc:Description"/>
              <xsl:with-param name="expresion" select="count(cac:DespatchLine[cbc:ID = 0 and cac:Item/cbc:Description[text() != '']]) = 0"/>
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="'Anotacion sobre los bienes a transportar'"/>
          </xsl:call-template>  
        </xsl:if>
     </xsl:if>     

     <!-- Indicadores -->
     <xsl:for-each select="cac:Shipment/cbc:SpecialInstructions">

        <xsl:if test="substring(text(),1,6) = 'SUNAT_' ">     
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3388'" />
              <xsl:with-param name="node" select="text()" />
              <xsl:with-param name="expresion" select="text() != 'SUNAT_Envio_IndicadorTransbordoProgramado' and text() != 'SUNAT_Envio_IndicadorRetornoVehiculoEnvaseVacio' and text() != 'SUNAT_Envio_IndicadorRetornoVehiculoVacio' and text() != 'SUNAT_Envio_IndicadorTrasporteSubcontratado'
                                                   and text() != 'SUNAT_Envio_IndicadorPagadorFlete_Remitente' and text() != 'SUNAT_Envio_IndicadorPagadorFlete_Subcontratador' and text() != 'SUNAT_Envio_IndicadorPagadorFlete_Tercero' and text() != 'SUNAT_Envio_IndicadorTrasladoTotal'" />
           </xsl:call-template>
        </xsl:if>          
                 
     </xsl:for-each>  

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorTransbordoProgramado']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTransbordoProgramado']) &gt; 1" />
     </xsl:call-template>     

       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'3344'" />
          <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorTrasladoVehiculoM1L']" />
          <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) &gt; 1" />
       </xsl:call-template>     

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorRetornoVehiculoEnvaseVacio']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorRetornoVehiculoEnvaseVacio']) &gt; 1" />
     </xsl:call-template>     

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorRetornoVehiculoVacio']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorRetornoVehiculoVacio']) &gt; 1" />
     </xsl:call-template>     

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasporteSubcontratado']) &gt; 1" />
     </xsl:call-template>
     
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Remitente']) &gt; 1" />
     </xsl:call-template>     

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Subcontratador']) &gt; 1" />
     </xsl:call-template> 
     
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Tercero']) &gt; 1" />
     </xsl:call-template> 
          
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[substring(text(),1,34) = 'SUNAT_Envio_IndicadorPagadorFlete_']) &gt; 1" />
     </xsl:call-template> 


     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'4388'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Remitente']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Subcontratador']) = 0 
                                             and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Tercero']) = 0" />
        <xsl:with-param name="isError" select ="false()"/> 
     </xsl:call-template> 

     <!-- Tipo de evento -->
     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:TransportEvent/cbc:TransportEventTypeCode != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3374'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransportEvent/cbc:TransportEventTypeCode" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>
 
     <!-- DATOS DE EMPRESA QUE SUBCONTRATA -->

     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasporteSubcontratado']) &gt; 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4425'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Empresa que subcontrata'"/>           
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID/@schemeID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3391'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>   
     </xsl:if>     

     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasporteSubcontratado']) &gt; 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4424'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Empresa que subcontrata'"/>           
        </xsl:call-template>
     </xsl:if>     

     <xsl:if test="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3390'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyIdentification/cbc:ID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template> 
     </xsl:if>      

     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasporteSubcontratado']) &gt; 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4426'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Empresa que subcontrata'"/>           
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName != ''">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4427'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cbc:Information" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4427'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4427'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:LogisticsOperatorParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
     </xsl:if> 
     
     <!-- DATOS DE QUIEN PAGA EL SERVICIO -->
     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Tercero']) &gt; 0">

        <!-- Tipo de documento de identidad-->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4401'"/>
           <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Pagador del servicio'"/>           
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'3399'"/>
           <xsl:with-param name="idCatalogo" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="catalogo" select="'06'"/>
           <xsl:with-param name="descripcion" select="'Pagador del servicio'"/>
        </xsl:call-template>        

        <!-- Numero de documento de identidad-->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4402'"/>
           <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Pagador del servicio'"/>           
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != ''">
        <xsl:choose>
           <xsl:when test="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '1'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3400'"/>
                 <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
              </xsl:call-template>
           </xsl:when>
           <xsl:when test="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3400'"/>
                 <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
              </xsl:call-template>
           </xsl:when>
           <xsl:otherwise>
              <xsl:choose>        	
                 <xsl:when test="string-length(cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &lt; 1 " >
                    <xsl:call-template name="isTrueExpresion">
                       <xsl:with-param name="errorCodeValidate" select="'3400'"/>
                       <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
                       <xsl:with-param name="expresion" select="true()" />
                    </xsl:call-template>
                 </xsl:when>
                 <xsl:otherwise>					
                    <xsl:call-template name="regexpValidateElementIfExist">
                       <xsl:with-param name="errorCodeValidate" select="'3400'"/>
                       <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                       <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/> 
                    </xsl:call-template>        		
                 </xsl:otherwise>
              </xsl:choose>       
           </xsl:otherwise>
        </xsl:choose>
     </xsl:if>     
     
     <!-- Apellidos y nombres, denominacion o razon social de quien paga el servicio-->
     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorPagadorFlete_Tercero']) &gt; 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4370'"/>
           <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
     </xsl:if> 
     <xsl:if test="cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != ''">
        <xsl:choose>          
           <xsl:when test="string-length(cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4423'"/>
                 <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4423'"/>
                 <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4423'"/>
                 <xsl:with-param name="node" select="cac:OriginatorCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
     </xsl:if>    
     
     <xsl:copy-of select="." />
    
  </xsl:template>

  
  <!-- ======================================================================================================================================
    
    ================================================= Template cbc:Note (Observaciones) ======================================================= 
    
    ===========================================================================================================================================
    -->
  <xsl:template match="cbc:Note">
     <xsl:variable name="desNota" select="text()"/>
     <xsl:choose>          
        <xsl:when test="not($desNota) " >
           <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4186'"/>
             <xsl:with-param name="node" select="$desNota" />
             <xsl:with-param name="expresion" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length($desNota) &gt; 250 or string-length($desNota) &lt; 1 " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4186'"/>
             <xsl:with-param name="node" select="$desNota" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>

        <xsl:when test="string-length(translate($desNota,' ','')) = 0 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4186'"/>
              <xsl:with-param name="node" select="$desNota" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>
                      
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4186'"/>
              <xsl:with-param name="node" select="$desNota"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>            
        </xsl:otherwise>
     </xsl:choose>
  </xsl:template>


    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AdditionalDocumentReference ===========================================

    ===========================================================================================================================================
    -->
  <xsl:template match="cac:AdditionalDocumentReference">
     <xsl:param name="root"/>

     <!-- Tipo de documento - Descripcion -->
     <xsl:if test= "cbc:DocumentTypeCode != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4371'"/>
           <xsl:with-param name="node" select="cbc:DocumentType"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>   

     <xsl:if test= "cbc:DocumentType != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4410'"/>
           <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:choose>
        <xsl:when test="string-length(cbc:DocumentType) &gt; 120 or string-length(cbc:DocumentType) &lt; 1 ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4372'" />
              <xsl:with-param name="node" select="cbc:DocumentType" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:when>
        
        <xsl:when test="string-length(translate(cbc:DocumentType,' ','')) = 0 " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4372'"/>
             <xsl:with-param name="node" select="cbc:DocumentType" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
             <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:when>
                
        <xsl:otherwise>				
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4372'"/>
              <xsl:with-param name="node" select="cbc:DocumentType"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>

     <!-- Tipo de documento - Codigo -->
     <xsl:if test= "cbc:DocumentTypeCode != ''">
        <xsl:call-template name="findElementInCatalog61tProperty">
           <xsl:with-param name="catalogo" select="'61'"/>
           <xsl:with-param name="propiedad" select="'gre-t'"/>
           <xsl:with-param name="idCatalogo" select="cbc:DocumentTypeCode"/>
           <xsl:with-param name="valorPropiedad" select="'1'"/>
           <xsl:with-param name="errorCodeValidate" select="'2692'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

      	<xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3403'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Tipo de documento relacionado'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
        <xsl:with-param name="regexp" select="'^(Documento relacionado al transporte)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Tipo de documento relacionado'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4253'"/>
        <xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo61)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Tipo de documento relacionado'"/>
     </xsl:call-template>

     <!-- Numero de documento relacionado -->
     <xsl:if test= "cbc:ID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3340'" />
           <xsl:with-param name="node" select="cbc:ID" />
           <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>        

      	<xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3376'"/>
           <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test= "cbc:DocumentTypeCode = '01'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}|[\d]{1,4}|[E][0][0][1])-(?!0+$)([0-9]{1,8}))$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '03'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(([B][A-Z0-9]{3}|[\d]{1,4}|[E][B][0][1])-(?!0+$)([0-9]{1,8}))$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '04'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(([L][A-Z0-9]{3}|[\d]{1,4}|[E][0][0][1])-(?!0+$)([0-9]{1,8}))$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '09'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(([T][A-Z0-9]{3}|[\d]{1,4}|[E][G][0][1]|[E][G][0][2])-(?!0+$)([0-9]{1,8}))$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '12'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^([a-zA-Z0-9-]{1,20})-([a-zA-Z0-9-]{1,20})$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '48'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^([\d]{1,4})-(?!0+$)([0-9]{1,7})$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>

     <xsl:if test= "cbc:DocumentTypeCode = '80'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9]{1,15})$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>          

     <xsl:if test= "cbc:DocumentTypeCode[text() = '50' or text() = '52']">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{2}-[0-9]{1,6}$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>
      
     <xsl:if test= "cbc:DocumentTypeCode = '31'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(([V][A-Z0-9]{3}|[E][G][0][3]|[E][G][0][4])-(?!0+$)([0-9]{1,8}))$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if>
     
     <xsl:if test= "cbc:DocumentTypeCode[text() = '82' or text() = '65' or text() = '66' or text() = '67' or text() = '68' or text() = '69']">
        <xsl:choose>
           <xsl:when test="string-length(cbc:ID) &gt; 100 or string-length(cbc:ID) &lt; 1 ">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3441'" />
                 <xsl:with-param name="node" select="cbc:ID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:when>
        
           <xsl:otherwise>
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:otherwise>
        </xsl:choose>
     </xsl:if> 
               
     <!-- Numero de RUC del emisor del documento relacionado -->

     <xsl:if test= "cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '31' or text() = '48']">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3380'"/>
           <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>     
     </xsl:if>

     <xsl:if test= "cac:IssuerParty/cac:PartyIdentification/cbc:ID != '' and substring(cbc:ID, 1, 1) != '0' and substring(cbc:ID, 1, 1) != '1' and substring(cbc:ID, 1, 1) != '2' and substring(cbc:ID, 1, 1) != '3' 
                and substring(cbc:ID, 1, 1) != '4' and substring(cbc:ID, 1, 1) != '5' and substring(cbc:ID, 1, 1) != '6' and substring(cbc:ID, 1, 1) != '7' and substring(cbc:ID, 1, 1) != '8' and substring(cbc:ID, 1, 1) != '9' ">
        <xsl:if test= "cbc:DocumentTypeCode = '09' ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test= "cbc:DocumentTypeCode = '31'">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>
     </xsl:if>
     
     <!-- Tipo de documento del emisor del documento relacionado -->
     <xsl:if test= "cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '31' or text() = '48']">
        <xsl:call-template name="existAndRegexpValidateElement">
           <xsl:with-param name="errorCodeNotExist" select="'3382'"/>
           <xsl:with-param name="errorCodeValidate" select="'3382'"/>
           <xsl:with-param name="regexp" select="'^(6)$'"/>
           <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

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
  </xsl:template>
  <!--
  ===========================================================================================================================================

  =========================================== fin Template cac:AdditionalDocumentReference ===========================================

  ===========================================================================================================================================
  -->

    <!--
    ===========================================================================================================================================

    ================= Template cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment ===================

    =========================================   Vehiculos Secundarios =========================================================================
    -->

  <xsl:template match="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment">
     <xsl:param name="root"/>

     <!-- Placa -->
     <xsl:if test="cbc:ID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2567'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{6,8})$'"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>

        <!-- Tarjeta Unica de Circulacion Electronica -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4399'"/>
           <xsl:with-param name="node" select="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>     

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3355'"/>
        <xsl:with-param name="node" select="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
        <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{10,15})$'"/>
        <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
     </xsl:call-template>

     <!-- Autorizacion especial Vehiculo secundario -->

     <xsl:if test="cac:ShipmentDocumentReference/cbc:ID != ''">
        <xsl:choose>          
           <xsl:when test="(string-length(cac:ShipmentDocumentReference/cbc:ID) &gt; 50 or string-length(cac:ShipmentDocumentReference/cbc:ID) &lt; 3) " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID,' - Longitud de autorizacion invalida')"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:ShipmentDocumentReference/cbc:ID,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID,' - Caracteres invalidos')"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4406'"/>
                 <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID,' - Caracteres invalidos')"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose>  
     </xsl:if> 
     
     <xsl:if test="count(cac:ShipmentDocumentReference/cbc:ID[text() != '']) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3356'"/>
           <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="expresion" select="count(cac:ShipmentDocumentReference) &gt; 1"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>     
     </xsl:if>    

     <xsl:if test="cac:ShipmentDocumentReference/cbc:ID != ''">
        <!-- Si existe Numero de Autorizacion especial, debe existir la entidad emisora -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4403'"/>
           <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID/@schemeID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="cac:ShipmentDocumentReference/cbc:ID/@schemeID != ''">

        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'4407'"/>
           <xsl:with-param name="idCatalogo" select="cac:ShipmentDocumentReference/cbc:ID/@schemeID"/>
           <xsl:with-param name="catalogo" select="'D37'"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4405'"/>
           <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>    
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Entidad Autorizadora)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Entidad Autorizadora - Autorizacion vehiculo secundario: ',cbc:ID)"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Entidad Autorizadora - Autorizacion vehiculo secundario: ',cbc:ID)"/>
     </xsl:call-template>
  </xsl:template>

    <!--
    ===========================================================================================================================================

    ====-======================= Template cac:Shipment/cac:ShipmentStage/cac:DriverPerson ======================================================

    =========================================   Conductores Principal y secundarios ===========================================================
    -->
  <xsl:template match="cac:Shipment/cac:ShipmentStage/cac:DriverPerson">
     <xsl:param name="root"/>
   
     
     <xsl:variable name="tipoConductor" select="cbc:JobTitle"/>
     
     <xsl:if test="cbc:JobTitle[ text() = 'Secundario']">
        <xsl:if test="cac:IdentityDocumentReference/cbc:ID != '' ">
           <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3362'" />
               <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID" />
               <xsl:with-param name="expresion" select="count(key('by-conductores',cac:IdentityDocumentReference/cbc:ID )) &gt; 1" />
               <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>            
     </xsl:if>
   
     <!-- Validaciones solo aplican si el tipo de conductor en 'Principal' o 'Secundario' -->
     <xsl:if test="cbc:JobTitle[text() = 'Principal' or text() = 'Secundario']">

        <!-- Existencia de Numero de documento de identidad -->
        <xsl:if test="(cbc:JobTitle[text() = 'Principal']) or (cbc:JobTitle[text() = 'Secundario'] and cac:IdentityDocumentReference/cbc:ID != '') or (cbc:JobTitle[text() = 'Secundario'] and cbc:ID/@schemeID != '')">     
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2568'"/>
              <xsl:with-param name="node" select="cbc:ID"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>

        <!-- Tipo de documento del conductor -->
        <xsl:if test="cbc:JobTitle[text() = 'Principal']">     
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2570'"/>
              <xsl:with-param name="node" select="cbc:ID/@schemeID"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="cbc:JobTitle[text() = 'Secundario'] and cbc:ID != ''">     
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2570'"/>
              <xsl:with-param name="node" select="cbc:ID/@schemeID"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="(cbc:JobTitle[text() = 'Principal']) or (cbc:JobTitle[text() = 'Secundario'] and cbc:ID/@schemeID != '')">     

           <xsl:call-template name="findElementInCatalog">
              <xsl:with-param name="errorCodeValidate" select="'2571'"/>
              <xsl:with-param name="idCatalogo" select="cbc:ID/@schemeID"/>
              <xsl:with-param name="catalogo" select="'06'"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
   
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'2571'" />
              <xsl:with-param name="node" select="cbc:ID/@schemeID" />
              <xsl:with-param name="expresion" select="cbc:ID/@schemeID = '6'" />
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4255'"/>
           <xsl:with-param name="node" select="cbc:ID/@schemeName"/>
           <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Tipo de documento de identidad')"/>
        </xsl:call-template>
   
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4256'"/>
           <xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
           <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Tipo de documento de identidad')"/>
        </xsl:call-template>
   
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4257'"/>
           <xsl:with-param name="node" select="cbc:ID/@schemeURI"/>
           <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Tipo de documento de identidad')"/>
        </xsl:call-template> 

        <!-- Numero de documento de identidad -->
        <xsl:if test="cbc:ID/@schemeID != ''">
           <xsl:choose>
              <xsl:when test="cbc:ID/@schemeID = '1'">
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2569'"/>
                    <xsl:with-param name="node" select="cbc:ID"/>
                    <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Numero de documento de identidad')"/>
                 </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                 <xsl:choose>        	
                    <xsl:when test="string-length(cbc:ID) &gt; 15 or string-length(cbc:ID) &lt; 1 " >
                       <xsl:call-template name="isTrueExpresion">
                          <xsl:with-param name="errorCodeValidate" select="'2569'"/>
                          <xsl:with-param name="node" select="cbc:ID" />
                          <xsl:with-param name="expresion" select="true()" />
                          <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Numero de documento de identidad')"/>
                       </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>					
                       <xsl:call-template name="regexpValidateElementIfExist">
                          <xsl:with-param name="errorCodeValidate" select="'2569'"/>
                          <xsl:with-param name="node" select="cbc:ID"/>
                          <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/>
                          <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Numero de documento de identidad')"/> 
                       </xsl:call-template> 
                    </xsl:otherwise>
                 </xsl:choose>       
              </xsl:otherwise>
           </xsl:choose>
        </xsl:if>     

        <xsl:if test="(cbc:JobTitle[text() = 'Principal']) or (cbc:JobTitle[text() = 'Secundario'] and cac:IdentityDocumentReference/cbc:ID != '')">        
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'3360'"/>
              <xsl:with-param name="node" select="cbc:FirstName"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
   
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'3361'"/>
              <xsl:with-param name="node" select="cbc:FamilyName"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="cbc:FirstName != ''">
           <xsl:choose>          
              <xsl:when test="(string-length(cbc:FirstName) &gt; 250 or string-length(cbc:FirstName) &lt; 1) " >
                 <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FirstName" />
                    <xsl:with-param name="expresion" select="true()" />
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres')"/>
                 </xsl:call-template>
              </xsl:when>
           
              <xsl:when test="string-length(translate(cbc:FirstName,' ','')) = 0 " >
                 <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                   <xsl:with-param name="node" select="cbc:FirstName" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="isError" select="false()"/>
                   <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres')"/>
                 </xsl:call-template>
              </xsl:when>
                 
              <xsl:otherwise>          
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FirstName"/>
                    <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres')"/>
                 </xsl:call-template>            
              </xsl:otherwise>
           </xsl:choose>
        </xsl:if>
        
        <xsl:if test="cbc:FamilyName != ''">          
           <xsl:choose>          
              <xsl:when test="(string-length(cbc:FamilyName) &gt; 250 or string-length(cbc:FamilyName) &lt; 1) " >
                 <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FamilyName" />
                    <xsl:with-param name="expresion" select="true()" />
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos')"/>
                 </xsl:call-template>
              </xsl:when>
           
              <xsl:when test="string-length(translate(cbc:FamilyName,' ','')) = 0 " >
                 <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                   <xsl:with-param name="node" select="cbc:FamilyName" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="isError" select="false()"/>
                   <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos')"/>
                 </xsl:call-template>
              </xsl:when>
                 
              <xsl:otherwise>          
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FamilyName"/>
                    <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos')"/>
                 </xsl:call-template>            
              </xsl:otherwise>
           </xsl:choose>
        </xsl:if>

        <!-- Licencia de conducir-->
        <xsl:if test="cbc:JobTitle[text() = 'Principal'] or (cbc:JobTitle[text() = 'Secundario'] and cbc:ID != '')">     
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2572'"/>
              <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>        
        
        <xsl:if test="cac:IdentityDocumentReference/cbc:ID != ''">
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'2573'"/>
              <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID"/>
              <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{9,10})$'"/>
              <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
           </xsl:call-template>
        </xsl:if>        
     </xsl:if>
  </xsl:template> 
  
  <!--
   ===========================================================================================================================================

   ================================= Template cac:DespatchLine (Lineas de la guia) ===========================================================

   ===========================================================================================================================================
   -->
  <xsl:template match="cac:DespatchLine">
     <xsl:param name="root"/>

     <xsl:variable name="nroLinea" select="cbc:ID"/>
     <xsl:variable name="bienControlado" select="count(cac:Item/cac:AdditionalItemProperty[cbc:NameCode = '7022' and cbc:Value = '1'])"/>
     
     <!-- Numero de linea -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
        <xsl:with-param name="errorCodeValidate" select="'2023'"/>
        <xsl:with-param name="node" select="cbc:ID"/>
        <xsl:with-param name="regexp" select="'^\d{1,4}$'"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/> 
     </xsl:call-template>

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'2752'" />
        <xsl:with-param name="node" select="cbc:ID" />
        <xsl:with-param name="expresion" select="count(key('by-despatchLine-id', number(cbc:ID))) &gt; 1" />
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>

     <xsl:if test="(count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '09'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) = 0)        
               and (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '82']]) = 0) 
               and (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text()='04'] and (substring(cbc:ID, 1, 1) = '0' or substring(cbc:ID, 1, 1) = '1' or substring(cbc:ID, 1, 1) = '2' or substring(cbc:ID, 1, 1) = '3' 
                or substring(cbc:ID, 1, 1) = '4' or substring(cbc:ID, 1, 1) = '5' or substring(cbc:ID, 1, 1) = '6' or substring(cbc:ID, 1, 1) = '7' or substring(cbc:ID, 1, 1) = '8' or substring(cbc:ID, 1, 1) = '9')] ) = 0  
                or count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0)
               and (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '03' or text()='12' or text()='48']]) = 0 or count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0) ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3458'" />
           <xsl:with-param name="node" select="cbc:ID" />
           <xsl:with-param name="expresion" select="cbc:ID = 0" />
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>  
     </xsl:if>


     <!-- VALIDACIONES DE EXISTENCIA DE CAMPOS -->
     <xsl:if test="(count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '12' or text() = '48' or text() = '50' or text() = '52']]) &gt; 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0)
                or (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48' or text() = '50' or text() = '52' or text() = '82']]) = 0 )">

        <!-- Cantidad -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2580'"/>
           <xsl:with-param name="node" select="cbc:DeliveredQuantity"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- Unidad de medida de Cantidad -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
           <xsl:with-param name="node" select="cbc:DeliveredQuantity/@unitCode"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- Descripcion del item -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2781'"/>
           <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="(count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '12' or text() = '48' or text() = '50' or text() = '52']]) &gt; 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0 and $bienControlado &gt; 0)
                or (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48' or text() = '50' or text() = '52' or text() = '82']]) = 0 and $bienControlado &gt; 0)">

        <!-- Codigo producto SUNAT -->
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3372'"/>
           <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <!-- SubPartida arancelaria -->
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3426'" />
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7022']"/>
           <xsl:with-param name="expresion" select="count(cac:Item/cac:AdditionalItemProperty[cbc:NameCode = '7020']) = 0" />
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7022')"/>
        </xsl:call-template>  
     </xsl:if>
              
     <!-- VALIDACIONES DE FORMATO -->
     <!-- Cantidad  -->
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'2780'"/>
        <xsl:with-param name="node" select="cbc:DeliveredQuantity"/>
        <xsl:with-param name="regexp" select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>
     
     <!-- Unidad de medida de la cantidad del bien --> 
     <xsl:if test="cbc:DeliveredQuantity/@unitCode != ''">
        <xsl:if test="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() = '52']]) = 0">		    
           <xsl:call-template name="findElementInCatalog">
              <xsl:with-param name="errorCodeValidate" select="'4320'"/>
              <xsl:with-param name="idCatalogo" select="cbc:DeliveredQuantity/@unitCode"/>
              <xsl:with-param name="catalogo" select="'03'"/>
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() = '52']]) &gt; 0">		    
           <xsl:call-template name="findElementInCatalog">
              <xsl:with-param name="errorCodeValidate" select="'4320'"/>
              <xsl:with-param name="idCatalogo" select="cbc:DeliveredQuantity/@unitCode"/>
              <xsl:with-param name="catalogo" select="'65'"/>
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
           </xsl:call-template>
        </xsl:if>
     </xsl:if>
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4258'"/>
        <xsl:with-param name="node" select="cbc:DeliveredQuantity/@unitCodeListID"/>
        <xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4259'"/>
        <xsl:with-param name="node" select="cbc:DeliveredQuantity/@unitCodeListAgencyName"/>
        <xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>
      
     <!-- Descripcion detallada del bien --> 
     <xsl:if test="cbc:ID != 0 and cac:Item/cbc:Description">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Item/cbc:Description) &gt; 500 or string-length(cac:Item/cbc:Description) &lt; 3 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4084'"/>
                <xsl:with-param name="node" select="cac:Item/cbc:Description" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>
           </xsl:when>
   
           <xsl:when test="string-length(translate(cac:Item/cbc:Description,' ','')) = 0 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4084'"/>
                <xsl:with-param name="node" select="cac:Item/cbc:Description" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>
           </xsl:when>
              
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4084'"/>
                 <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose>       
     </xsl:if>   

     <!-- Anotacion generica del bien --> 
     <xsl:if test="cbc:ID = 0 and cac:Item/cbc:Description != ''">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Item/cbc:Description) &gt; 500 or string-length(cac:Item/cbc:Description) &lt; 3 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4430'"/>
                <xsl:with-param name="node" select="cac:Item/cbc:Description" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>
           </xsl:when>
   
           <xsl:when test="string-length(translate(cac:Item/cbc:Description,' ','')) = 0 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4430'"/>
                <xsl:with-param name="node" select="cac:Item/cbc:Description" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>
           </xsl:when>
              
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4430'"/>
                 <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose>       
     </xsl:if>   
     
     <!-- Codigo del bien --> 
     <xsl:if test="cac:Item/cac:SellersItemIdentification/cbc:ID ">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Item/cac:SellersItemIdentification/cbc:ID) &gt; 30 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'4085'"/>
                <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID" />
                <xsl:with-param name="regexp" select="true()" />
                <xsl:with-param name="isError" select="false()"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>
           </xsl:when>
             
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4085'"/>
                 <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{0,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
     </xsl:if>

     <!-- Codigo de producto SUNAT --> 

     <xsl:if test="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != '' ">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3002'"/>
           <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9]{1,8})$'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'3373'"/>
           <xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
           <xsl:with-param name="catalogo" select="'25'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>        

        <xsl:if test="$bienControlado &gt; 0">
           <xsl:call-template name="findElementInCatalog">
              <xsl:with-param name="errorCodeValidate" select="'3425'"/>
              <xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
              <xsl:with-param name="catalogo" select="'62A'"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
           </xsl:call-template>        
        </xsl:if>
     </xsl:if>      
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4254'"/>
        <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID"/>
        <xsl:with-param name="regexp" select="'^(UNSPSC)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea,' Codigo de producto SUNAT ')"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(GS1 US)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea,' Codigo de producto SUNAT ')"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>
        <xsl:with-param name="regexp" select="'^(Item Classification)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea,' Codigo de producto SUNAT ')"/>
     </xsl:call-template>

     <!-- Codigo GTIN -->
     <xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID != '' ">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3375'"/>
           <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^([0-9A-Za-z]{1,14})$'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4335'"/>
        <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
        <xsl:with-param name="regexp" select="'^(GTIN-8|GTIN-12|GTIN-13|GTIN-14)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>

     <!-- Datos adicionales de linea -->
     <xsl:if test="(count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '12' or text() = '48' or text() = '50' or text() = '52']]) &gt; 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotal']) = 0)
                or (count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48' or text() = '50' or text() = '52' or text() = '82']]) = 0 )">
        
        <xsl:if test="$bienControlado &gt; 0 ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3426'"/>
              <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7022']"/>
              <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7020'])"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7022')"/>
           </xsl:call-template>             

        </xsl:if>        
     </xsl:if>

     <xsl:if test="$bienControlado &gt; 0 and count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48' or text() = '50' or text() = '52' or text() = '82']]) = 0 ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3379'"/>
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7022']"/>
           <xsl:with-param name="expresion" select="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '80']]) = 0"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7022')"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:with-param name="nroLinea" select="$nroLinea"/>
        <xsl:with-param name="root" select="$root"/>
        <xsl:with-param name="bienControlado" select="$bienControlado"/>
     </xsl:apply-templates>

  </xsl:template>

  <!--
   ===========================================================================================================================================

   ================================= Template cac:AdditionalItemProperty (Propiedades adicionales) ============================

   ===========================================================================================================================================
   -->  
  <xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
     <xsl:param name="nroLinea"/>
     <xsl:param name="root"/>
     <xsl:param name="bienControlado"/>

     <xsl:if test="cbc:Name">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4235'"/>
           <xsl:with-param name="node" select="cbc:Name"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cbc:NameCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
     </xsl:call-template>
        
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cbc:NameCode/@listName"/>
        <xsl:with-param name="regexp" select="'^(Propiedad del item)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
     </xsl:call-template>
        
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4253'"/>
        <xsl:with-param name="node" select="cbc:NameCode/@listURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
     </xsl:call-template>
    
     <xsl:if test="cbc:NameCode[text() = '7020' or text()='7022']">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
           <xsl:with-param name="node" select="cbc:Value"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
        </xsl:call-template>
     </xsl:if>                                                                                    

     <xsl:if test="cbc:NameCode = '7020'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3377'"/>
           <xsl:with-param name="node" select="cbc:Value"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9]{1,10})$'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
        </xsl:call-template>

        
        <xsl:if test="$bienControlado &gt; 0">
           <xsl:call-template name="findElementInCatalog">
              <xsl:with-param name="errorCodeValidate" select="'3429'"/>
              <xsl:with-param name="idCatalogo" select="cbc:Value"/>
              <xsl:with-param name="catalogo" select="'62'"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
           </xsl:call-template>                                                                              
        </xsl:if>                                                                                    
     </xsl:if>
     
     <xsl:if test="cbc:NameCode = '7022'">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3396'"/>
           <xsl:with-param name="node" select="cbc:Value"/>
           <xsl:with-param name="expresion" select="cbc:Value != '0' and cbc:Value != '1'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
        </xsl:call-template>                            
       
     </xsl:if>  
     
 </xsl:template>
        
</xsl:stylesheet>
