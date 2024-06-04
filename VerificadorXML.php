<?php

function validateXMLWithXmllint($xmlFile, $xsdFile) {
    // Comando xmllint
    $command = escapeshellcmd("xmllint --schema " . escapeshellarg($xsdFile) . " " . escapeshellarg($xmlFile) . " --noout 2>&1");
    
    // Ejecutar el comando y capturar la salida
    exec($command, $output, $returnVar);

    $result = [
        'isValid' => $returnVar === 0,
        'errors' => []
    ];

    if ($returnVar !== 0) {
        foreach ($output as $line) {
            $error = parseErrorLine($line);
            if ($error !== null) {
                $result['errors'][] = $error;
            }
        }
    }

    return $result;
}

function parseErrorLine($line) {
    // Regex para capturar el formato del error de xmllint
    if (preg_match('/^(.*):(\d+): element (.*): Schemas validity error : (.*)$/', $line, $matches)) {
        print_r($matches);  die();
        return [
            'file' => $matches[1],
            'line' => (int)$matches[2],
            'element' => $matches[3],
            'message' => trim($matches[4])
        ];
    }
    return null;
}

// Archivo XML y XSD
$xmlFile = '20605446788-01-F002-00000031.xml';
$xsdFile = './contenido/maindoc/UBL-Invoice-2.1.xsd';

// Validar el XML
$result = validateXMLWithXmllint($xmlFile, $xsdFile);

// Devolver el resultado en formato JSON
header('Content-Type: application/json');
echo json_encode($result, JSON_PRETTY_PRINT);

?>
