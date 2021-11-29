#!/bin/bash

# Puertos
# Mail (smtp/s) puerto 25 - 465 / tcp
# BD (mysql) puerto 3306 / tcp
# DNS (dns) puerto 53 / tcp - udp
# Web (http/s) puerto 80 - 443 / tcp
# Acceso remoto (ssh) puerto 22 / tcp
# Proxy Web () puerto 3128 / tcp 

# Ejercicio 30112017

# Definición de variables

I = /sbin/iptables
LAN = 10.23.0.0/16
ADMIN_PC = 10.23.23.5
DMZ = 10.1.1.0/29
WEBSRV = 10.1.1.2
MAIL_RELAY = 10.1.1.3
MAIL_SRV = 10.10.1.3
DB_SRV = 10.10.1.2
IF_LAN = eth2
IF_SRV = eth1
IF_DMZ = eth3
IF_EXT = eth0 
IP_EXT = 200.123.131.112

case $1 in
  start)

# Policies
# Valores por omision de las cadenas
# Deniego entrada y salida por omision.
$I -P INPUT DROP
$I -P OUTPUT DROP
# 9- No hay más accesos que los especificados.
$I -P FORWARD DROP

# TABLA FILTER

# También por reque 9 (Reglas de estado)
for i in INPUT OUTPUT FORWARD; do
    $I -A $i -m state -state INVALID -j DROP
    $I -A $i -m state -state RELATED, ESTABLISHED -j ACCEPT
done

#Si llega hasta acá es porque los paquetes son NEW (solo quedan las conexiones en estado "NEW" para las cadenas INPUT y OUTPUT)

# Cadenas INPUT Y OUTPUT

# 8- En cuanto al firewall en si, sólo es posible ingresar desde la PC del administrador, 10.23.23.5
# por ssh. 
# (utilizo -i para prevenir spoofing de direcciones desde otra red)
$I -A INPUT -s $ADMIN_PC -dport=22 -i=IF_LAN -p tcp -j ACCEPT
# Como puse -P DROP, no sería necesario denegar todo el resto explicitamente. Pero sería agregar:
$I -A INPUT -j DROP # si ya matchea en la regla anterior, no llega acá

# 8- Desde el firewall, solo se puede consultar dns en el servidor de la DMZ. 
# El DNS maestro para la organizacion (autoritativo para el dominio y cache para los equipos internos) se encuentra en el
#servidor “Mailrelay”
$I -A OUTPUT -d $MAIL_RELAY -dport=53 -i=IF_DMZ -p tcp -j ACCEPT
$I -A OUTPUT -d $MAIL_RELAY -dport=53 -i=IF_DMZ -p udp -j ACCEPT
# No se aceptan más paquetes en la cadena OUTPUT (por la policy)

# CADENA FORWARD

# 1- Las PC de la LAN tienen acceso al correo electronico en la red de servidores (imap, imaps, pop,
# pop3s, smtp, smtp-ssl – tcp en todos los casos -) y a la aplicacion web de negocios en el dbserver
# por https. Asimismo pueden acceder al DNS de la DMZ, y a nada mas de las redes internas.
$I -A FORWARD -m multiport -s $LAN -d $MAIL_SRV -p tcp -i $IF_LAN -dports imap, imaps, pop, pop3s, smtp, smtp-ssl -j ACCEPT
$I -A FORWARD -m multiport -s $LAN -d $DB_SRV -p tcp -i $IF_LAN -dport 443 -j ACCEPT
$I -A FORWARD -s $LAN -d $MAIL_RELAY -dport 53 -p udp -i $IF_LAN -j ACCEPT
# el "y nada más de las redes internas" queda cumplido con la policy -P

# 2- El servidor de mail de la red de servidores tiene acceso al dns y al puerto 465/tcp (smtps) del relay.
$I -A FORWARD -m multiport -s $MAIL_SRV -d $MAIL_RELAY -p tcp -dports 53,465 -i $IF_SRV -j ACCEPT
$I -A FORWARD -s $MAIL_SRV -d $MAIL_RELAY -p udp -dport 53 -i $IF_SRV -j ACCEPT

# 3- El relay tiene acceso al puerto 465/tcp del servidor de mail
$I -A FORWARD -s $MAIL_RELAY -d $MAIL_SRV -i IF_DMZ -dport 465 -p tcp -j ACCEPT

# 4- el webserver de la dmz tiene acceso al puerto 3306/tcp (mysql) del dbserver
$I -A FORWARD -s $WEBSRV -d $DB_SRV -p tcp -i IF_DMZ -dport 3306 -j ACCEPT

# 5- Las pc pueden navegar libremente por internet (no sabemos puntualmente a qué destino, pero sabemos que va a estar afuera, por eso
# -o IF_EXT).
$I -A FORWARD -s $LAN -i $IF_LAN -o $IF_EXT -j ACCEPT # En la tabla NAT le vamos a tener que cambiar la source addres por la IP publica
# para que puedan llegar las respuestas devuelta

