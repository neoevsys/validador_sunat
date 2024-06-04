<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:regexp="http://exslt.org/regular-expressions" 
xmlns:dyn="http://exslt.org/dynamic" xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions" 
xmlns:date="http://exslt.org/dates-and-times" xmlns:func="http://exslt.org/functions" 
xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp dyn regexp date func" version="1.0">
  <!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
  <!-- xsl:include href="local:///commons/error/error_utils.xsl"
               dp:ignore-multiple="yes"/ -->
  <!-- xsl:include href="local:///commons/StringTemplates.xsl"
               dp:ignore-multiple="yes"/ -->
  <!-- Inicio: SFS -->
  <xsl:include href="error_utils.xsl"/>
  <xsl:include href="../StringTemplates.xsl"/>
  <!-- Fin: SFS -->
  <!-- Template que sirve para validar que exista y que serie y nro sera valido segun su tipo -->
  <!-- Se debe de usar para elementos obligatorios -->
  <xsl:template name="existAndValidateSerieyNroCPE">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="tipoComprobante"/>
    <xsl:param name="withPortal" select="false()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$tipoComprobante = '01'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([F][A-Z0-9]{3}|[\d]{1,4}|E001)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([F][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '03'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([B][A-Z0-9]{3}|[\d]{1,4}|EB01)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([B][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '07'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '08'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '09'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([T][A-Z0-9]{3}|[\d]{1,4}|EG01)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([T][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '14'">
          <xsl:value-of select="'^([S][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '06' or $tipoComprobante = '13' or $tipoComprobante = '16' or $tipoComprobante = '37' or $tipoComprobante = '43' or $tipoComprobante = '45' or $tipoComprobante = '24' or $tipoComprobante = '15'">
          <xsl:value-of select="'^[a-zA-Z0-9-]{1,20}-[0-9]{1,10}?$'"/>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '12'">
          <xsl:value-of select="'^[a-zA-Z0-9-]{1,20}-[0-9]{1,10}?$'"/>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '56'">
          <xsl:value-of select="'^[a-zA-Z0-9-]{1,30}?$'"/>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '20'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([R][A-Z0-9]{3}|[\d]{1,4}|E001)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([R][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '40'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([P][A-Z0-9]{3}|[\d]{1,4}|E001)-[0-9]{1,8}?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([P][A-Z0-9]{3}|[\d]{1,4})-[0-9]{1,8}?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^([FBSTPR][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)-[0-9]{1,8}?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar si existe el nodo y que cumpla una serie valida -->
  <!-- Se debe de usar para elementos obligatorios -->
  <xsl:template name="existAndValidateSerieCPE">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="tipoComprobante"/>
    <xsl:param name="withPortal" select="false()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$tipoComprobante = '01'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([F][A-Z0-9]{3}|[\d]{1,4}|E001)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([F][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '03'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([B][A-Z0-9]{3}|[\d]{1,4}|EB01)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([B][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '07'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '08'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([FBS][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '09'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([T][A-Z0-9]{3}|[\d]{1,4}|EG01)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([T][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '14'">
          <xsl:value-of select="'^([S][A-Z0-9]{3}|[\d]{1,4})?$'"/>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '06' or $tipoComprobante = '13' or $tipoComprobante = '16' or $tipoComprobante = '37' or $tipoComprobante = '43' or $tipoComprobante = '45' or $tipoComprobante = '24' or $tipoComprobante = '15'">
          <xsl:value-of select="'^[a-zA-Z0-9-]{1,20}?$'"/>
        </xsl:when>
        <!-- 
                <xsl:when test="$tipoComprobante = '12'">
                    <xsl:value-of select="'^[a-zA-Z0-9-]{1,20}?$'"></xsl:value-of>
                </xsl:when>
                <xsl:when test="$tipoComprobante = '56'">
                    <xsl:value-of select="'^[a-zA-Z0-9-]{1,30}?$'"></xsl:value-of>
                </xsl:when>
                -->
        <xsl:when test="$tipoComprobante = '20'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([R][A-Z0-9]{3}|[\d]{1,4}|E001)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([R][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$tipoComprobante = '40'">
          <xsl:choose>
            <xsl:when test="$withPortal">
              <xsl:value-of select="'^([P][A-Z0-9]{3}|[\d]{1,4}|E001)?$'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'^([P][A-Z0-9]{3}|[\d]{1,4})?$'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^([FBSTPR][A-Z0-9]{3}|[\d]{1,4}|EB01|E001)?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar si un nodo existe y si existe no este vacio (solo contenga cualquier tipo de espacio o saltos de linea) -->
  <xsl:template name="existElement">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="node"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:if test="not(string($node))">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeNotExist"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeNotExist"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- Template que sirve para validar si un nodo existe -->
  <xsl:template name="existElementNoVacio">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="node"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:if test="not($node)">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeNotExist"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeNotExist"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- Template que sirve para validar si un nodo existe y si existe valida que se cumpla la expresion regular -->
  <xsl:template name="existAndRegexpValidateElement">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="regexp"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:choose>
      <xsl:when test="not(string($node))">
        <xsl:choose>
          <xsl:when test="$isError">
            <xsl:call-template name="rejectCall">
              <xsl:with-param name="errorCode" select="$errorCodeNotExist"/>
              <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="addWarning">
              <xsl:with-param name="warningCode" select="$errorCodeNotExist"/>
              <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	  <!-- Funcion MATCH -->
      <!-- <xsl:if test="not(regexp:match(string($node),$regexp))">
          <xsl:choose>
            <xsl:when test="$isError">
              <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode"
                                select="$errorCodeValidate"/>
                <xsl:with-param name="errorMessage"
                                select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>


              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="addWarning">
                <xsl:with-param name="warningCode"
                                select="$errorCodeValidate"/>
                <xsl:with-param name="warningMessage"
                                select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>


              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if> -->

                <xsl:if test="not(matches($node, $regexp,'!'))">
                    <xsl:choose>
                        <xsl:when test="$isError">
                            <xsl:call-template name="rejectCall">
                                <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                                <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            
                            <xsl:call-template name="addWarning">
                                <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                                <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo existe, valida que se cumpla la expresion regular, si el nodo no existe no hace nada -->
  <!-- Se debe de usar para elementos opcionales -->
  <xsl:template name="regexpValidateElementIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="regexp"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <!-- <xsl:if test="count($node) &gt;= 1 and not(regexp:match($node,$regexp))">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode"
                            select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage"
                            select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>


          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode"
                            select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage"
                            select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>


          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if> -->
	
                <xsl:if test="count($node) &gt;= 1 and not(matches($node, $regexp,'!'))">
                    <xsl:choose>
                        <xsl:when test="$isError">
                            <xsl:call-template name="rejectCall">
                                <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                                <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            
                            <xsl:call-template name="addWarning">
                                <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                                <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
	
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales y es mayor a cero -->
  <!-- Se debe de usar para elementos opcionales -->
  <xsl:template name="validateValueTenDecimalIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="regexpValidateElementIfExist">
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales y es mayor a cero -->
  <!-- Se debe de usar para elementos opcionales -->
  <xsl:template name="validateValuePercentIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="regexpValidateElementIfExist">
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales y es mayor a cero -->
  <!-- Se debe de usar para elementos opcionales -->
  <xsl:template name="validateValueTwoDecimalIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,2})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,2})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="regexpValidateElementIfExist">
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales y es mayor a cero -->
  <!-- Se debe de usar para elementos opcionales -->
  <xsl:template name="validateValueThreeDecimalIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,3})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,3})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="regexpValidateElementIfExist">
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales -->
  <!-- Se debe de usar para elementos obligatorios -->
  <xsl:template name="existAndValidateValueTenDecimal">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,10})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 02 decimales -->
  <!-- Se debe de usar para elementos obligatorios -->
  <xsl:template name="existAndValidateValueTwoDecimal">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,2})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,2})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar un nodo y si el nodo contiene un monto de 12 enteros 10 decimales -->
  <!-- Se debe de usar para elementos obligatorios -->
  <xsl:template name="existAndValidateValueThreeDecimal">
    <xsl:param name="errorCodeNotExist"/>
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="isGreaterCero" select="true()"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO'"/>
    <xsl:variable name="regexp">
      <xsl:choose>
        <xsl:when test="$isGreaterCero">
          <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,3})?$'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,3})?$'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="existAndRegexpValidateElement">
      <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
      <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
      <xsl:with-param name="node" select="$node"/>
      <xsl:with-param name="regexp" select="$regexp"/>
      <xsl:with-param name="isError" select="$isError"/>
      <xsl:with-param name="descripcion" select="$descripcion"/>
    </xsl:call-template>
  </xsl:template>
  <!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->
  <xsl:template name="findElementInCatalog">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
    <xsl:if test="count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo]) &lt; 1 ">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,': Valor no se encuentra en el catalogo: ',$catalogo,' (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; valor: &quot;', $idCatalogo, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,': ','Valor no se encuentra en el catalogo: ',$catalogo,' (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; valor: &quot;', $idCatalogo, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->
  <xsl:template name="findElementInCatalogProperty">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:param name="valorPropiedad"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    <!-- INI SFS <xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/> -->
	<xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="vCondition" select="concat('@id=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)"/>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')"/>
    <!-- xsl:if test="count(document('local:///commons/cpe/catalogo/cat_22.xml')/l/c[@id=$idCatalogo and @tasa=$valorPropiedad]) &lt; 1 " -->
	
	<xsl:if test="count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo and @gre-r=$valorPropiedad]) &lt; 1 ">
	
    <!-- <xsl:if test="count(dyn:evaluate($dynEval)) &lt; 1 "> -->
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="findElementInCatalog61rProperty">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:param name="valorPropiedad"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    
	<!-- Inicio: SFS -->
    <!-- <xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/> -->
	<xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
	<!-- Fin: SFS -->

    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="vCondition" select="concat('@id=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)"/>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')"/>
    <xsl:if test="count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo and @gre-r=$valorPropiedad]) &lt; 1 ">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template> 
  
  <xsl:template name="findElementInCatalog61tProperty">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:param name="valorPropiedad"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    
	<!-- Inicio: SFS -->
    <!-- <xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/> -->
	<xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
	<!-- Fin: SFS -->

    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="vCondition" select="concat('@id=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)"/>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')"/>
    <xsl:if test="count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo and @gre-t=$valorPropiedad]) &lt; 1 ">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>   
  
  <xsl:template name="findElementInCatalogGREUbigeoProperty">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:param name="valorPropiedad"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    
	<!-- Inicio: SFS -->
    <!-- <xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/> -->
    <xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
	<!-- Fin: SFS -->

    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="vCondition" select="concat('@id=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)"/>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')"/>
    <xsl:if test="count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo and @ubigeo=$valorPropiedad]) &lt; 1 ">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate ,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template> 
  
  <!-- INI PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->
  <xsl:template name="getValueInCatalogProperty">
    <xsl:param name="idCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[@id=', $idCatalogo, ']/@', $propiedad)"/>
    <xsl:value-of select="dyn:evaluate($dynEval)"/>
  </xsl:template>
  <!-- FIN PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->
  <!-- Template que sirve para verificar la expresion, si es verdadera lanza el error -->
  <xsl:template name="isTrueExpresion">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="expresion"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO '"/>
    <xsl:if test="$expresion = true()">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- PAS20221U210700304-INI-EBV -->
    <xsl:template name="isTrueExpresionEmptyNode">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="expresion" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'INFO '"/>
        <xsl:param name="line" select="'0'"/>
        
        <xsl:if test="$expresion = true()">
            <xsl:choose>
                <xsl:when test="$isError">    
                    <xsl:call-template name="rejectCall">
                        <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                        <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate)" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>   
                    <xsl:call-template name="addWarning">
                        <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                        <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate)" />
                        <xsl:with-param name="warningLine" select="$line" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        
    </xsl:template>
    <!-- PAS20221U210700304-FIN-EBV -->
  <xsl:template name="isTrueExpresionIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="node"/>
    <xsl:param name="expresion"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'INFO '"/>
    <xsl:if test="count($node) &gt;= 1 and $expresion = true()">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- Verifica si un contribuyente esta afiliado a otro (Ose o a un PSE) -->
  <xsl:template name="verifyAfiliacion">
    <xsl:param name="urlService"/>
    <xsl:param name="errorCode"/>
    <xsl:param name="errorMessage"/>
    <xsl:param name="isError" select="true()"/>
    <!-- agregado PAS20191U210100101  -->
    <xsl:variable name="resp">
      <dp:url-open target="{$urlService}" response="responsecode-binary" http-method="get" timeout="300"/>
    </xsl:variable>
    <!-- 
        <xsl:message terminate="no" dp:category="cpe" dp:priority="warn">
        
            <xsl:copy-of select="$resp"></xsl:copy-of>
        
        </xsl:message>
         -->
    <xsl:if test="string($resp/result/responsecode) != '200'">
      <xsl:call-template name="rejectCall">
        <xsl:with-param name="errorCode" select="'200'"/>
        <xsl:with-param name="errorMessage" select="concat('El servicio: ',$urlService, ' no esta disponible')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template name="isDateBefore">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="startDateNode"/>
    <xsl:param name="endDateNode"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'Error '"/>
    <xsl:if test="(date:seconds(date:difference(concat($endDateNode,'-00:00'),$startDateNode)) &lt; 0)">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:variable name="currentdate" select="date:date()"/>
  <xsl:template name="isDateAfterToday">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="startDateNode"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'Error '"/>
    <xsl:if test="(date:seconds(date:difference(concat($startDateNode,'-00:00'),$currentdate)) &lt; 0)">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': errorCode ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:template name="isDateBeforeIfExist">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="startDateNode"/>
    <xsl:param name="endDateNode"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:param name="descripcion" select="'Error '"/>
    <xsl:if test="count($startDateNode) &gt;= 1 and (date:seconds(date:difference(concat($endDateNode,'-00:00'),$startDateNode)) &lt; 0)">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="addWarning">
            <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
            <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- verifca si un certificado le pertenece a un contribuyente:
    datos de entrada ruc mas numero de serie del certificado 
    fecha en que fue firmado el comprobante
    retorna codigo de error y certificado validado 
    
    Solo es valido para servicios fuera del dominio FACTURA ELECTRONICA 
    -->
  <xsl:template name="validateCertContribuyente">
    <xsl:param name="rucBillCertSerialExaDecimal"/>
    <xsl:param name="rucPseCertSerialExaDecimal"/>
    <xsl:param name="issueDate"/>
    <xsl:param name="certificados" select="'local:///sistemagem/catalogos/certificados.xml'"/>
    <xsl:variable name="certificates" select="document($certificados)"/>
    <xsl:variable name="certificate" select="$certificates/l/c[@id=$rucBillCertSerialExaDecimal or @id=$rucPseCertSerialExaDecimal]"/>
    <xsl:variable name="errorCode">
      <xsl:choose>
        <xsl:when test="$certificate">
          <xsl:choose>
            <xsl:when test="$certificate/r =1 ">2328</xsl:when>
            <xsl:when test="$certificate/b =1 ">2326</xsl:when>
            <!-- xsl:when test="(date:seconds(date:difference($issuedate,$certificate/f)) &lt; 0)">
                            2327
                        </xsl:when-->
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>2325</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$errorCode != 0">
      <xsl:call-template name="rejectCall">
        <xsl:with-param name="errorCode" select="$errorCode"/>
        <xsl:with-param name="errorMessage" select="concat('Validation Cert Serial error: ', $errorCode ,' rucBillcertserial: ',$rucBillCertSerialExaDecimal ,' rucPseBillcertserial: ',$rucPseCertSerialExaDecimal,' issueDate: ', $issueDate)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <!-- obtenemos el numero de serie del certificado en base64 -->
  <xsl:template name="getCertificateSerialNumber">
    <xsl:param name="base64cert"/>
    <!-- get the serial number of certificate -->
    <xsl:variable name="serialNumber">
      <xsl:value-of select="dp:get-cert-serial(concat('cert:',$base64cert))"/>
    </xsl:variable>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
    <xsl:variable name="certSerialExaDecimal">
      <xsl:call-template name="remove-leading-zeros">
        <xsl:with-param name="text" select="translate(dp:radix-convert($serialNumber, 10, 16),$uppercase,$lowercase)"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$certSerialExaDecimal"/>
  </xsl:template>
  <func:function name="gemfunc:is-blank">
        <xsl:param name="data" select="''"/>
        <func:result select="regexp:match($data,'^[\s]*$')"/>
      </func:function>
  <xsl:template name="findElementInCatalogPropertyxComponente">
    <xsl:param name="errorCodeValidate"/>
    <xsl:param name="idCatalogo"/>
    <xsl:param name="propiedadCatalogo"/>
    <xsl:param name="catalogo"/>
    <xsl:param name="propiedad"/>
    <xsl:param name="valorPropiedad"/>
    <xsl:param name="descripcion" select="''"/>
    <xsl:param name="isError" select="true()"/>
    <xsl:variable name="url_catalogo" select="concat('../cpe/catalogo/cat_',$catalogo,'.xml')"/>
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="vCondition" select="concat('@', $propiedadCatalogo, '=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)"/>
    <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')"/>
    <!-- xsl:if test="count(document('local:///commons/cpe/catalogo/cat_22.xml')/l/c[@id=$idCatalogo and @tasa=$valorPropiedad]) &lt; 1 " -->
    <xsl:if test="count(dyn:evaluate($dynEval)) &lt; 1 ">
      <xsl:choose>
        <xsl:when test="$isError">
          <xsl:call-template name="rejectCall">
            <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
            <xsl:with-param name="errorMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en x el catalogo: ',$catalogo,', ', $propiedadCatalogo , ': ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <!-- xsl:call-template name="addWarning">
		                <xsl:with-param name="warningCode" select="$errorCodeValidate"/>
	                    <xsl:with-param name="warningMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en el catalogo: ',$catalogo,', ', $propiedadCatalogo , ': ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')" />;
                    </xsl:call-template -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
