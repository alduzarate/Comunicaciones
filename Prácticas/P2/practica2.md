**Ejercicio 1**

i.

* Clase A Rango: 1 – 127 (La red 127 se reserva para loopback y pruebas internas) (/8)
* Clase B Rango: 128 – 191 (/16)
* Clase C Rango: 192 – 223 (/24)
* Clase D Rango: 224 – 239 (Reservadas para multicast) (/4)
* Clase E Rango: 240 – 255 (Reservadas para experimentación, usadas para investigación (/4)

ii.
* Clase A 255.0.0.0
* Clase B 255.255.0.0
* Clase C: 255.255.255.0
  
iii.
* Clase A Rango: 10.0.0.0 – 10.255.255.255
* Clase B Rango: 172.16.0.0 – 172.31.255.255
* Clase C Rango: 192.168.0.0 – 192.168.255.255

**Ejercicio 2**

* 220.200.23.1

Clase de red: C
Parte de red: 220.200.23
Parte del host: 1
Máscara: 255.255.255.0

TODO

**Ejercicio 3**

* Dirección IP de la red: 174.56.7.0
* 60 hosts
* 1020 subredes
* 2^10 = 1024
* 174.56.7.0 => mascara por defecto = /16 ==> mascara ideal = /26 (16+10) ==> 255.255.255.11000000
* Las direcciones son de 32 bits, con lo cual para los host nos queda:
* 32 - 26 = 6 ==> hay 2^6 = 64 hosts :D

**Ejercicio 4**
* Dirección IP de la red: 210.66.56.0
* 30 hosts
* 6 subredes
* 2^3 = 8
* 210.66.56.0 => mascara por defecto = /24 ==> mascara ideal = /27 (24+3)
* Las direcciones son de 32 bits, con lo cual para los host nos queda:
* 32 - 27 = 5 ==> hay 2^5 = 32 hosts :D

**Ejercicio 5**

i.
* La red es 193.52.57.0
* Nos piden 8 sucursales ==> nos piden 8 subredes.
* 2^3 = 8
* 193.52.57.0 ==> máscara por defecto = /24 ==> máscara ideal = /27 (24+3)
* No sabemos la cantidad de hosts así que no tenemos que chequear eso. Pero, para saber:
Cantidad de hosts útiles por subred = 2^5 - 2 = 30 (-2 pq 1 para el id de la red y el otro para el broadcast)

Nota: el ejemplo de Flavio optó por una máscara /28 (para tener 16 subredes, por si el día de mañana se abre otra sucursal)

ii.
Cantidad de hosts por subred = 30
* Subred 1 - 193.52.57.0  (000-00000) - rango de hosts: 193.52.57.1 a 193.52.57.30 -> .31 broadcast
* Subred 2 - 193.52.57.32 (001-00000) - rango de hosts: 193.52.57.33 a 193.52.57.62 -> .63 broadcast
* Subred 3 - 193.52.57.64 (010-00000) - rango de hosts: 193.52.57.65 a 193.52.57.94 -> .95 broadcast
* Subred 4 - 193.52.57.96 (011-00000) - rango de hosts: 193.52.57.97 a 193.52.57.126 -> .127 broadcast
* Subred 5 - 193.52.57.128 (100-00000)- rango de hosts: 193.52.57.129 a 193.52.57.158 -> .159 broadcast
* Subred 6 - 193.52.57.160 (101-00000)- rango de hosts: 193.52.57.161 a 193.52.57.190 -> .191 broadcast 
* Subred 7 - 193.52.57.192 (110-00000)- rango de hosts: 193.52.57.193 a 193.52.57.222 -> .223 broadcast
* Subred 8 - 193.52.57.224 (111-00000)- rango de hosts: 193.52.57.225 a 193.52.57.254 -> .255 broadcast

Nota: Flavio en las direcciones de cada subred agarra 8 random de esas 16 totales en su tabla

iii.
La dirección de broadcast de la 3er subred es 193.52.57.95

**Ejercicio 6**

i. El host 'A' envía un paquete IP a 'B'

El host A le manda el paquete al R1 y este sabe la ubicación de B (puede hacer una entrega directa) y se lo manda tanto a A como B. A lo ignora y B lo recibe (al ser Ethernet).

ii. El host 'A' envía un paquete IP a 'C'

El A manda el paquete al R1. Este no tiene entrega directa al destino, pero por su tabla de ruteo sabe que éste está bajo R4. Se lo envía a R4, y este lo envía tanto a C como a X. X lo ignora y C lo acepta.

**Ejercicio 7**

i.
a)
![e7i](./e7ip2.png)
Preguntar si el que va a internet es un host random que me haya quedado libre.

b)

Tabla de ruteo del R:

Destino | Máscara | Gateway|
--------|---------|--------|
200.13.147.0| /24 | Entrega directa|
200.13.148.0| /24 | ED|
200.13.149.0| /24 | ED|

ii.
Necesitamos 3 subredes. Entonces con 2 bits nos alcanza ya que 2^2 = 4. Con lo cual la máscara nos queda /26 (24+2)
El ID de la red es: 200.13.147.0
En cada subred tenemos 2^6 - 2 hosts UTILES = 62 (64 en total)
Subred 1: 200.13.147.0 (00-000000) => rango de hosts: 200.13.147.1 a 200.13.147.62 (.63 broadcast) 
Subred 2: 200.13.147.64 (01-000000) => rango de hosts: 200.13.147.65 a 200.13.147.126 (.127 broadcast)
Subred 3: 200.13.147.128 (10-000000) => rango de hosts: 200.13.147.129 a 200.13.147.190 (.191 broadcast)
No la voy a usar, aunque flavio la usó para el enlace al router que sale a internet xd: Subred 4: 200.13.147.192 (11-000000) => rango de hosts: 200.13.147.193 a XD

HACER DIBUJITO

b)
Destino | Máscara | Gateway|
--------|---------|--------|
200.13.147.0| /26 | Entrega directa|
200.13.147.64| /26 | ED|
200.13.147.128| /26 | ED|
...(VER)

**Ejercicio 8**

La 199.199.20.6 es la que va del router a Internet (pq las IP publicas son las que tienen acceso desde internet, asumiendo que la que nos dan es pública)

El ID de la red 