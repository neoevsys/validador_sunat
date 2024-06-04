<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:dyn="http://exslt.org/dyn"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"  
    xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:func="http://exslt.org/functions"
    exclude-result-prefixes="dyn gemfunc regexp date func" version="1.0">
    <!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
    <!-- <xsl:include href="D:/sunat_archivos/sfs/VALI/commons/error/error_utils.xsl" /> -->
    <!-- <xsl:include href="D:/sunat_archivos/sfs/VALI/commons/StringTemplates.xsl" /> -->
    
    
    <!-- Template que sirve para validar si un nodo existe y si existe valida que se cumpla la expresion regular -->
    
    <xsl:template name="existElement">
        <xsl:param name="errorCodeNotExist" />
        <xsl:param name="node" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'INFO'"/>
        

       <xsl:if test="not(string($node))">
           <xsl:choose>
               <xsl:when test="$isError">
                   <xsl:call-template name="rejectCall">
                       <xsl:with-param name="errorCode" select="$errorCodeNotExist" />
                       <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                   </xsl:call-template>
               </xsl:when>
               <xsl:otherwise>
                   <xsl:call-template name="addWarning">
                       <xsl:with-param name="warningCode" select="$errorCodeNotExist" />
                       <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                   </xsl:call-template>
               </xsl:otherwise>
           </xsl:choose>
       </xsl:if>
        
    </xsl:template>
    
    
    <!-- Template que sirve para validar si un nodo existe y si existe valida que se cumpla la expresion regular -->
    
    <xsl:template name="existAndRegexpValidateElement">
        <xsl:param name="errorCodeNotExist" />
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="node" />
        <xsl:param name="regexp" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'INFO'"/>
        
        <xsl:choose>
            <xsl:when test="not(string($node))">
                <xsl:choose>
                    <xsl:when test="$isError">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="$errorCodeNotExist" />
                            <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="addWarning">
                            <xsl:with-param name="warningCode" select="$errorCodeNotExist" />
                            <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(matches($node, $regexp,'!'))">
                    <xsl:choose>
                        <xsl:when test="$isError">
                            <xsl:call-template name="rejectCall">
                                <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                                <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            
                            <xsl:call-template name="addWarning">
                                <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                                <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
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
                   
        <xsl:if test="count($node) &gt;= 1 and not(matches(string($node), $regexp,'!'))">
            
            <xsl:choose>
                <xsl:when test="$isError">
                    <xsl:call-template name="rejectCall">
                        <xsl:with-param name="errorCode" select="$errorCodeValidate"/>
                        <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />                      
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                        <xsl:call-template name="addWarning">
                            <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                            <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,10})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
                   
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select ="$errorCodeValidate"/>
            <xsl:with-param name="node" select ="$node"/>
            <xsl:with-param name="regexp" select ="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,2})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,2})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select ="$errorCodeValidate"/>
            <xsl:with-param name="node" select ="$node"/>
            <xsl:with-param name="regexp" select ="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,3})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,3})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
                   
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select ="$errorCodeValidate"/>
            <xsl:with-param name="node" select ="$node"/>
            <xsl:with-param name="regexp" select ="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,10})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,10})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        

        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
            <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
            <xsl:with-param name="node" select="$node"/>
            <xsl:with-param name="regexp" select="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,2})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,2})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
            <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
            <xsl:with-param name="node" select ="$node"/>
            <xsl:with-param name="regexp" select ="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
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
                    <xsl:value-of select="'^(?!0[0-9]*(\.0*)?$)[0-9]{1,12}(\.[0-9]{1,3})?$'"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'^(?!(0)[0-9]+$)[0-9]{1,12}(\.[0-9]{1,3})?$'"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="$errorCodeNotExist"/>
            <xsl:with-param name="errorCodeValidate" select="$errorCodeValidate"/>
            <xsl:with-param name="node" select ="$node"/>
            <xsl:with-param name="regexp" select ="$regexp"/>
            <xsl:with-param name="isError" select ="$isError"/>
            <xsl:with-param name="descripcion" select="$descripcion"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->
    
    <xsl:template name="findElementInCatalog">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="idCatalogo" />
        <xsl:param name="catalogo" />
        <xsl:param name="descripcion" select="''"/>
        <xsl:param name="isError" select="true()"/>
        
        <xsl:variable name="url_catalogo" select="concat('../../../VALI/commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
                
        <xsl:if test='count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo]) &lt; 1 '>
            <xsl:choose>
                <xsl:when test="$isError">
                    <xsl:call-template name="rejectCall">
                        <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                        <xsl:with-param name="errorMessage" select="concat($descripcion,': Valor no se encuentra en el catalogo: ',$catalogo,' (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; valor: &quot;', $idCatalogo, '&quot;)')" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                        <xsl:call-template name="addWarning">
                            <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                            <xsl:with-param name="warningMessage" select="concat($descripcion,': ','Valor no se encuentra en el catalogo: ',$catalogo,' (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; valor: &quot;', $idCatalogo, '&quot;)')" />
                        </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->
    
    <xsl:template name="findElementInCatalogProperty">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="idCatalogo" />
        <xsl:param name="catalogo" />
        <xsl:param name="propiedad" />
        <xsl:param name="valorPropiedad" />
        <xsl:param name="descripcion" select="''"/>
        
        <xsl:variable name="url_catalogo" select="concat('../../../VALI/commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
        
        <xsl:variable name="apos">'</xsl:variable>
        <xsl:variable name="vCondition" select="concat('@id=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)" />
        <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')" />
        
        <!-- xsl:if test="count(document('local:///commons/cpe/catalogo/cat_22.xml')/l/c[@id=$idCatalogo and @tasa=$valorPropiedad]) &lt; 1 " -->
        <xsl:if test="count(dyn:evaluate($dynEval)) &lt; 1 ">
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                <xsl:with-param name="errorMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- INI PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->
    <xsl:template name="getValueInCatalogProperty">
        <xsl:param name="idCatalogo" />
        <xsl:param name="catalogo" />
        <xsl:param name="propiedad" />
        
        <xsl:variable name="url_catalogo" select="concat('../../../VALI/commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
        <xsl:variable name="apos">'</xsl:variable>
        
        <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[@id=', $idCatalogo, ']/@', $propiedad)" />
        
        <xsl:value-of select="dyn:evaluate($dynEval)" />

    </xsl:template>
    <!-- FIN PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->
    
    
    <!-- Template que sirve para verificar la expresion, si es verdadera lanza el error -->
    
    <xsl:template name="isTrueExpresion">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="node" />
        <xsl:param name="expresion" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'INFO '"/>
        
        <xsl:if test="$expresion = true()">
        
            <xsl:choose>
                <xsl:when test="$isError">
                    <xsl:call-template name="rejectCall">
                        <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                        <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    
                    <xsl:call-template name="addWarning">
                        <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                        <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        
        </xsl:if>
        
        
    </xsl:template>
    
    <xsl:template name="isDateBefore">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="startDateNode" />
        <xsl:param name="endDateNode" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'Error '"/>
        
        <xsl:if test="(date:seconds(date:difference(concat($endDateNode,'-00:00'),$startDateNode)) &lt; 0)">
            <xsl:choose>
                <xsl:when test="$isError">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                            <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                        </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="addWarning">
                        <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                        <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    
    </xsl:template>
    
    <xsl:variable name="currentdate" select="date:date()"/>
    
    <xsl:template name="isDateAfterToday">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="startDateNode" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'Error '"/>
        
        <xsl:if test="(date:seconds(date:difference(concat($startDateNode,'-00:00'),$currentdate)) &lt; 0)">
            <xsl:choose>
                <xsl:when test="$isError">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                            <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                        </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="addWarning">
                        <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                        <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    
    </xsl:template>
    
    
    <xsl:template name="isDateBeforeIfExist">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="startDateNode" />
        <xsl:param name="endDateNode" />
        <xsl:param name="isError" select="true()"/>
        <xsl:param name="descripcion" select="'Error '"/>
        
        <xsl:if test="count($startDateNode) &gt;= 1 and (date:seconds(date:difference(concat($endDateNode,'-00:00'),$startDateNode)) &lt; 0)">
            <xsl:choose>
                <xsl:when test="$isError">
                        <xsl:call-template name="rejectCall">
                            <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                            <xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                        </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="addWarning">
                        <xsl:with-param name="warningCode" select="$errorCodeValidate" />
                        <xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($startDateNode/parent::*),'/', name($startDateNode), '&quot; valor: &quot;', $startDateNode, '&quot;)')" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    
    </xsl:template>
    
    <func:function name="gemfunc:is-blank" as="xs:boolean">
        <xsl:param name="data" select="''"  as="xs:boolean"/>
        <xsl:sequence select="matches(string($data), '^[\s]*$', '!')"/>
    </func:function>
    
    <xsl:function name="regexp:match" as="xs:boolean">
        <xsl:param name="input" as="xs:string"/> 
        <xsl:param name="regex" as="xs:string"/> 
        <xsl:sequence select="matches($input, $regex, '!')"/>
    </xsl:function>
    
    
    
	<xsl:template name="findElementInCatalogPropertyxComponente">
        <xsl:param name="errorCodeValidate" />
        <xsl:param name="idCatalogo" />
		<xsl:param name="propiedadCatalogo" />
        <xsl:param name="catalogo" />
        <xsl:param name="propiedad" />
        <xsl:param name="valorPropiedad" />
        <xsl:param name="descripcion" select="''"/>
        
        <xsl:variable name="url_catalogo" select="concat('../../../VALI/commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
        
        <xsl:variable name="apos">'</xsl:variable>
        <xsl:variable name="vCondition" select="concat('@', $propiedadCatalogo, '=', $apos,$idCatalogo, $apos,' and @', $propiedad, '=', $apos, $valorPropiedad, $apos)" />
        <xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')" />
        
        <xsl:if test="count(dyn:evaluate($dynEval)) &lt; 1 ">
            <xsl:call-template name="rejectCall">
                <xsl:with-param name="errorCode" select="$errorCodeValidate" />
                <xsl:with-param name="errorMessage" select="concat($descripcion,': condicion:',$dynEval,' Valor no se encuentra en el catalogo: ',$catalogo,', ', $propiedadCatalogo , ': ', $idCatalogo, '  (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:template name="rejectCall">
		<xsl:param name="errorCode" />
		<xsl:param name="errorMessage" />
		<xsl:param name="priority" select="'error'"/>
		

        <xsl:message terminate="yes" >
			<xsl:value-of select="concat('errorCode; ',$ errorCode, ' error: ', $errorMessage)" />
		</xsl:message>

	</xsl:template>
    
	<!-- genera mensaje de warning -->
	<xsl:template name="addWarning">
	
		<xsl:param name="warningCode" />
		
		<xsl:param name="warningMessage" />
		
		
		<xsl:variable name="newWarning">
			
			<xsl:call-template name="createWarning">
			
				<xsl:with-param name="warningCode" select="$warningCode"/>
			
				<xsl:with-param name="warningMessage" select="$warningMessage"/>
				
			</xsl:call-template>
			
		</xsl:variable>
        
        <xsl:message terminate="no">
			<xsl:value-of select="$newWarning" />
		</xsl:message>
		
	</xsl:template>
	
	
	<!--  Crea un nuevo nodo warning -->
	
	<xsl:template name="createWarning">
		<xsl:param name="warningCode" />
		<xsl:param name="warningMessage" />
		
		<xsl:element name="warn">
			<xsl:value-of select="concat('code:', $warningCode, ',warning:', $warningMessage )"/>
		</xsl:element>
	</xsl:template>
    
</xsl:stylesheet>
