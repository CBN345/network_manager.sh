#!/bin/bash

# ==========================================
# VPS Management & Network Optimizer Script
# Repository: CBN345/network_manager.sh
# ==========================================

# Paleta de Colores Profesional (Estilo DevOps / SysAdmin)
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # Sin color / Reset

# Colores primarios y sobrios
PRIMARY='\033[38;5;39m'   # Azul brillante / profesional
SECONDARY='\033[38;5;80m' # Cian elegante
TEXT_MAIN='\033[38;5;253m' # Blanco suave
TEXT_MUTED='\033[38;5;242m'# Gris tenue para bordes y detalles

# Alertas y estados
SUCCESS='\033[38;5;78m'   # Verde menta
WARNING='\033[38;5;214m'  # Naranja suave
DANGER='\033[38;5;203m'   # Rojo moderado

# Verificación de permisos de Root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${DANGER}[!] Este script debe ejecutarse como root.${NC}"
        exit 1
    fi
}

# Encabezado visual estilizado
show_header() {
    clear
    echo -e "${TEXT_MUTED}┌────────────────────────────────────────────────────────┐${NC}"
    echo -e "${TEXT_MUTED}│${NC} ${PRIMARY}${BOLD}           VPS NETWORK MANAGER & OPTIMIZER            ${NC}${TEXT_MUTED}│${NC}"
    echo -e "${TEXT_MUTED}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# SUBMENÚ 1: Optimización de Red
submenu_optimize() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: OPTIMIZACIÓN DE RED ---${NC}"
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Aplicar/Reaplicar Optimizaciones (BBR + Sysctl)${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${WARNING}[+] Aplicando optimizaciones de red...${NC}"
                cp /etc/sysctl.conf /etc/sysctl.conf.bak 2>/dev/null

                sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
                sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
                sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
                sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf

                cat << 'EOF' >> /etc/sysctl.conf

# Parametros de red optimizados
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_slow_start_after_idle = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_keepalive_time = 300
EOF
                sysctl -p > /dev/null 2>&1
                echo -e "${SUCCESS}[✔] Optimización aplicada con éxito.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 2: Gestión de BadVPN (udpgw)
submenu_badvpn() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: BADVPN UDPGW ---${NC}"
        
        if pgrep -x "badvpn-udpgw" > /dev/null; then
            bv_status="${SUCCESS}Activo (En ejecución)${NC}"
        else
            bv_status="${DANGER}Inactivo / No instalado${NC}"
        fi
        
        echo -e "${TEXT_MAIN}Estado de BadVPN:${NC} $bv_status"
        echo ""
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Instalar / Iniciar BadVPN (Puerto 7300)${NC}"
        echo -e "${PRIMARY}2.${NC} ${TEXT_MAIN}Detener BadVPN${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-2]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${WARNING}[+] Configurando e iniciando BadVPN en puerto 7300...${NC}"
                
                if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
                    wget -q -O /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/dayron15/badvpn/master/badvpn-udpgw" 2>/dev/null || \
                    wget -q -O /usr/local/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/raw/master/badvpn-udpgw" 2>/dev/null
                    chmod +x /usr/local/bin/badvpn-udpgw
                fi

                if [ -f /usr/local/bin/badvpn-udpgw ]; then
                    pkill badvpn-udpgw 2>/dev/null
                    screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10 2>/dev/null || \
                    nohup badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10 >/dev/null 2>&1 &
                    
                    echo -e "${SUCCESS}[✔] BadVPN iniciado en el puerto 7300.${NC}\n"
                else
                    echo -e "${DANGER}[!] No se pudo descargar el binario de BadVPN.${NC}\n"
                fi
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                echo -e "\n${WARNING}[+] Deteniendo BadVPN...${NC}"
                pkill badvpn-udpgw 2>/dev/null
                echo -e "${SUCCESS}[✔] BadVPN detenido correctamente.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 3: Certificados SSL/TLS
submenu_ssl() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: CERTIFICADOS SSL (Let's Encrypt) ---${NC}"
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Instalar Certbot (Herramienta SSL)${NC}"
        echo -e "${PRIMARY}2.${NC} ${TEXT_MAIN}Generar Certificado SSL para un Dominio/Subdominio${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-2]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${WARNING}[+] Instalando Certbot...${NC}"
                apt update -y && apt install certbot -y
                echo -e "${SUCCESS}[✔] Certbot instalado correctamente.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                read -p "Ingresa tu dominio/subdominio (Ej: vps.midominio.com): " domain
                if [ -n "$domain" ]; then
                    echo -e "\n${WARNING}[+] Generando certificado para $domain...${NC}"
                    certbot certonly --standalone -d "$domain" --non-interactive --agree-tos -m admin@"$domain" || certbot certonly --standalone -d "$domain"
                    echo -e "\n${SUCCESS}[✔] Certificados guardados en /etc/letsencrypt/live/$domain/${NC}\n"
                else
                    echo -e "${DANGER}[!] Dominio no válido.${NC}\n"
                fi
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 4: Configurar Proxy HTTP 101 WebSocket
submenu_http101() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: RESPUESTA HTTP 101 WEBSOCKET ---${NC}"
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Instalar Nginx y Crear Configuración HTTP 101 / WS${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${WARNING}[+] Instalando Nginx...${NC}"
                apt update -y && apt install nginx -y
                
                read -p "Ingresa el puerto de escucha (Ej: 80 u 8080): " ws_port
                ws_port=${ws_port:-8080}

                echo -e "\n${WARNING}[+] Creando bloque Nginx en puerto $ws_port para WebSocket 101...${NC}"
                cat << EOF > /etc/nginx/conf.d/websocket101.conf
server {
    listen $ws_port;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:22;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
EOF
                systemctl restart nginx
                echo -e "${SUCCESS}[✔] Nginx configurado en el puerto $ws_port apuntando al puerto SSH (22).${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 5: Estado del Sistema
submenu_status() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: ESTADO DE RED Y SISTEMA ---${NC}"
        
        bbr_status=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
        qdisc_status=$(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}')
        ram_used=$(free -m | awk '/Mem:/ {printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2}')
        uptime_info=$(uptime -p 2>/dev/null || uptime)

        echo -e "${TEXT_MAIN}Controlador de Congestión:${NC} ${SECONDARY}${bbr_status:-No activo}${NC}"
        echo -e "${TEXT_MAIN}Algoritmo de Colas:        ${NC} ${SECONDARY}${qdisc_status:-Estándar}${NC}"
        echo -e "${TEXT_MAIN}Uso de Memoria RAM:        ${NC} ${SECONDARY}${ram_used}${NC}"
        echo -e "${TEXT_MAIN}Tiempo Encendido:          ${NC} ${SECONDARY}${uptime_info}${NC}"
        echo ""
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Actualizar Estado${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1) continue ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 6: Limpieza y Mantenimiento
submenu_clean() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: LIMPIEZA Y MANTENIMIENTO ---${NC}"
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Liberar Memoria Caché RAM${NC}"
        echo -e "${PRIMARY}2.${NC} ${TEXT_MAIN}Limpiar Paquetes Obsoletos del Sistema (apt autoremove)${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-2]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${WARNING}[+] Liberando memoria caché...${NC}"
                sync; echo 3 > /proc/sys/vm/drop_caches
                echo -e "${SUCCESS}[✔] Memoria caché liberada con éxito.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                echo -e "\n${WARNING}[+] Limpiando paquetes obsoletos...${NC}"
                apt autoremove -y && apt clean -y
                echo -e "${SUCCESS}[✔] Sistema limpiado correctamente.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# SUBMENÚ 7: Información y Servicios
submenu_info() {
    while true; do
        show_header
        echo -e "${SECONDARY}${BOLD}--- SUBMENÚ: INFORMACIÓN Y SERVICIOS ---${NC}"
        public_ip=$(curl -s --connect-timeout 3 https://api.ipify.org || echo "No disponible")
        echo -e "${TEXT_MAIN}IP Pública:${NC} ${SECONDARY}${public_ip}${NC}\n"
        echo -e "${TEXT_MUTED}Sockets y Puertos en Escucha:${NC}"
        ss -tulpn | grep LISTEN | awk '{print $1, $5}' | column -t 2>/dev/null || ss -tulpn | grep LISTEN
        echo ""
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Actualizar Información de Puertos e IP${NC}"
        echo -e "${PRIMARY}2.${NC} ${TEXT_MAIN}Reiniciar Servicio Nginx${NC}"
        echo -e "${PRIMARY}3.${NC} ${TEXT_MAIN}Reiniciar Servicio SSH${NC}"
        echo -e "${DANGER}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-3]: " sub_opt

        case $sub_opt in
            1) continue ;;
            2)
                systemctl restart nginx 2>/dev/null && echo -e "${SUCCESS}[✔] Nginx reiniciado.${NC}\n" || echo -e "${DANGER}[!] Nginx no está instalado.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                echo -e "${SUCCESS}[✔] Servicio SSH reiniciado.${NC}\n"
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# FUNCIÓN: Actualizar Script desde GitHub
update_script() {
    show_header
    echo -e "${SECONDARY}${BOLD}--- ACTUALIZACIÓN DEL SCRIPT ---${NC}"
    echo -e "${WARNING}[+] Descargando la última versión del repositorio...${NC}\n"
    
    repo_url="https://raw.githubusercontent.com/CBN345/network_manager.sh/refs/heads/main/optimizacion.sh"
    
    if curl -sSL "$repo_url" -o /tmp/optimizacion_new.sh; then
        if [ -s /tmp/optimizacion_new.sh ]; then
            mv /tmp/optimizacion_new.sh "$0"
            chmod +x "$0"
            echo -e "${SUCCESS}[✔] ¡Script actualizado con éxito! Reejecutando...${NC}\n"
            sleep 1.5
            exec "$0"
        else
            echo -e "${DANGER}[!] El archivo descargado está vacío. Ocurrió un problema.${NC}\n"
        fi
    else
        echo -e "${DANGER}[!] Falló la conexión con GitHub. Revisa la URL o tu red.${NC}\n"
    fi
    read -p "Presiona Enter para regresar al menú..."
}

# MENÚ PRINCIPAL
main_menu() {
    check_root
    while true; do
        show_header
        echo -e "${PRIMARY}1.${NC} ${TEXT_MAIN}Optimizaciones de Red (BBR / Sysctl)${NC}"
        echo -e "${PRIMARY}2.${NC} ${TEXT_MAIN}Gestión de BadVPN (UDP 7300 para Juegos/Voz)${NC}"
        echo -e "${PRIMARY}3.${NC} ${TEXT_MAIN}Generar Certificado SSL (Certbot Let's Encrypt)${NC}"
        echo -e "${PRIMARY}4.${NC} ${TEXT_MAIN}Configurar Encabezado 101 WebSocket (Nginx Proxy)${NC}"
        echo -e "${PRIMARY}5.${NC} ${TEXT_MAIN}Estado de Red y Recursos del VPS${NC}"
        echo -e "${PRIMARY}6.${NC} ${TEXT_MAIN}Limpieza de Memoria Caché y Sistema${NC}"
        echo -e "${PRIMARY}7.${NC} ${TEXT_MAIN}IP Pública, Puertos y Reiniciar Servicios${NC}"
        echo -e "${SECONDARY}8.${NC} ${BOLD}Actualizar Script desde GitHub${NC}"
        echo -e "${DANGER}0. Salir del Script${NC}"
        echo ""
        read -p "Selecciona una opción [0-8]: " option

        case $option in
            1) submenu_optimize ;;
            2) submenu_badvpn ;;
            3) submenu_ssl ;;
            4) submenu_http101 ;;
            5) submenu_status ;;
            6) submenu_clean ;;
            7) submenu_info ;;
            8) update_script ;;
            0) echo -e "${SUCCESS}¡Hasta luego!${NC}"; exit 0 ;;
            *) echo -e "${DANGER}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# Iniciar menú principal
main_menu
