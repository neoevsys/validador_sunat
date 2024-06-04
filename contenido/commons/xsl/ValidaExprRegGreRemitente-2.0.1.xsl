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
  
  <!-- key Numero de contenedores duplicados -->  
  <xsl:key name="by-contenedores" match="*[local-name()='DespatchAdvice']/cac:Shipment/cac:TransportHandlingUnit/cac:Package" use="cbc:ID"/>

  <!-- key Numero de precintos duplicados -->  
  <xsl:key name="by-precintos" match="*[local-name()='DespatchAdvice']/cac:Shipment/cac:TransportHandlingUnit/cac:Package" use="cbc:TraceID"/>

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
	 
 
     <xsl:variable name="motivoTraslado" select="cac:Shipment/cbc:HandlingCode"/>
     <xsl:variable name="tipdocDestinatario" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
     <xsl:variable name="numdocDestinatario" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
     <xsl:variable name="numdocRemitente" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>     
     <xsl:variable name="modalidadTraslado" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode"/>
     
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
        <xsl:with-param name="regexp" select="'^[T][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
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
        <xsl:with-param name="regexp" select="'^(09)$'"/>
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

     
     <!--  Datos del remitente -->    
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
        <xsl:with-param name="descripcion" select="'Documento de identidad - Remitente'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Documento de identidad - Remitente'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4257'"/>
        <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Documento de identidad - Remitente'"/>
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
              <xsl:with-param name="descripcion" select="concat(' cbc:RegistrationName ', cbc:RegistrationName)"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(translate(cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'4338'"/>
              <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="expresion" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>				
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4338'"/>
              <xsl:with-param name="node" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>

     <xsl:if test="count(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID[text() != '']) &gt; 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3353'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID[text() != '']"/>
           <xsl:with-param name="expresion" select="count(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:AgentParty/cac:PartyLegalEntity) &gt; 1"/>
           <xsl:with-param name="descripcion" select="'Existe mas de una Autorizacion del remitente'"/>
        </xsl:call-template>     
     </xsl:if>     

     <!-- Autorizaciones especiales Remitente -->
     <xsl:apply-templates select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:AgentParty/cac:PartyLegalEntity"/>

     <!-- DATOS DEL DESTINATARIO -->
     <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'2757'"/>
       <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
     </xsl:call-template>  

     <xsl:call-template name="existElement">
       <xsl:with-param name="errorCodeNotExist" select="'2759'"/>
       <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
     </xsl:call-template>  

		 <xsl:call-template name="findElementInCatalog">
		    <xsl:with-param name="errorCodeValidate" select="'2760'"/>
		    <xsl:with-param name="idCatalogo" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
        <xsl:with-param name="catalogo" select="'06'"/>
		 </xsl:call-template>

     <xsl:if test="$motivoTraslado[text() = '06' or text() = '17']">
        <xsl:if test="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'"> 
           <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3417'" />
           <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
           <xsl:with-param name="expresion" select="true()" />
         </xsl:call-template>
       </xsl:if>
     </xsl:if>

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

     <xsl:if test="$motivoTraslado[text() = '02' or text() = '04' or text() = '07']">
        <xsl:if test="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6' or ($numdocDestinatario != $numdocRemitente)"> 
           <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'2554'" />
           <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="expresion" select="true()" />
         </xsl:call-template>
       </xsl:if>
     </xsl:if>
     
     <xsl:if test="$motivoTraslado[text() = '01' or text() = '03' or text() = '05' or text() = '06' or text() = '09' or text() = '14' or text() = '17']">
       <xsl:if test="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6' and ($numdocDestinatario = $numdocRemitente)"> 
         <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'2555'" />
           <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="expresion" select="true()" />
         </xsl:call-template>
       </xsl:if>
     </xsl:if>  
 
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
   
   
     <!--  Datos del Proveedor -->
     <xsl:if test="$motivoTraslado[text() = '02' or text() = '07']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4375'" />
           <xsl:with-param name="node" select="cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="expresion" select="count(cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID[text() != '']) = 0" />
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
     </xsl:if>     
     
     <xsl:apply-templates select="cac:SellerSupplierParty">
        <xsl:with-param name="root" select="."/>
        <xsl:with-param name="motivoTraslado" select="$motivoTraslado"/>
     </xsl:apply-templates>


     <!--  Datos del Comprador -->     
     <!-- Tipo de documento del Comprador -->
     <xsl:if test="$motivoTraslado[text() = '03' or text() = '13']"> 
        <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != ''">
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'3331'"/>
              <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           </xsl:call-template>  
        </xsl:if>  

        <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != ''">
		       <xsl:call-template name="findElementInCatalog">
		          <xsl:with-param name="errorCodeValidate" select="'3332'"/>
		          <xsl:with-param name="idCatalogo" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
              <xsl:with-param name="catalogo" select="'06'"/>
		       </xsl:call-template>
        </xsl:if> 

     </xsl:if>       

     <xsl:if test="$motivoTraslado[text() != '03' and text() != '13']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4377'"/>
           <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="expresion" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != ''" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Tipo de documento de identidad del comprador'"/>
        </xsl:call-template>
     </xsl:if> 
          
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Comprador - Tipo de documento de identidad'"/>
     </xsl:call-template>
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
    </xsl:call-template>
    <xsl:call-template name="regexpValidateElementIfExist">
       <xsl:with-param name="errorCodeValidate" select="'4257'"/>
       <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
       <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
       <xsl:with-param name="isError" select ="false()"/>
       <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
    </xsl:call-template>

    <!-- Numero de documento del Comprador -->
    <xsl:if test="$motivoTraslado= '03'">
       <xsl:call-template name="isTrueExpresion">
          <xsl:with-param name="errorCodeValidate" select="'4378'"/>
          <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
          <xsl:with-param name="expresion" select="count(cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID[text() != '']) &lt; 1" />
          <xsl:with-param name="isError" select ="false()"/>
       </xsl:call-template>
    </xsl:if> 

    <xsl:if test="$motivoTraslado[text() = '03' or text() = '13'] and (cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '' or cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != '')">
       <xsl:call-template name="existElement">
          <xsl:with-param name="errorCodeNotExist" select="'3333'"/>
          <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
       </xsl:call-template>
    </xsl:if> 

     <xsl:if test="$motivoTraslado[text() != '03' and text() != '13'] and (cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != '')">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4377'"/>
           <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="expresion" select="true()" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Numero de documento de identidad del comprador'"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="$motivoTraslado = '03' and cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != ''">
        <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6' and (cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID)"> 
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3334'" />
              <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="true()" />
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID and cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID = cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"> 
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3335'" />
              <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="true()" />
           </xsl:call-template>
        </xsl:if>
     </xsl:if>

    <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != ''">
       <xsl:choose>
          <xsl:when test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '1'">
             <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'3337'"/>
                <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
             </xsl:call-template>
          </xsl:when>
          <xsl:when test="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">        
             <xsl:call-template name="regexpValidateElementIfExist">
                <xsl:with-param name="errorCodeValidate" select="'3337'"/>
                <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
             </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
             <xsl:choose>        	
                <xsl:when test="string-length(cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID) &lt; 1 " >
                   <xsl:call-template name="regexpValidateElementIfExist">
                      <xsl:with-param name="errorCodeValidate" select="'3337'"/>
                      <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
                      <xsl:with-param name="regexp" select="true()" />
                   </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>					
                   <xsl:call-template name="regexpValidateElementIfExist">
                      <xsl:with-param name="errorCodeValidate" select="'3337'"/>
                      <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                      <xsl:with-param name="regexp" select="'^[^\s]{1,}$'"/> 
                   </xsl:call-template>        		
                </xsl:otherwise>
             </xsl:choose>       
          </xsl:otherwise>                                                                                
        </xsl:choose> 
     </xsl:if>
     
     <!-- Nombre del Comprador -->
     <xsl:if test="$motivoTraslado = '03' and cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3339'"/>
           <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
        </xsl:call-template>

     </xsl:if>
 
     <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != ''">
        <xsl:choose>          
           <xsl:when test="string-length(cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 1 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4381'"/>
                 <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select ="false()"/>
                 <xsl:with-param name="descripcion" select="'Nombre/Razon del comprador - Longitud invalida'"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4381'"/>
                 <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Nombre/Razon del comprador - Caracteres invalidos'"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">             
                 <xsl:with-param name="errorCodeValidate" select="'4381'"/>
                 <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
                 <xsl:with-param name="isError" select ="false()"/>
                 <xsl:with-param name="descripcion" select="'Nombre/Razon del comprador - Caracteres invalidos'"/>
              </xsl:call-template>
           </xsl:otherwise>                                                                   
        </xsl:choose>  
     </xsl:if>
          
     <xsl:if test="$motivoTraslado[text() != '03' and text() != '13'] and cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != '' ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4377'"/>
           <xsl:with-param name="node" select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
           <xsl:with-param name="expresion" select="true()" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Nombre/Razon del comprador'"/>
        </xsl:call-template>
     </xsl:if>    
     
     <!-- Documentos Relacionados -->  

     <xsl:if test="$motivoTraslado[text() = '08' or text() = '09']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3440'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() = '52']]) = 0" />
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3445'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() != '09' and text() != '49' and text() != '50' and text() != '52' and text() != '80']]) &gt; 0" />
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="$motivoTraslado[text() != '08' and text() != '09' and text() != '13']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3445'"/>
           <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode" />
           <xsl:with-param name="expresion" select="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() = '52']]) &gt; 0" />
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="count(cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '49' or text() = '80']]) > 0">
        <xsl:if test="count(cac:Shipment[cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']]) = 0">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3352'" />
              <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode" />
              <xsl:with-param name="expresion" select="count(cac:DespatchLine[cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7020']]) = 0" />
           </xsl:call-template>
        </xsl:if>
     </xsl:if>
     
     <xsl:apply-templates select="cac:AdditionalDocumentReference">
        <xsl:with-param name="root" select="."/>
        <xsl:with-param name="motivoTraslado" select="$motivoTraslado"/>
     </xsl:apply-templates>


     <!-- Datos del Envio -->

     <!-- Motivo de traslado -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'3404'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode"/>
     </xsl:call-template>

     <xsl:call-template name="findElementInCatalog">
		    <xsl:with-param name="errorCodeValidate" select="'3405'"/>
		    <xsl:with-param name="idCatalogo" select="cac:Shipment/cbc:HandlingCode"/>
        <xsl:with-param name="catalogo" select="'20'"/>
		 </xsl:call-template>
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode/@listName"/>
         <xsl:with-param name="regexp" select="'^(Motivo de traslado)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4253'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingCode/@listURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <!-- Descripcion de motivo de traslado -->

     <xsl:if test="$motivoTraslado = '13'">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3457'"/>
           <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingInstructions"/>
        </xsl:call-template>

        <xsl:variable name="alfabeto" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚáéíóú'"/>
        <xsl:variable name="cadena" select="cac:Shipment/cbc:HandlingInstructions"/>
        
        <xsl:choose>          
           <xsl:when test="string-length(cac:Shipment/cbc:HandlingInstructions) &gt; 100 or string-length(cac:Shipment/cbc:HandlingInstructions) &lt; 3 ">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4190'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingInstructions" />
                 <xsl:with-param name="regexp" select="true()" />
                 <xsl:with-param name="isError" select ="false()"/>
                 <xsl:with-param name="descripcion" select="'Longitud errada'"/>
              </xsl:call-template>
           </xsl:when>
           <xsl:when test="(string-length($cadena) - string-length(translate($cadena, $alfabeto, ''))) &lt; 3">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4190'" />
                 <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingInstructions" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select ="false()"/>
                 <xsl:with-param name="descripcion" select="'No contiene 3 caracteres alfabeticos'"/>                 
              </xsl:call-template> 
           </xsl:when>                      
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4190'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cbc:HandlingInstructions"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
                 <xsl:with-param name="isError" select ="false()"/>
                 <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>                 
              </xsl:call-template>
           </xsl:otherwise>                                                                   
        </xsl:choose>  
     </xsl:if>

     <!-- Peso bruto total de los items seleccionados -->
     <xsl:if test="($motivoTraslado[text() = '08' or text() = '09'] and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4383'"/>
           <xsl:with-param name="node" select="cac:Shipment/cbc:NetWeightMeasure"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Campo cac:Shipment/cbc:NetWeightMeasure'"/>
        </xsl:call-template>
     </xsl:if>   

     <xsl:if test="$motivoTraslado[text() != '08' and text() != '09'] and cac:Shipment/cbc:NetWeightMeasure">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3395'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:NetWeightMeasure"/>
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>
      
     <xsl:call-template name="validateValueThreeDecimalIfExist">
       <xsl:with-param name="errorCodeValidate" select="'3397'"/>
       <xsl:with-param name="node" select="cac:Shipment/cbc:NetWeightMeasure"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3398'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:NetWeightMeasure/@unitCode"/>
        <xsl:with-param name="regexp" select="'^(KGM)$'"/>
     </xsl:call-template>     

     <!-- Sustento de diferencia de Peso bruto total -->
     <xsl:if test="($motivoTraslado[text() = '08' or text() = '09'] and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4387'"/>
           <xsl:with-param name="node" select="cac:Shipment/cbc:Information"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Campo cac:Shipment/cbc:Information'"/>
        </xsl:call-template>
     </xsl:if>      

     <xsl:if test="$motivoTraslado[text() != '08' and text() != '09'] and cac:Shipment/cbc:Information">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3418'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:Information"/>
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>      

     <xsl:if test="cac:Shipment/cbc:Information">
        <xsl:choose>          
           <xsl:when test="string-length(cac:Shipment/cbc:Information) &gt; 250 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4428'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cbc:Information" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:Shipment/cbc:Information,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4428'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cbc:Information" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4428'"/>
                 <xsl:with-param name="node" select="text()"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
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
    
     <!-- Numero de bultos o pallets -->
     <xsl:variable name="motivoTraslado" select="cac:Shipment/cbc:HandlingCode"/>
     <xsl:if test="($motivoTraslado = '08' or $motivoTraslado = '09') and count(cac:Shipment/cac:TransportHandlingUnit/cac:Package/cbc:ID[text() != '']) = 0 ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3419'"/>
           <xsl:with-param name="node" select="cac:Shipment/cbc:TotalTransportHandlingUnitQuantity"/>
        </xsl:call-template> 
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4384'"/>
        <xsl:with-param name="node" select="cac:Shipment/cbc:TotalTransportHandlingUnitQuantity"/>
        <xsl:with-param name="regexp" select="'^([0-9]{1,6})$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <!-- Numero de contenedor -->
     <xsl:if test="($motivoTraslado = '08' or $motivoTraslado = '09') and count(cac:Shipment/cac:TransportHandlingUnit/cac:Package/cbc:ID[text() != '']) &gt; 2 ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3420'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:Package/cbc:ID" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>

     <xsl:for-each select="cac:Shipment/cac:TransportHandlingUnit/cac:Package">
        <xsl:if test="cbc:ID != '' ">
           <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3421'" />
               <xsl:with-param name="node" select="cbc:ID" />
               <xsl:with-param name="expresion" select="count(key('by-contenedores',cbc:ID )) &gt; 1" />
               <xsl:with-param name="descripcion" select="concat('Contenedor : ', cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>   

        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4071'"/>
           <xsl:with-param name="node" select="cbc:ID"/>                      
           <xsl:with-param name="regexp" select="'^([0-9A-Za-z]{1,11})$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="concat('Contenedor : ', cbc:ID)"/>
        </xsl:call-template>                                      

        <!-- Precintos -->
        <xsl:if test="($motivoTraslado = '08' or $motivoTraslado = '09') and cbc:ID != ''">
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'3422'"/>
              <xsl:with-param name="node" select="cbc:TraceID"/>
           </xsl:call-template> 
        </xsl:if>
        
        <xsl:if test="cbc:TraceID != '' ">
           <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3423'" />
               <xsl:with-param name="node" select="cbc:TraceID" />
               <xsl:with-param name="expresion" select="count(key('by-precintos',cbc:TraceID )) &gt; 1" />
               <xsl:with-param name="descripcion" select="concat('Precinto : ', cbc:TraceID)"/>
           </xsl:call-template>
        </xsl:if>   
        
        <xsl:if test="$motivoTraslado = '08' or $motivoTraslado = '09'">
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4074'"/>
              <xsl:with-param name="node" select="cbc:TraceID"/>
              <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Za-z]{1,20})$'"/>
              <xsl:with-param name="isError" select ="false()"/>
           </xsl:call-template>
        </xsl:if>
             
     </xsl:for-each>
    
     <!-- Modalidad de traslado -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2532'"/>
        <xsl:with-param name="errorCodeValidate" select="'2773'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode"/>
        <xsl:with-param name="regexp" select="'^(01|02)$'"/>      
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode/@listName"/>
         <xsl:with-param name="regexp" select="'^(Modalidad de traslado)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4253'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode/@listURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo18)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>
     
     <!-- Fecha Inicio de traslado -->
     <xsl:if test="$modalidadTraslado = '02' or ($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1) or 
                  ($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3406'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3407'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
        </xsl:call-template>   
                
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3343'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="expresion" select="number(translate(cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate,'-','')) &lt; number(translate(cbc:IssueDate,'-',''))" />
        </xsl:call-template>
           
     </xsl:if>

     <!-- Fecha entrega de bienes al transportista -->
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0) and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4385'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3407'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4386'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate" />
           <xsl:with-param name="expresion" select="number(translate(cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate,'-','')) &lt; number(translate(cbc:IssueDate,'-',''))" />
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>

     </xsl:if>

     <!-- Indicadores -->

     <xsl:for-each select="cac:Shipment/cbc:SpecialInstructions">

        <xsl:if test="substring(text(),1,6) = 'SUNAT_' ">     
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3388'" />
              <xsl:with-param name="node" select="text()" />
              <xsl:with-param name="expresion" select="text() != 'SUNAT_Envio_IndicadorTransbordoProgramado' and text() != 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L' and text() != 'SUNAT_Envio_IndicadorRetornoVehiculoEnvaseVacio' 
                                                   and text() != 'SUNAT_Envio_IndicadorRetornoVehiculoVacio' and text() != 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS' and text() != 'SUNAT_Envio_IndicadorVehiculoConductoresTransp'" />
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
          <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) &gt; 1" />
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
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) &gt; 1" />
     </xsl:call-template>
     
     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'3344'" />
        <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
        <xsl:with-param name="expresion" select="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) &gt; 1" />
     </xsl:call-template>     

     <xsl:if test="($motivoTraslado != '08' and $motivoTraslado != '09') and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 1">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3392'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>
     
     <xsl:if test="$motivoTraslado = '08' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4437'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']" />
           <xsl:with-param name="expresion" select="true()" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Indicador SUNAT_Envio_IndicadorTrasladoTotalDAMoDS'"/>           
        </xsl:call-template>
     </xsl:if>     

     <xsl:if test="$modalidadTraslado = '02' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3450'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>   

     <xsl:if test="$modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3451'" />
           <xsl:with-param name="node" select="cac:Shipment/cbc:SpecialInstructions[text()='SUNAT_Envio_IndicadorVehiculoConductoresTransp']" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>   


     <!-- Tipo de evento -->
     <xsl:if test="cac:Shipment/cac:ShipmentStage/cac:TransportEvent/cbc:TransportEventTypeCode != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3374'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:TransportEvent/cbc:TransportEventTypeCode" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>

     <!-- Datos del transportista -->

     <!-- Existencia de Tipo de documento y Numero de documento de identidad del transportista -->     
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2558'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>

        <xsl:call-template name="existAndRegexpValidateElement">
           <xsl:with-param name="errorCodeNotExist" select="'2561'"/>
           <xsl:with-param name="errorCodeValidate" select="'2485'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
     </xsl:if>
     
     <!-- Tipo de documento de identidad del transportista -->
     <xsl:if test="$modalidadTraslado = '02' and cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3347'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
         <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4257'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/cbc:ID/@schemeURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>     
     
     <!-- Numero de documento de identidad del transportista -->     
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)">
       <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'2560'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="expresion" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
     </xsl:if>                         

     <xsl:if test="$modalidadTraslado = '02' and cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3347'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>

     <!-- Nombre del transportista -->
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2563'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
        </xsl:call-template>

        <xsl:choose>          
           <xsl:when test="(string-length(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 3) " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4165'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>

           <xsl:when test="string-length(translate(cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4165'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName" />
                 <xsl:with-param name="expresion" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>
           </xsl:when>
           
           <xsl:otherwise>          
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4165'"/>
                 <xsl:with-param name="node" select="text()"/>
                 <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
                 <xsl:with-param name="isError" select="false()"/>
              </xsl:call-template>            
           </xsl:otherwise>
        </xsl:choose> 
     </xsl:if> 

     <xsl:if test="$modalidadTraslado = '02' and cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3347'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName" />
           <xsl:with-param name="expresion" select="true()" />
        </xsl:call-template>
     </xsl:if>

     <!-- Registro MTC del transportista -->
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)">
        <xsl:call-template name="existAndRegexpValidateElement">
           <xsl:with-param name="errorCodeNotExist" select="'4391'"/>
           <xsl:with-param name="errorCodeValidate" select="'4392'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:CompanyID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{1,20})$'"/>
           <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>     
     </xsl:if>     
     
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
		    </xsl:call-template>

        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4397'"/>
			     <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID"/>
           <xsl:with-param name="isError" select="false()"/>
		    </xsl:call-template>    
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Entidad Autorizadora)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty/cac:AgentParty/cac:PartyLegalEntity/cbc:CompanyID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>


     <!-- VEHICULO PRINCIPAL -->
     <!-- Placa -->
     <xsl:if test="($modalidadTraslado = '02' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0) 
                or ($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2566'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>
     </xsl:if>     

     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3354'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
           <xsl:with-param name="expresion" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID != ''"/>
        </xsl:call-template>
     </xsl:if>  

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2567'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{6,8})$'"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>
     </xsl:if>
     
     <!-- Tarjeta Unica de Circulacion Electronica -->
     <xsl:if test="($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4399'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal'"/>
        </xsl:call-template>
     </xsl:if>     

     <xsl:if test="count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0 and cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3452'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="expresion" select="true()"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal - Tarjeta unica de circulacion'"/>
        </xsl:call-template>
     </xsl:if>  

     <xsl:if test="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3355'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{10,15})$'"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal - Tarjeta unica de circulacion'"/>
        </xsl:call-template>
     </xsl:if>
     
     <!-- Autorizaciones especiales Vehiculo principal -->

     <xsl:if test="(count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1 )
                or ($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3452'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="expresion" select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:ShipmentDocumentReference/cbc:ID != ''"/>
           <xsl:with-param name="descripcion" select="'Vehiculo principal - Autorizacion especial'"/>
        </xsl:call-template>
     </xsl:if>  

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
     </xsl:call-template>

     <xsl:apply-templates select="cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:AttachedTransportEquipment">
        <xsl:with-param name="root" select="."/>
        <xsl:with-param name="modalidadTraslado" select="$modalidadTraslado"/>
     </xsl:apply-templates>      

     <!-- CONDUCTORES PRINCIPAL y SECUNDARIOS -->     
     <xsl:if test="($modalidadTraslado = '02' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)
                or ($modalidadTraslado = '01' and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count(cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3357'" />
              <xsl:with-param name="node" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle" />
              <xsl:with-param name="expresion" select="count(cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:JobTitle[text()='Principal']) &lt; 1" />
           </xsl:call-template>
     </xsl:if>     

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
        <xsl:with-param name="modalidadTraslado" select="$modalidadTraslado"/>
     </xsl:apply-templates>
   
 
     <!-- PUNTO DE PARTIDA --> 

     <!-- Ubigeo de partida -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2775'"/>
        <xsl:with-param name="errorCodeValidate" select="'2776'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
        <xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
        <xsl:with-param name="descripcion" select="'Punto de Partida'"/> 
     </xsl:call-template>            

     <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3363'"/>
				<xsl:with-param name="idCatalogo" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
		 </xsl:call-template>
 
     <!-- Numero deRUC  asociado al punto de partida -->
     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3410'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID"/>
        </xsl:call-template>      
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de Partida - Ubigeo'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de Partida - Ubigeo'"/>
     </xsl:call-template>

     <!-- Direccion completa y detallada de partida -->
     <xsl:call-template name="existElement">
        <xsl:with-param name="errorCodeNotExist" select="'2577'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
     </xsl:call-template>  

     <xsl:choose>          
        <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &gt; 500 or string-length(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line) &lt; 3 " >
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4076'"/>
              <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line" />
              <xsl:with-param name="regexp" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="'Longitud invalida'"/>             
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
 
     <!-- Numero de RUC  asociado al punto de partida -->
     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3410'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID"/>
           <xsl:with-param name="descripcion" select="'Punto de Partida'"/>
        </xsl:call-template>      
     </xsl:if>
     
     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID != '' and $motivoTraslado[text() = '02' or text() = '07' or text() = '08']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3411'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="descripcion" select="'Punto de Partida'"/>
        </xsl:call-template>     
     </xsl:if>     

     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID != '' and $motivoTraslado[text() = '04']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3414'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID != cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="descripcion" select="'Punto de Partida - Establecimiento anexo'"/>
        </xsl:call-template>     
     </xsl:if>     

     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3409'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID"/>
           <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
           <xsl:with-param name="descripcion" select="'Punto de Partida'"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Codigo de establecimiento de punto de partida -->
     <xsl:if test="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listID != '' or $motivoTraslado = '04'">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3365'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode"/>
        </xsl:call-template>      
     </xsl:if>
     
     <xsl:if test="$motivoTraslado = '08' and count(cac:Shipment/cac:FirstArrivalPortLocation[cbc:LocationTypeCode[text() = '1' or text()='2'] and cbc:ID !='']) = 0 and count(cac:Shipment/cac:FirstArrivalPortLocation[cbc:LocationTypeCode[text() = '1' or text()='2'] and cbc:Name != '']) = 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3365'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode" />
           <xsl:with-param name="expresion" select="not(cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode) or cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode = ''" />
        </xsl:call-template>     
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de Partida - Establecimiento anexo'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:AddressTypeCode/@listName"/>
        <xsl:with-param name="regexp" select="'^(Establecimientos anexos)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de Partida - Establecimiento anexo'"/>
     </xsl:call-template>

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
     <xsl:if test="$motivoTraslado != '18'">
        <xsl:call-template name="existAndRegexpValidateElement">
           <xsl:with-param name="errorCodeNotExist" select="'2775'"/>
           <xsl:with-param name="errorCodeValidate" select="'2776'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
           <xsl:with-param name="descripcion" select="'Punto de LLegada'"/> 
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
        <xsl:with-param name="descripcion" select="'Punto de LLegada - Ubigeo'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de LLegada - Ubigeo'"/>
     </xsl:call-template>

     <!-- Direccion completa y detallada de partida -->
     <xsl:if test="$motivoTraslado != '18'">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2574'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
        </xsl:call-template>  
   
        <xsl:choose>          
           <xsl:when test="string-length(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line) &gt; 500 or string-length(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line) &lt; 3 " >
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'4068'"/>
                 <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
                 <xsl:with-param name="regexp" select="true()" />
                 <xsl:with-param name="isError" select="false()"/>
                 <xsl:with-param name="descripcion" select="'Longitud invalida'"/>
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
     
     <!-- Numero de RUC  asociado al punto de llegada -->
     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3410'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID"/>
           <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
        </xsl:call-template>      
     </xsl:if>
     
     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID != '' and $motivoTraslado[text() = '01' or text() = '03' or text() = '05' or text() = '06' or text() = '14' or text() = '17']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3411'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID = cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
        </xsl:call-template>     
     </xsl:if>     

     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID != '' and $motivoTraslado[text() = '04']">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3414'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID != cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
           <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
        </xsl:call-template>     
     </xsl:if>     

     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3409'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID"/>
           <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
           <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Codigo de establecimiento de punto de llegada -->
     <xsl:if test="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listID != '' or $motivoTraslado = '04'">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3369'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode"/>
        </xsl:call-template>      
     </xsl:if>
     
     <xsl:if test="$motivoTraslado = '09' and count(cac:Shipment/cac:FirstArrivalPortLocation[cbc:LocationTypeCode[text() = '1'] and cbc:ID !='']) = 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3369'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode" />
           <xsl:with-param name="expresion" select="not(cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode) or cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode = ''" />
        </xsl:call-template>     
     </xsl:if>

     <xsl:if test="$motivoTraslado = '18'">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3416'" />
           <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode" />
           <xsl:with-param name="expresion" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode != ''" />
        </xsl:call-template>     
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4251'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4252'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:AddressTypeCode/@listName"/>
        <xsl:with-param name="regexp" select="'^(Establecimientos anexos)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Punto de LLegada - Establecimiento anexo'"/>
     </xsl:call-template>

     <!-- Punto de georreferencia de partida -->
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:LocationCoordinate/cbc:LatitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de llegada - Latitud'"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'3413'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cac:LocationCoordinate/cbc:LongitudeDegreesMeasure"/>
        <xsl:with-param name="regexp" select="'^[+\-]?[0-9]{1,3}(\.[0-9]{1,8})?$'"/>
        <xsl:with-param name="descripcion" select="'Georeferencia punto de llegada - Longitud'"/>
     </xsl:call-template>

     <!--Puerto o Aeropuerto de embarque/desembarque -->
     <!-- PUERTO -->
     <xsl:if test="$motivoTraslado[text() = '08' or text() = '09'] and cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '1' ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4413'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
        </xsl:call-template>      

        <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID != ''">
           <xsl:call-template name="findElementInCatalog">
		          <xsl:with-param name="errorCodeValidate" select="'3459'"/>
		          <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
              <xsl:with-param name="catalogo" select="'63'"/>
              <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
		       </xsl:call-template>
        </xsl:if>
    </xsl:if>

     <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '1' ">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4255'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID/@schemeName"/>
           <xsl:with-param name="regexp" select="'^(Puertos)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
        </xsl:call-template>
   
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4257'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID/@schemeURI"/>
           <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo63)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
        </xsl:call-template>       
     </xsl:if>
     
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
     </xsl:call-template>
     
     <xsl:if test="$motivoTraslado[text() = '08' or text() = '09'] and cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID != '' ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4415'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>      

        <xsl:call-template name="isTrueExpresion">
		       <xsl:with-param name="errorCodeValidate" select="'4416'"/>
		       <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode"/>
           <xsl:with-param name="expresion" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode[text() != '1' and text() != '2']"/>
           <xsl:with-param name="isError" select ="false()"/>        
		    </xsl:call-template>
    </xsl:if>
    
    <!-- AEROPUERTO -->     
     <xsl:if test="$motivoTraslado[text() = '08'] and cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '2' ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4413'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Aeropuerto'"/>
        </xsl:call-template>      

        <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID != ''">
           <xsl:call-template name="findElementInCatalog">
		          <xsl:with-param name="errorCodeValidate" select="'3460'"/>
		          <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
              <xsl:with-param name="catalogo" select="'64'"/>
              <xsl:with-param name="descripcion" select="'Codigo de Aeropuerto'"/>
           </xsl:call-template>
        </xsl:if>
    </xsl:if>
     
     <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '2' ">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4255'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID/@schemeName"/>
           <xsl:with-param name="regexp" select="'^(Aeropuertos)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Aeropuerto'"/>
        </xsl:call-template>
   
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'4257'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID/@schemeURI"/>
           <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo64)$'"/>
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Codigo de Aeropuerto'"/>
        </xsl:call-template>       
     </xsl:if>
          
     <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode[text() = '1' or text() ='2'] and cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID != '' ">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4418'"/>
           <xsl:with-param name="node" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:Name"/>
           <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>      
     </xsl:if>     

     <!-- Control del ubigeo del punto de partida vs ubigeo del puerto/aeropuerto -->
     <xsl:if test="$motivoTraslado = '08' and count(cac:Shipment/cac:FirstArrivalPortLocation[cbc:LocationTypeCode[text() = '1' or text()='2'] and cbc:ID !='']) &gt; 0">
        <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '1'">
           <xsl:call-template name="findElementInCatalogGREUbigeoProperty">
              <xsl:with-param name="catalogo" select="'63'"/>
              <xsl:with-param name="propiedad" select="'ubigeo'"/>
              <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
              <xsl:with-param name="valorPropiedad" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
              <xsl:with-param name="errorCodeValidate" select="'3364'"/>
              <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
           </xsl:call-template>
        </xsl:if>
 
        <xsl:if test="cac:Shipment/cac:FirstArrivalPortLocation/cbc:LocationTypeCode = '2'">
           <xsl:call-template name="findElementInCatalogGREUbigeoProperty">
              <xsl:with-param name="catalogo" select="'64'"/>
              <xsl:with-param name="propiedad" select="'ubigeo'"/>
              <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
              <xsl:with-param name="valorPropiedad" select="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
              <xsl:with-param name="errorCodeValidate" select="'3364'"/>
              <xsl:with-param name="descripcion" select="'Codigo de Aeropuerto'"/>
           </xsl:call-template>
        </xsl:if>
     </xsl:if>

     <!-- Control del ubigeo del punto de llegada vs ubigeo del puerto -->
     <xsl:if test="$motivoTraslado = '09' and count(cac:Shipment/cac:FirstArrivalPortLocation[cbc:LocationTypeCode[text() = '1'] and cbc:ID !='']) &gt; 0">
        <xsl:call-template name="findElementInCatalogGREUbigeoProperty">
           <xsl:with-param name="catalogo" select="'63'"/>
           <xsl:with-param name="propiedad" select="'ubigeo'"/>
           <xsl:with-param name="idCatalogo" select="cac:Shipment/cac:FirstArrivalPortLocation/cbc:ID"/>
           <xsl:with-param name="valorPropiedad" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
           <xsl:with-param name="errorCodeValidate" select="'3364'"/>
           <xsl:with-param name="descripcion" select="'Codigo de Puerto'"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Lineas de la guia -->
     <xsl:apply-templates select="cac:DespatchLine">
        <xsl:with-param name="root" select="."/> 
        <xsl:with-param name="motivoTraslado" select="$motivoTraslado"/>
     </xsl:apply-templates>     
     
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
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>            
        </xsl:otherwise>
     </xsl:choose>
  </xsl:template>

  <!--
   ===========================================================================================================================================

   ================================= Template cac:AgentParty (Autorizaciones especiales - Remitente) =========================================

   ===========================================================================================================================================
   -->
  <xsl:template match="cac:Shipment/cac:Delivery/cac:Despatch/cac:DespatchParty/cac:AgentParty/cac:PartyLegalEntity">
     <xsl:choose>          
        <xsl:when test="cbc:CompanyID and (string-length(cbc:CompanyID) &gt; 50 or string-length(cbc:CompanyID) &lt; 3) " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4369'"/>
             <xsl:with-param name="node" select="cbc:CompanyID" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>

        <xsl:when test="string-length(translate(cbc:CompanyID,' ','')) = 0 " >
           <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'4369'"/>
             <xsl:with-param name="node" select="cbc:CompanyID" />
             <xsl:with-param name="regexp" select="true()" />
             <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>
        </xsl:when>
           
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4369'"/>
              <xsl:with-param name="node" select="cbc:CompanyID"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{3,}$'"/> 
              <xsl:with-param name="isError" select="false()"/>
           </xsl:call-template>            
        </xsl:otherwise>
     </xsl:choose>  

     <xsl:if test="cbc:CompanyID != ''">
        <!-- Si existe Numero de Autorizacion especial, debe existir la entidad emisora -->
        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4394'"/>
			     <xsl:with-param name="node" select="cbc:CompanyID/@schemeID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="'Autorizacion especial del remitente'"/>
		    </xsl:call-template>
     </xsl:if>

     <xsl:if test="cbc:CompanyID/@schemeID and cbc:CompanyID/@schemeID != ''">

		    <xsl:call-template name="findElementInCatalog">
			     <xsl:with-param name="errorCodeValidate" select="'4395'"/>
			     <xsl:with-param name="idCatalogo" select="cbc:CompanyID/@schemeID"/>
           <xsl:with-param name="catalogo" select="'D37'"/>
           <xsl:with-param name="isError" select="false()"/>
		    </xsl:call-template>

        <xsl:call-template name="existElement">
			     <xsl:with-param name="errorCodeNotExist" select="'4397'"/>
			     <xsl:with-param name="node" select="cbc:CompanyID"/>
           <xsl:with-param name="isError" select="false()"/>
		    </xsl:call-template>    
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cbc:CompanyID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Entidad Autorizadora)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cbc:CompanyID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
     </xsl:call-template>

  </xsl:template>


  <!--
   ===========================================================================================================================================

   =========================================== Template cac:SellerSupplierParty (Proveedores) ==============================================

   ===========================================================================================================================================
   -->
  <xsl:template match="cac:SellerSupplierParty">
     <xsl:param name="root"/>
     <xsl:param name="motivoTraslado" select = "'-'" />

     <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID != ''">
        <xsl:if test="$motivoTraslado[text() = '02' or text() = '07' or text() = '13']">
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2552'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="$motivoTraslado = '02'">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3447'" />
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
              <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '1' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '4' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '7'" />
           </xsl:call-template>              
        </xsl:if>

        <xsl:if test="$motivoTraslado = '07' ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3447'" />
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
              <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
           </xsl:call-template>              
        </xsl:if>

        <xsl:if test="$motivoTraslado = '13' ">
		       <xsl:call-template name="findElementInCatalog">
		          <xsl:with-param name="errorCodeValidate" select="'3447'"/>
		          <xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
              <xsl:with-param name="catalogo" select="'06'"/>
		       </xsl:call-template>
        </xsl:if>        
     </xsl:if> 

     <xsl:if test="$motivoTraslado[text() != '02' and text() != '07' and text() != '13'] ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4054'"/>
           <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
           <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != ''" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4255'"/>
        <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
        <xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
     </xsl:call-template>
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4256'"/>
        <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
        <xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
     </xsl:call-template>
     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'4257'"/>
        <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
        <xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
        <xsl:with-param name="isError" select ="false()"/>
        <xsl:with-param name="descripcion" select="'Proveedor - Tipo de documento de identidad'"/>
     </xsl:call-template>

     <xsl:if test="$motivoTraslado[text() = '02' or text() = '07' or text() = '13']">
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '' and cac:Party/cac:PartyIdentification/cbc:ID = '' ">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'2723'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
              <xsl:with-param name="expresion" select="true()" />
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName and cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != '' ">
           <xsl:call-template name="existElement">
              <xsl:with-param name="errorCodeNotExist" select="'2723'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
           </xsl:call-template>
        </xsl:if>
     </xsl:if>
     
     <xsl:if test="$motivoTraslado[text() != '02' and text() != '07' and text() != '13'] and cac:Party/cac:PartyIdentification/cbc:ID != '' ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4054'"/>
           <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="expresion" select="true()" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Proveedor - Numero de documento de identidad'"/>
        </xsl:call-template>
     </xsl:if>     

     <xsl:choose>
        <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '1'">
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'2724'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
              <xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">        
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'2724'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
              <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
           <xsl:choose>        	
              <xsl:when test="string-length(cac:Party/cac:PartyIdentification/cbc:ID) &gt; 15 or string-length(cac:Party/cac:PartyIdentification/cbc:ID) &lt; 0 " >
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2724'"/>
                    <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID" />
                    <xsl:with-param name="regexp" select="true()" />
                 </xsl:call-template>
              </xsl:when>                                           
              <xsl:otherwise>					
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'2724'"/>
                    <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
                    <xsl:with-param name="regexp" select="'^[^\s]{0,}$'"/> 
                 </xsl:call-template>        		
              </xsl:otherwise>
           </xsl:choose>       
        </xsl:otherwise>
     </xsl:choose>   
     
     <xsl:if test="$motivoTraslado[text() = '02' or text() = '07'] and cac:Party/cac:PartyIdentification/cbc:ID != ''">
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6' and (cac:Party/cac:PartyIdentification/cbc:ID = $root/cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID)"> 
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3448'" />
              <xsl:with-param name="node" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="true()" />
           </xsl:call-template>
        </xsl:if>

        <xsl:if test="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '12']]) &gt; 0">
           <xsl:variable name="numDocProveedor" select="cac:Party/cac:PartyIdentification/cbc:ID"/>  
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3442'" />
              <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
              <xsl:with-param name="expresion" select="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '12'] and cac:IssuerParty/cac:PartyIdentification/cbc:ID = $numDocProveedor]) &lt; 1"/>
           </xsl:call-template>
        </xsl:if>     
     </xsl:if>

     <xsl:if test="$motivoTraslado[text() = '02' or text() = '07' or text() = '13'] and cac:Party/cac:PartyIdentification/cbc:ID != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3449'"/>
           <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:choose>          
        <xsl:when test="string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &gt; 250 or string-length(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName) &lt; 1 " >
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4106'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="regexp" select="true()" />
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="'Longitud invalida'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(translate(cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,' ','')) = 0 " >
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4106'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName" />
              <xsl:with-param name="regexp" select="true()" />
              <xsl:with-param name="isError" select="false()"/>
              <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
           </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>          
           <xsl:call-template name="regexpValidateElementIfExist">
              <xsl:with-param name="errorCodeValidate" select="'4106'"/>
              <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
              <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/>
              <xsl:with-param name="isError" select ="false()"/>
              <xsl:with-param name="descripcion" select="'Caracteres invalidos'"/>
           </xsl:call-template>
        </xsl:otherwise>
     </xsl:choose>  
     
     <xsl:if test="$motivoTraslado[text() != '02' and text() != '07' and text() != '13'] and cac:Party/cac:PartyLegalEntity/cbc:RegistrationName != '' ">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4054'"/>
           <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
           <xsl:with-param name="expresion" select="true()" />
           <xsl:with-param name="isError" select ="false()"/>
           <xsl:with-param name="descripcion" select="'Proveedor - Nombre/Razon social'"/>
        </xsl:call-template>
     </xsl:if>     

  </xsl:template>



    <!--
    ===========================================================================================================================================

    =========================================== Template cac:AdditionalDocumentReference ===========================================

    ===========================================================================================================================================
    -->
  <xsl:template match="cac:AdditionalDocumentReference">
     <xsl:param name="root"/>
     <xsl:param name="motivoTraslado"/>

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
     </xsl:if>

     <!-- Tipo de documento - Codigo -->
     <xsl:if test= "cbc:DocumentTypeCode != ''">
      	<xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3403'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog61rProperty">
           <xsl:with-param name="catalogo" select="'61'"/>
           <xsl:with-param name="propiedad" select="'gre-r'"/>
           <xsl:with-param name="idCatalogo" select="cbc:DocumentTypeCode"/>
           <xsl:with-param name="valorPropiedad" select="'1'"/>
           <xsl:with-param name="errorCodeValidate" select="'2692'"/>
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

     <xsl:if test= "cbc:DocumentTypeCode = '49'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9]{1,15})$'"/>
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

     <xsl:if test= "cbc:DocumentTypeCode = '81'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3441'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^([a-zA-Z0-9]{1,20})$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
         </xsl:call-template>
     </xsl:if> 

     <xsl:if test= "cbc:DocumentTypeCode[text() = '50']">
        <xsl:choose>
           <xsl:when test= "$motivoTraslado = '08'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-([1][0])-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:when>   
           <xsl:when test= "$motivoTraslado = '09'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-([4][0])-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:when> 
           <xsl:otherwise>
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{2}-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:otherwise> 
        </xsl:choose>
     </xsl:if> 

     <xsl:if test= "cbc:DocumentTypeCode[text() = '52']">
        <xsl:choose>
           <xsl:when test= "$motivoTraslado = '08'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-([1][8])-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:when>   
           <xsl:when test= "$motivoTraslado = '09'">
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-([4][8])-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:when> 
           <xsl:otherwise>
              <xsl:call-template name="regexpValidateElementIfExist">
                 <xsl:with-param name="errorCodeValidate" select="'3441'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{2}-[0-9]{1,6}$'"/>
                 <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
              </xsl:call-template>
           </xsl:otherwise> 
        </xsl:choose>
     </xsl:if>
     
     <xsl:if test= "cbc:DocumentTypeCode[text() = '71' or text() = '72' or text() = '73' or text() = '74' or text() = '75' or text() = '76' or text() = '77' or text() = '78']">
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

     <xsl:if test= "cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48']">
      	<xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3380'"/>
           <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>     
     </xsl:if>

     <xsl:if test= "cac:IssuerParty/cac:PartyIdentification/cbc:ID != ''  ">
        <xsl:if test= "$motivoTraslado[text() = '01' or text() = '03'] and cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '12']">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:if test= "cbc:DocumentTypeCode = '09'">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>
     
        <xsl:if test= "$motivoTraslado = '02' and cbc:DocumentTypeCode[text() = '04' or text() = '48']">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:DespatchSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>     

        <xsl:if test= "$motivoTraslado = '06' and cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '12']">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3381'" />
              <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="expresion" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID != $root/cac:DeliveryCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID" />
              <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
           </xsl:call-template>
        </xsl:if>

        <xsl:call-template name="regexpValidateElementIfExist"> 
           <xsl:with-param name="errorCodeValidate" select="'3409'"/>
           <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID"/>
           <xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
           <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Tipo de documento del emisor del documento relacionado -->
     <xsl:if test= "cbc:DocumentTypeCode[text() = '01' or text() = '03' or text() = '04' or text() = '09' or text() = '12' or text() = '48']">
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
     <xsl:param name="modalidadTraslado" select = "'-'" />  

     <!-- Placa -->
     <xsl:if test="cbc:ID != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4408'"/>
           <xsl:with-param name="node" select="$root/cac:Shipment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
           <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
     </xsl:if>  

     <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3453'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="expresion" select="cbc:ID != ''"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

     <xsl:if test="cbc:ID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2567'"/>
           <xsl:with-param name="node" select="cbc:ID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{6,8})$'"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

     
     <!-- Tarjeta Unica de Circulacion Electronica -->
     <xsl:if test="$modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1 and cbc:ID != ''">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'4399'"/>
           <xsl:with-param name="node" select="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Tarjeta unica circulacion - Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>     

     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0 and cac:ApplicableTransportMeans/cbc:RegistrationNationalityID != ''">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3454'"/>
           <xsl:with-param name="node" select="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="expresion" select="true()"/>
           <xsl:with-param name="descripcion" select="concat('Tarjeta unica circulacion - Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>  

     <xsl:if test="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID != ''">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3355'"/>
           <xsl:with-param name="node" select="cac:ApplicableTransportMeans/cbc:RegistrationNationalityID"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9A-Z]{10,15})$'"/>
           <xsl:with-param name="descripcion" select="concat('Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>

     <!-- Autorizacion especial Vehiculo secundario -->

     <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)  
                or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3454'"/>
           <xsl:with-param name="node" select="cac:ShipmentDocumentReference/cbc:ID"/>
           <xsl:with-param name="expresion" select="cac:ShipmentDocumentReference/cbc:ID != ''"/>
           <xsl:with-param name="descripcion" select="concat('Autorizacion especial - Vehiculo secundario: ',cbc:ID)"/>
        </xsl:call-template>
     </xsl:if>  

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

    =========================== Template cac:Shipment/cac:ShipmentStage/cac:DriverPerson ======================================================

    =========================================   Conductores Principal y secundarios ===========================================================
    -->
  <xsl:template match="cac:Shipment/cac:ShipmentStage/cac:DriverPerson">
     <xsl:param name="root"/>
     <xsl:param name="modalidadTraslado" select = "'-'" />

     <xsl:variable name="tipoConductor" select="cbc:JobTitle"/>
        
     <xsl:if test="cbc:JobTitle[ text() = 'Secundario']">
        <xsl:if test="cac:IdentityDocumentReference/cbc:ID != '' ">
           <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3362'" />
               <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID" />
               <xsl:with-param name="expresion" select="count(key('by-conductores',cac:IdentityDocumentReference/cbc:ID )) &gt; 1" />
           </xsl:call-template>
        </xsl:if>            
     </xsl:if>
   
     <!-- Validaciones solo aplican si el tipo de conductor en 'Principal' o 'Secundario' -->
     <xsl:if test="cbc:JobTitle[text() = 'Principal' or text() = 'Secundario']">
        <!-- Validaci�n de existencia de Tipo de documento del conductor y Numero de documento de identidad del conductor-->
        <xsl:if test="($modalidadTraslado = '02' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">

           <xsl:if test="cbc:JobTitle[text() = 'Principal']">     
              <xsl:call-template name="existElement">
                 <xsl:with-param name="errorCodeNotExist" select="'2568'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
              </xsl:call-template>

              <xsl:call-template name="existElement">
                 <xsl:with-param name="errorCodeNotExist" select="'2570'"/>
                 <xsl:with-param name="node" select="cbc:ID/@schemeID"/>                                         
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
              </xsl:call-template>
           </xsl:if>
           
           <xsl:if test="cbc:JobTitle[text() = 'Secundario'] and (cbc:ID/@schemeID != '' or cac:IdentityDocumentReference/cbc:ID != '')">     
              <xsl:call-template name="existElement">
                 <xsl:with-param name="errorCodeNotExist" select="'2568'"/>
                 <xsl:with-param name="node" select="cbc:ID"/>
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

        </xsl:if>

        
        <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
   
           <xsl:if test="cbc:JobTitle = 'Principal'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3455'" />
                 <xsl:with-param name="node" select="cbc:ID/@schemeID" />
                 <xsl:with-param name="expresion" select="cbc:ID/@schemeID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Tipo de documento de identidad')"/>
              </xsl:call-template>
           </xsl:if>
           
           <xsl:if test="cbc:JobTitle = 'Secundario'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3456'" />
                 <xsl:with-param name="node" select="cbc:ID/@schemeID" />
                 <xsl:with-param name="expresion" select="cbc:ID/@schemeID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Tipo de documento de identidad')"/>
              </xsl:call-template>
           </xsl:if>
        </xsl:if>
   
        <xsl:if test="cbc:ID/@schemeID != ''">
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
   
   
        <!-- Numero de documento de identidad del conductor -->  
        <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
   
           <xsl:if test="cbc:JobTitle = 'Principal'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3455'" />
                 <xsl:with-param name="node" select="cbc:ID" />
                 <xsl:with-param name="expresion" select="cbc:ID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Numero de documento de identidad')"/>
              </xsl:call-template>
           </xsl:if>
           
           <xsl:if test="cbc:JobTitle = 'Secundario'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3456'" />
                 <xsl:with-param name="node" select="cbc:ID" />
                 <xsl:with-param name="expresion" select="cbc:ID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Numero de documento de identidad')"/>
              </xsl:call-template>
           </xsl:if>
        </xsl:if>
   
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
           
        <!-- Apellidos y nombres del conductor -->
   
        <!-- Nombres del conductor -->
        <xsl:if test="($modalidadTraslado = '02' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
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
        </xsl:if>
   
        <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
   
           <xsl:if test="cbc:JobTitle = 'Principal'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3455'" />
                 <xsl:with-param name="node" select="cbc:FirstName" />
                 <xsl:with-param name="expresion" select="cbc:FirstName != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres')"/>
              </xsl:call-template>
           </xsl:if>
   
           <xsl:if test="cbc:JobTitle = 'Principal'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3455'" />
                 <xsl:with-param name="node" select="cbc:FamilyName" />
                 <xsl:with-param name="expresion" select="cbc:FamilyName != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos')"/>
              </xsl:call-template>
           </xsl:if>
           
           <xsl:if test="cbc:JobTitle = 'Secundario'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3456'" />
                 <xsl:with-param name="node" select="cbc:FirstName" />
                 <xsl:with-param name="expresion" select="cbc:FirstName != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres')"/>
              </xsl:call-template>
           </xsl:if>
   
           <xsl:if test="cbc:JobTitle = 'Secundario'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3456'" />
                 <xsl:with-param name="node" select="cbc:FamilyName" />
                 <xsl:with-param name="expresion" select="cbc:FamilyName != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos')"/>
              </xsl:call-template>
           </xsl:if>
   
        </xsl:if>
   
   
        <xsl:if test="cbc:FirstName != ''">
           <xsl:choose>          
              <xsl:when test="(string-length(cbc:FirstName) &gt; 250 or string-length(cbc:FirstName) &lt; 3) " >
                 <xsl:call-template name="isTrueExpresion">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FirstName" />
                    <xsl:with-param name="expresion" select="true()" />
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres - Longitud invalida')"/>
                 </xsl:call-template>
              </xsl:when>
           
              <xsl:when test="string-length(translate(cbc:FirstName,' ','')) = 0 " >
                 <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                   <xsl:with-param name="node" select="cbc:FirstName" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="isError" select="false()"/>
                   <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres - Caracteres invalidos')"/>
                 </xsl:call-template>
              </xsl:when>
                 
              <xsl:otherwise>          
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FirstName"/>
                    <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{2,}$'"/> 
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Nombres - Caracteres invalidos')"/>
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
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos - Longitud invalida')"/>
                 </xsl:call-template>
              </xsl:when>
           
              <xsl:when test="string-length(translate(cbc:FamilyName,' ','')) = 0 " >
                 <xsl:call-template name="isTrueExpresion">
                   <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                   <xsl:with-param name="node" select="cbc:FamilyName" />
                   <xsl:with-param name="expresion" select="true()" />
                   <xsl:with-param name="isError" select="false()"/>
                   <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos - Caracteres invalidos')"/>
                 </xsl:call-template>
              </xsl:when>
                 
              <xsl:otherwise>          
                 <xsl:call-template name="regexpValidateElementIfExist">
                    <xsl:with-param name="errorCodeValidate" select="'4409'"/>
                    <xsl:with-param name="node" select="cbc:FamilyName"/>
                    <xsl:with-param name="regexp" select="'^[^\n\t\r\f]{1,}$'"/> 
                    <xsl:with-param name="isError" select="false()"/>
                    <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Apellidos - Caracteres invalidos')"/>
                 </xsl:call-template>            
              </xsl:otherwise>
           </xsl:choose>
        </xsl:if>
           
        <!-- Numero de licencia de conducir -->
        <xsl:if test="($modalidadTraslado = '02' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 1)">
           <xsl:if test="cbc:JobTitle[text() = 'Principal'] or (cbc:JobTitle[text() = 'Secundario'] and cbc:ID != '')">     
              <xsl:call-template name="existElement">
                 <xsl:with-param name="errorCodeNotExist" select="'2572'"/>
                 <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID"/>
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor)"/>
              </xsl:call-template>
           </xsl:if>
        </xsl:if>
   
        <xsl:if test="(count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 1)
                   or ($modalidadTraslado = '01' and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoVehiculoM1L']) = 0 and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorVehiculoConductoresTransp']) = 0)">
   
           <xsl:if test="cbc:JobTitle = 'Principal'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3455'" />
                 <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="cac:IdentityDocumentReference/cbc:ID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Licencia')"/>
              </xsl:call-template>
           </xsl:if>
   
           <xsl:if test="cbc:JobTitle = 'Secundario'">
              <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3456'" />
                 <xsl:with-param name="node" select="cac:IdentityDocumentReference/cbc:ID" />
                 <xsl:with-param name="expresion" select="cac:IdentityDocumentReference/cbc:ID != ''" />
                 <xsl:with-param name="descripcion" select="concat('Tipo de conductor ',$tipoConductor,' - Licencia')"/>
              </xsl:call-template>
           </xsl:if>
   
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
     <xsl:param name="motivoTraslado" select = "'-'" />
     
     <xsl:variable name="nroLinea" select="cbc:ID"/>
     <xsl:variable name="bienControlado" select="count(cac:Item/cac:AdditionalItemProperty[cbc:NameCode = '7022' and cbc:Value = '1'])"/>
     
     <!-- Numero de linea -->
     <xsl:call-template name="existAndRegexpValidateElement">
        <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
        <xsl:with-param name="errorCodeValidate" select="'2023'"/>
        <xsl:with-param name="node" select="cbc:ID"/>
        <xsl:with-param name="regexp" select="'^\d{1,4}$'"/> 
     </xsl:call-template>

     <xsl:call-template name="isTrueExpresion">
        <xsl:with-param name="errorCodeValidate" select="'2752'" />
        <xsl:with-param name="node" select="cbc:ID" />
        <xsl:with-param name="expresion" select="count(key('by-despatchLine-id', number(cbc:ID))) &gt; 1" />
     </xsl:call-template>

     <!-- Cantidad del bien -->
     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'2580'" />
           <xsl:with-param name="node" select="cbc:DeliveredQuantity" />
           <xsl:with-param name="expresion" select="not(cbc:DeliveredQuantity) or cbc:DeliveredQuantity = 0" />
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>      
     </xsl:if> 

     <xsl:call-template name="regexpValidateElementIfExist">
        <xsl:with-param name="errorCodeValidate" select="'2780'"/>
        <xsl:with-param name="node" select="cbc:DeliveredQuantity"/>
        <xsl:with-param name="regexp" select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
     </xsl:call-template>
      
     <!-- Unidad de medida de la cantidad del bien --> 
     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
           <xsl:with-param name="node" select="cbc:DeliveredQuantity/@unitCode"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
     </xsl:if> 
      
     <xsl:if test="$motivoTraslado[text() != '08' and text() != '09' and text() != '13'] and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="findElementInCatalog">
		   <xsl:with-param name="errorCodeValidate" select="'4320'"/>
		   <xsl:with-param name="idCatalogo" select="cbc:DeliveredQuantity/@unitCode"/>
           <xsl:with-param name="catalogo" select="'03'"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
     </xsl:if> 

     <xsl:if test="$motivoTraslado[text() = '13'] and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'4320'"/>
           <xsl:with-param name="idCatalogo" select="cbc:DeliveredQuantity/@unitCode"/>
           <xsl:with-param name="catalogo" select="'65A'"/>
           <xsl:with-param name="isError" select="false()"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
     </xsl:if> 
      
     <xsl:if test="$motivoTraslado[text() = '08' or text() = '09'] and count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'3446'"/>
           <xsl:with-param name="idCatalogo" select="cbc:DeliveredQuantity/@unitCode"/>
           <xsl:with-param name="catalogo" select="'65'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
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
      
     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'2781'"/>
           <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
     </xsl:if> 
     
     <!-- Descripcion detallada del bien --> 
     <xsl:if test="cac:Item/cbc:Description">
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
     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0
               and $bienControlado &gt; 0">
        <xsl:call-template name="existElement">
           <xsl:with-param name="errorCodeNotExist" select="'3372'"/>
           <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>

        <xsl:call-template name="findElementInCatalog">
           <xsl:with-param name="errorCodeValidate" select="'3425'"/>
           <xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
           <xsl:with-param name="catalogo" select="'62A'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>        

     </xsl:if>

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
     </xsl:if>     
     
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
     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0
               and count(cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '7022'] and cbc:Value[text() = '1']]) &gt; 0">

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3426'"/>
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7020']"/>
           <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7020'])"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7020')"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3379'"/>
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7022']"/>
           <xsl:with-param name="expresion" select="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '49' or text() ='80']]) = 0"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7022')"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0
               and $motivoTraslado[text()='08' or text()='09']">

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3427'"/>
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7021']"/>
           <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7021'])"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7021')"/>
        </xsl:call-template>

        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'3428'"/>
           <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode = '7023']"/>
           <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7023'])"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7023')"/>
        </xsl:call-template>
     </xsl:if> 

     <xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:with-param name="nroLinea" select="$nroLinea"/>
        <xsl:with-param name="root" select="$root"/>
        <xsl:with-param name="motivoTraslado" select="$motivoTraslado"/>
        <xsl:with-param name="bienControlado" select="$bienControlado"/>
     </xsl:apply-templates>

  </xsl:template>

  <!--
   ===========================================================================================================================================

   ================================= Template cac:AddiotionalItemProperty (Autorizaciones especiales - Remitente) ============================

   ===========================================================================================================================================
   -->  
  <xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
     <xsl:param name="nroLinea"/>
     <xsl:param name="root"/>
     <xsl:param name="motivoTraslado"/>
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
    
     <xsl:if test="cbc:NameCode[text() = '7020' or text()='7021' or text()='7022' or text()='7023']">
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
        
        <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0
                  and $bienControlado &gt; 0">
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
     
     <xsl:if test="cbc:NameCode = '7021'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'2769'"/>
           <xsl:with-param name="node" select="cbc:Value"/>
           <xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{2}-[0-9]{1,6}$'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
        </xsl:call-template>

        <xsl:variable name="numDoc" select="cbc:Value"/>
        <xsl:if test="count($root/cac:Shipment/cbc:SpecialInstructions[text() = 'SUNAT_Envio_IndicadorTrasladoTotalDAMoDS']) = 0
                  and $motivoTraslado[text()='08' or text()='09']">
           <xsl:call-template name="isTrueExpresion">
              <xsl:with-param name="errorCodeValidate" select="'3430'"/>
              <xsl:with-param name="node" select="cbc:Value"/>
              <xsl:with-param name="expresion" select="count($root/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '50' or text() ='52'] and cbc:ID[text()= $numDoc]]) = 0"/>
              <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
           </xsl:call-template>
        </xsl:if>
     </xsl:if>

     <xsl:if test="cbc:NameCode = '7023'">
        <xsl:call-template name="regexpValidateElementIfExist">
           <xsl:with-param name="errorCodeValidate" select="'3431'"/>
           <xsl:with-param name="node" select="cbc:Value"/>
           <xsl:with-param name="regexp" select="'^(?!0+$)([0-9]{1,4})$'"/>
           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: ', cbc:NameCode)"/>
        </xsl:call-template>
     </xsl:if>

 </xsl:template>
        
</xsl:stylesheet>