# 6- Desde internet (no se sabe la fuente con exactitud! NO poner -s $IP_EXT) es posible acceder a los siguientes servicios de la DMZ: 
# Mailrelay 53 udp y tcp (DNS) y 25 (SMTP), y a los puertos 80 y 443 del webserver, a través de la única IP pública
$I -A FORWARD -d $MAIL_RELAY -i IF_EXT -p udp -dport 53 -j ACCEPT   #SMTP es solo por tcp
$I -A FORWARD -m multiport -d $MAIL_RELAY -i IF_EXT -p tcp -dports 53, 25 -j ACCEPT
$I -A FORWARD -m multiport -d $WEBSRV -i IF_EXT -p tcp -dports 80,443 -j ACCEPT

# 7- Los servidores de la DMZ pueden consultar DNS a internet y el RELAY puede enviar correo a Internet a traves del puerto 25/tcp
$I -A FORWARD -i $IF_DMZ -o IF_EXT -p tcp -dport 53 -j ACCEPT
$I -A FORWARD -i $IF_DMZ -o IF_EXT -p udp -dport 53 -j ACCEPT
$I -A FORWARD -i $IF_DMZ -s $MAIL_RELAY -o IF_EXT -dport 25 -p tcp -j ACCEPT

# Tabla NAT
# Hay que hacer que la comunicación sea posible para los reques 5, 6 y 7

# 5 - Las pc pueden navegar libremente por internet
$I -t nat -A POSTROUTING -s $LAN -o $IF_EXT -j SNAT -to-source $IP_EXT # al poner SNAT podría poner -to nada más
# NO se puede usar -i en POSTROUTING

# 6- Desde internet (no se sabe la fuente de afuera! NO poner -s $IP_EXT) es posible acceder a los siguientes servicios de la DMZ: 
# Mailrelay 53 udp y tcp (DNS) y 25 (SMTP), y a los puertos 80 y 443 del webserver, a través de la única IP pública
$I -t nat -A PREROUTING -d $IP_EXT -p udp -dport 53 -j DNAT --to-destination $MAIL_RELAY
$I -t nat -A PREROUTING -m multiport -d $IP_EXT -p tcp -dports 53,25 -j DNAT -to $MAIL_RELAY
$I -t nat -A PREROUTING -m multiport -d $IP_EXT -p tcp -dports 80,443 -j DNAT -to $WEBSRV

# 7 - Los servidores de la DMZ pueden consultar DNS a internet y el RELAY puede enviar correo a Internet a traves del puerto 25/tcp
$I -t nat -A POSTROUTING -s $DMZ -o $IF_EXT -j SNAT -to $IP_EXT


# Ejercicio 28112018

# Definición de variables

WEB_SRV = 181.16.1.18 # pública
PROXY = 181.16.1.19 # pública
DMZ = 181.16.1.16/28 # red pública
IP_EXT = 200.3.1.2
LAN = 10.0.1.0/24 # privada
ADMIN_PC = 10.0.1.22 # privada
IF_LAN = eth0 
IF_DMZ = eth1
IF_EXT = eth2 

I = /sbin/iptables

case $1 in 
start)

# Limpiamos reglas anteriores 
$I -F -t filter 
$I -F -t nat

# Policies

# Reglas de estado (firewall stateful)
for i in INPUT, OUTPUT, FORWARD; do
$I -A $i -m state --state INVALID -j DROP
$I -A $i -m state --state RELATED, ESTABLISHED -j ACCEPT
done

# Tabla FILTER

# Cadenas INPUT y OUTPUT

# 1- La PC de administración es el único lugar desde donde se puede acceder al servicio ssh de los servidores y el firewall.
$I -A INPUT -i $IF_LAN -s $ADMIN_PC -p tcp -dport 22 -j ACCEPT
$I -A INPUT -j DROP # $I -P INPUT DROP

# 6- El firewall solo tiene acceso al proxy (para actualizaciones).
$I -A OUTPUT -i $IF_DMZ -d $PROXY -p tcp -dport 3128 -j ACCEPT
$I -A OUTPUT -j DROP    #I -P OUTPUT DROP

# Cadena FORWARD

# 1- La PC de administración es el único lugar desde donde se puede acceder al servicio ssh de los servidores
$I -A FORWARD -i $IF_LAN -o $IF_DMZ -s $ADMIN_PC -d $DMZ -p tcp -dport 22 -j ACCEPT
# $I -A FORWARD -m iprange -s $ADMIN_PC -i $IF_LAN --dst-range $WEB_SRV-$PROXY -p tcp --dport 22 -j ACEPT para especificar IPs de los servers
$I -A FORWARD -o $IF_DMZ -dport 22 -j REJECT

# 2- Las PC de la LAN pueden acceder a los servicios restantes de los servidores de la DMZ
$I -A FORWARD -i $IF_LAN -o $IF_DMZ -s $LAN -d $DMZ -j ACCEPT

