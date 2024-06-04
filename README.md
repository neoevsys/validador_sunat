<p align="center"><a href="https://www.neotecperu.com/" target="_blank"><img src="https://www.neotecperu.com/wp-content/uploads/2022/08/logo_png.png" width="400" alt="Laravel NEOTEEC"></a></p>


## Validador de XML tanto de Tags como de Valores.
Primero esto solo funciona en servidores privados (no en hosting), ya que necesitamos instalar 2 cosas:

- libxml2-utils
- Java

Y sobretodo activar la función: `exec` de PHP
### Actualizamos
```shell script
sudo dnf update
```

### Primero instalamos: libxml2-utils
```shell script
sudo dnf install -y libxml2-utils
```

### Segundo instalamos: Java
```shell script
sudo yum install -y java-1.8.0-openjdk
```

> Esto es un aporte a la comunidad `Greenter` si tienes preguntas ingresa al grupo de Telegram https://t.me/+EZKfH3D1cDtlNDE5