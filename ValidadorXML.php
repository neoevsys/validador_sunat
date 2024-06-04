<?php
// Definir las rutas a los archivos
$xmlFile = '20605446788-01-F002-00000031.xml';
$xslFile = 'contenido/commons/xsl/ValidaExprRegFactura-2.0.1.xsl';
$saxonJar = 'saxon/saxon-he-12.4.jar';
$paramName = 'nombreArchivoEnviado';
$paramValue = '20605446788-01-F002-00000031.xml';

// Construir el comando para ejecutar Saxon-HE
$command = "java -jar " . escapeshellarg($saxonJar) . " -s:" . escapeshellarg($xmlFile) . " -xsl:" . escapeshellarg($xslFile) . " " . escapeshellarg($paramName) . "=" . escapeshellarg($paramValue);

exec($command . " 2>&1", $output, $returnVar);

$result = [
    'isValid' => $returnVar === 0,
    'errors' => []
];

// Filtrar y procesar la salida
foreach ($output as $line) {
    // Eliminar líneas que contienen mensajes no deseados
    if (strpos($line, 'Error at xsl:message') !== false || strpos($line, 'Processing terminated by xsl:message') !== false) {
        continue; // Ignorar estas líneas
    }

    // Clasificar las líneas como errores o salida informativa
    if (strpos($line, 'error') !== false || strpos($line, 'Error') !== false) {
        $result['errors'][] = $line;
    }
}

if(count($result['errors'])){
    $result['isValid'] = false;
}

header('Content-Type: application/json');
echo json_encode($result, JSON_PRETTY_PRINT);
?>
