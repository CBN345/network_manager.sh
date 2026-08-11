#!/bin/bash

# ==========================================
# VPS Management & Network Optimizer Script
# ==========================================

# Colores para la interfaz
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Verificación de permisos de Root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Este script debe ejecutarse como root.${NC}"
        exit 1
    fi
}

# Encabezado visual
show_header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}           VPS NETWORK MANAGER & OPTIMIZER          ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo ""
}

# SUBMENÚ 1: Optimización de Red
submenu_optimize() {
    while true; do
        show_header
        echo -e "${YELLOW}--- SUBMENÚ: OPTIMIZACIÓN DE RED ---${NC}"
        echo -e "${YELLOW}1.${NC} Aplicar/Reaplicar Optimizaciones (BBR + Sysctl)"
        echo -e "${RED}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${YELLOW}[+] Aplicando optimizaciones de red...${NC}"
                cp /etc/sysctl.conf /etc/sysctl.conf.bak 2>/dev/null

                # Limpiar entradas anteriores
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

                # Escribir parámetros
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
                echo -e "${GREEN}[✔] Optimización aplicada con éxito.${NC}\n"
                read -p "Presiona Enter para continuar en este submenú..."
                ;;
            0)
                break # Sale del bucle del submenú y vuelve al menú principal
                ;;
            *)
                echo -e "${RED}[!] Opción inválida.${NC}"
                sleep 1
                ;;
        esac
    done
}

# SUBMENÚ 2: Estado del Sistema
submenu_status() {
    while true; do
        show_header
        echo -e "${YELLOW}--- SUBMENÚ: ESTADO DE RED Y SISTEMA ---${NC}"
        
        bbr_status=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
        qdisc_status=$(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}')
        ram_used=$(free -m | awk '/Mem:/ {printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2}')
        uptime_info=$(uptime -p 2>/dev/null || uptime)

        echo -e "Controlador de Congestión: ${CYAN}${bbr_status:-No activo}${NC}"
        echo -e "Algoritmo de Colas:         ${CYAN}${qdisc_status:-Estándar}${NC}"
        echo -e "Uso de Memoria RAM:         ${CYAN}${ram_used}${NC}"
        echo -e "Tiempo Encendido:           ${CYAN}${uptime_info}${NC}"
        echo ""
        echo -e "${YELLOW}1.${NC} Actualizar Estado"
        echo -e "${RED}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                continue # Recarga la pantalla del submenú con datos frescos
                ;;
            0)
                break # Regresa al menú principal
                ;;
            *)
                echo -e "${RED}[!] Opción inválida.${NC}"
                sleep 1
                ;;
        esac
    done
}

# SUBMENÚ 3: Limpieza de Caché
submenu_clean() {
    while true; do
        show_header
        echo -e "${YELLOW}--- SUBMENÚ: LIMPIEZA DE MEMORIA ---${NC}"
        echo -e "${YELLOW}1.${NC} Ejecutar Limpieza de Memoria Caché RAM"
        echo -e "${RED}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                echo -e "\n${YELLOW}[+] Liberando memoria caché...${NC}"
                sync; echo 3 > /proc/sys/vm/drop_caches
                echo -e "${GREEN}[✔] Memoria caché liberada con éxito.${NC}\n"
                read -p "Presiona Enter para continuar en este submenú..."
                ;;
            0)
                break # Regresa al menú principal
                ;;
            *)
                echo -e "${RED}[!] Opción inválida.${NC}"
                sleep 1
                ;;
        esac
    done
}

# SUBMENÚ 4: Información de Conexión y Puertos
submenu_info() {
    while true; do
        show_header
        echo -e "${YELLOW}--- SUBMENÚ: INFORMACIÓN DE RED ---${NC}"
        public_ip=$(curl -s --connect-timeout 3 https://api.ipify.org || echo "No disponible")
        echo -e "IP Pública: ${CYAN}${public_ip}${NC}\n"
        echo -e "${YELLOW}Sockets y Puertos en Escucha:${NC}"
        ss -tulpn | grep LISTEN | awk '{print $1, $5}' | column -t 2>/dev/null || ss -tulpn | grep LISTEN
        echo ""
        echo -e "${YELLOW}1.${NC} Actualizar Información de Puertos e IP"
        echo -e "${RED}0. Regresar al Menú Principal${NC}"
        echo ""
        read -p "Selecciona una opción [0-1]: " sub_opt

        case $sub_opt in
            1)
                continue # Recarga la vista de puertos
                ;;
            0)
                break # Regresa al menú principal
                ;;
            *)
                echo -e "${RED}[!] Opción inválida.${NC}"
                sleep 1
                ;;
        esac
    done
}

# MENÚ PRINCIPAL
main_menu() {
    check_root
    while true; do
        show_header
        echo -e "${YELLOW}1.${NC} Optimizaciones de Red (BBR / Sysctl)"
        echo -e "${YELLOW}2.${NC} Estado de Red y Recursos"
        echo -e "${YELLOW}3.${NC} Limpieza de Memoria Caché"
        echo -e "${YELLOW}4.${NC} IP Pública y Puertos en Escucha"
        echo -e "${RED}0. Salir del Script${NC}"
        echo ""
        read -p "Selecciona una opción [0-4]: " option

        case $option in
            1) submenu_optimize ;;
            2) submenu_status ;;
            3) submenu_clean ;;
            4) submenu_info ;;
            0) echo -e "${GREEN}¡Hasta luego!${NC}"; exit 0 ;;
            *) echo -e "${RED}[!] Opción inválida.${NC}"; sleep 1 ;;
        esac
    done
}

# Iniciar menú principal
main_menu
