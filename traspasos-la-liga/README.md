# Análisis de Traspasos de La Liga

Este repositorio contiene un script de R (`getTransfers.R`) que descarga, limpia y procesa datos de traspasos de jugadores entre equipos de La Liga española de fútbol. He usado esos datos para un _side project_ en Svelte siguiendo el ejemplo de [Yuriko Schumacher](https://x.com/yuriko_a_s/status/1950958702464221231) en (The Athletic)[https://www.nytimes.com/athletic/6521187/2025/07/30/mlb-trade-deadline-matrix-cliques-rivals-executives/].

Puedes ver los gráficos interactivos [aquí](https://adrimaqueda.com/projects/traspasos-la-liga)

https://github.com/user-attachments/assets/43959f7a-507c-4892-a7c2-2b5179622171

## Cómo funciona

El script realiza los siguientes pasos:

1.  **Extracción de Datos**: Utiliza el paquete `worldfootballR` para descargar datos de traspasos desde Transfermarkt.com para un rango de años definido (por defecto, de 2017 a 2025). Para evitar sobrecargar el servidor, el script hace una pausa de 10 minutos entre la consulta de cada año. Puedes reducirlo al tiempo que quieras, pero no te recomendaría no hacer pausas porque el servidor te va a bloquear.

2.  **Limpieza de Datos**:
    *   Filtra los datos para quedarse únicamente con los traspasos realizados entre equipos de La Liga.
    *   Excluye los registros de "fin de cesión" para no contabilizarlos como un traspaso nuevo.
    *   Normaliza los nombres de los equipos para corregir inconsistencias (p. ej., "Betis" y "Real Betis Balompié" se unifican como "Real Betis").

3.  **Agregación de Datos**:
    *   Cuenta el número total de movimientos entre cada par de equipos.
    *   Diferencia entre fichajes y cesiones.

4.  **Generación del Archivo Final**:
    *   Crea una matriz con todas las combinaciones posibles de equipos de origen y destino.
    *   Exporta el resultado a un archivo llamado `transfers_matrix.csv`, que contiene el número de cesiones, fichajes y el total de movimientos entre cada club.

## Uso

1.  **Prerrequisitos**:
    *   Tener R instalado en tu sistema.
    *   Instalar las librerías necesarias.

2.  **Instalación de Paquetes**:
    Abre una consola de R y ejecuta el siguiente comando para instalar las dependencias:
    ```r
    install.packages(c("worldfootballR", "tidyverse"))
    ```

3.  **Ejecutar el Script**:
    Navega hasta el directorio del proyecto y ejecuta el script.
    ```r
    source("getTransfers.R")
    ```
    El script puede tardar bastante en completarse debido a la pausa de 10 minutos entre cada año.

## Salida

El script generará un archivo `transfers_matrix.csv` con la siguiente estructura:

| origen          | destino            | loans | transfers | totals |
| --------------- | ------------------ | ----- | --------- | ------ |
| FC Barcelona    | Atlético de Madrid | 1     | 2         | 3      |
| Real Madrid     | FC Barcelona       | 0     | 1         | 1      |
| Real Betis      | Sevilla FC         | 0     | 0         | 0      |
| ...             | ...                | ...   | ...       | ...    |

Donde `loans` son las cesiones, `transfers` los fichajes y `totals` la suma de ambos.