# 3- Las PC pueden acceder a Internet en forma directa, exceptuando la navegación web que debe realizarse exclusivamente a través del proxy.
#Para los servicios que no pasan por el proxy, es necesario realizar NAT, pues tienen direcciones privadas.
$I -A FORWARD -i $IF_LAN -s $LAN -o $IF_EXT -m multiport -dports 80,443 -p tcp -j REJECT
$I -A FORWARD -i $IF_LAN -s $LAN -o $IF_EXT -j ACCEPT # hay que natear después

# 4- Los servidores de la DMZ solo pueden acceder a servicios DNS y web en Internet, y no tienen acceso alguno a la LAN.
#DNS
$I -A FORWARD -i $IF_DMZ -s $DMZ -o $IF_EXT -p udp -dport 53 -j ACCEPT
$I -A FORWARD -i $IF_DMZ -s $DMZ -o $IF_EXT -p tcp -dport 53 -j ACCEPT
#WEB
$I -A FORWARD -m multiport -i $IF_DMZ -s $DMZ -o $IF_EXT -p tcp -dports 80,443 -j ACCEPT
# Restriccion
$I -A FORWARD -i $IF_DMZ -s $DMZ -o $IF_LAN -d $LAN -j REJECT

# 5- Desde Internet, solo se puede acceder a los servicios DNS (ambos servers) y Web del “www”
$I -A FORWARD -i $IF_EXT -d $DMZ -o $IF_DMZ -p udp -dport 53 -j ACCEPT
$I -A FORWARD -i $IF_EXT -d $DMZ -o $IF_DMZ -p tcp -dport 53 -j ACCEPT

$I -A FORWARD -m multiport -i $IF_EXT -d $WEB_SRV -o $IF_DMZ -p tcp -dports 80,443 -j ACCEPT 


$I -P FORWARD DROP

# Tabla NAT
$I -t nat -A POSTROUTING -s $LAN -o $IF_EXT -j SNAT -to $IP_EXT

;;
stop)
$I -P INPUT ACCEPT
$I -P FORWARD DROP
$I -P OUTPUT ACCEPT
$I -F -t nat
$I -F
;;
*)
echo "Sintaxis: $0 <start|stop>"
exit 1
;;
esac


# Ejercicio 16122020

# Def de variables
SERVERS = 10.0.2.0/24
DB_SRV = 10.0.2.3
DMZ = 181.16.1.16/28
DMZ_WEB_SRV = 181.16.1.18
DNS = 181.16.1.19
LAN = 10.0.1.0/24
ADMIN_PC = 10.0.1.22
IP_EXT = 200.3.1.2
IF_LAN = eth0
IF_SRV = eth1 
IF_DMZ = eth2 
IF_EXT = eth3

case $1 in
  start)

# Reglas de estado
$I -A FORWARD -m state --state INVALID -j DROP
$I -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Tabla FILTER
# Pcs de la LAN: NO tienen acceso a red de servidores, sí al resto del universo.
$I -A FORWARD -i $IF_LAN -o IF_SRV -j REJECT 
$I -A FORWARD -i $IF_LAN -s $LAN -j ACCEPT  # queda natear después para que puedan ir y volver a internet

# Desde el exterior solo se puede tener acceso limitado a la DMZ: al dns (puertos tcp y udp 53 de
#ambos servidores) y puertos 80 y 443 del servidor Web.
for protocolo in udp, tcp; do
$I -A FORWARD -i $IF_EXT -o IF_DMZ -d $DNS -p $protocolo -dport 53 -j ACCEPT
$I -A FORWARD -i $IF_EXT -o IF_DMZ -d $DMZ_WEB_SRV -p $protocolo -dport 53 -j ACCEPT
done
# No hace falta natear después pq la DMZ ya tiene una IP pública

$I -A FORWARD -m multiport -i $IF_EXT -d $DMZ_WEB_SRV -p tcp -dports 80,443 -j ACCEPT

# Desde la DMZ solo es posible hacer consultas DNS hacia el exterior y al puerto 3306 del servidor de base de datos de la red de
# Servers.
$I -A FORWARD -i $IF_DMZ -o $IF_EXT -p udp -dport 53 -j ACCEPT  # No hace falta natear después pq la DMZ ya tiene una IP pública
$I -A FORWARD -i $IF_DMZ -o $IF_EXT -p tcp -dport 53 -j ACCEPT  # No hace falta natear después pq la DMZ ya tiene una IP pública
$I -A FORWARD -i $IF_DMZ -o $IF_SRV -d $DB_SRV -p tcp -dport 3306 -j ACCEPT

# La red de servers no tiene ningún tipo de acceso (solo para responder al servidor web)
#$I -A FORWARD -i $IF_SRV -j DROP
$I -A FORWARD -j DROP

# Tabla NAT

# Pcs de la LAN: NO tienen acceso a red de servidores, sí al resto del universo.
$I -t nat -A POSTROUTING -s $LAN -o $IF_EXT -j SNAT -to-source $IP_EXT

;;
stop)
$I -F FORWARD
$I -t nat -F POSTROUTING
;;
*)
echo Error de Sintaxis
exit 1
;;
esac