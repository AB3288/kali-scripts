#!/bin/bash

# ============================================================
#   Script d'installation : Cisco Packet Tracer 9.0
#   Compatible : Kali Linux (2024/2025/2026)
# ============================================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Bannière
clear
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║        Installation Cisco Packet Tracer 9.0          ║"
echo "║              Kali Linux - Script Auto                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# Vérifications préliminaires
# ============================================================

# Vérifier que le script n'est pas lancé en root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERREUR] Ne lance pas ce script en root.${NC}"
    echo -e "${YELLOW}Utilise : bash install_packet_tracer.sh${NC}"
    exit 1
fi

USER_NAME=$(whoami)
echo -e "${GREEN}[INFO] Utilisateur : $USER_NAME${NC}"

# Chercher le fichier .deb de Packet Tracer
DEB_FILE=$(find ~/Downloads ~/Desktop /tmp -name "CiscoPacketTracer*.deb" 2>/dev/null | head -1)

if [ -z "$DEB_FILE" ]; then
    echo -e "\n${RED}[ERREUR] Fichier CiscoPacketTracer*.deb introuvable !${NC}"
    echo -e "${YELLOW}"
    echo "  Tu dois d'abord télécharger Packet Tracer depuis :"
    echo "  → https://www.netacad.com/portal/resources/packet-tracer"
    echo "  → Choisis la version : Ubuntu 64bit (.deb)"
    echo "  → Place le fichier dans ~/Downloads"
    echo -e "${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO] Fichier trouvé : $DEB_FILE${NC}"
echo ""
echo -e "${YELLOW}Prêt à installer Cisco Packet Tracer. Continuer ? (o/n)${NC}"
read -p "> " CONFIRM
if [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]]; then
    echo "Installation annulée."
    exit 0
fi

# ============================================================
# ÉTAPE 1 : Mise à jour du système
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 1/7] Mise à jour du système...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo apt update -y
echo -e "${GREEN}[✓] Système mis à jour.${NC}"

# ============================================================
# ÉTAPE 2 : Dépendances de base
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 2/7] Installation des dépendances...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo apt install -y \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libpcre2-dev \
    fuse2fs \
    equivs
echo -e "${GREEN}[✓] Dépendances installées.${NC}"

# ============================================================
# ÉTAPE 3 : Créer un faux paquet libfuse2
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 3/7] Création du paquet libfuse2 (workaround)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Vérifier si libfuse2 est déjà installé
if dpkg -l | grep -q "^ii.*libfuse2"; then
    echo -e "${YELLOW}[INFO] libfuse2 déjà installé, on passe.${NC}"
else
    cat <<EOF > /tmp/libfuse2-fake.control
Section: misc
Priority: optional
Standards-Version: 3.9.2
Package: libfuse2
Version: 2.9.9
Description: fake libfuse2 for Packet Tracer compatibility
EOF
    cd /tmp && equivs-build libfuse2-fake.control > /dev/null 2>&1
    sudo dpkg -i /tmp/libfuse2_2.9.9_all.deb
    echo -e "${GREEN}[✓] Paquet libfuse2 créé et installé.${NC}"
fi

# ============================================================
# ÉTAPE 4 : Installer Packet Tracer
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 4/7] Installation de Cisco Packet Tracer...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo dpkg -i "$DEB_FILE"
sudo apt --fix-broken install -y
echo -e "${GREEN}[✓] Packet Tracer installé.${NC}"

# ============================================================
# ÉTAPE 5 : Extraire l'AppImage (fix FUSE)
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 5/7] Extraction AppImage (fix libfuse.so.2)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "/opt/pt-extracted" ]; then
    echo -e "${YELLOW}[INFO] /opt/pt-extracted existe déjà, on passe.${NC}"
else
    cd /tmp
    /usr/local/bin/packettracer --appimage-extract > /dev/null 2>&1
    if [ -d "/tmp/squashfs-root" ]; then
        sudo mv /tmp/squashfs-root /opt/pt-extracted
        echo -e "${GREEN}[✓] AppImage extraite dans /opt/pt-extracted.${NC}"
    else
        echo -e "${RED}[ERREUR] Extraction échouée. Essai alternatif...${NC}"
        # Télécharger libfuse.so.2 réel
        wget -q https://snapshot.debian.org/archive/debian/20230611T210420Z/pool/main/f/fuse/libfuse2_2.9.9-7_amd64.deb -O /tmp/libfuse2-real.deb
        sudo dpkg -x /tmp/libfuse2-real.deb /tmp/libfuse2-extract
        sudo cp /tmp/libfuse2-extract/usr/lib/x86_64-linux-gnu/libfuse.so.2* /usr/lib/x86_64-linux-gnu/ 2>/dev/null
        sudo ldconfig
    fi
fi
echo -e "${GREEN}[✓] Fix FUSE appliqué.${NC}"

# ============================================================
# ÉTAPE 6 : Créer un alias et raccourci
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 6/7] Création du raccourci...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Créer script de lancement
sudo tee /usr/local/bin/pt > /dev/null <<'LAUNCHER'
#!/bin/bash
if [ -f "/opt/pt-extracted/AppRun" ]; then
    /opt/pt-extracted/AppRun "$@"
else
    /usr/local/bin/packettracer "$@"
fi
LAUNCHER
sudo chmod +x /usr/local/bin/pt

# Ajouter alias dans .zshrc et .bashrc
for RC in ~/.zshrc ~/.bashrc; do
    if [ -f "$RC" ]; then
        if ! grep -q "alias packettracer=" "$RC"; then
            echo "alias packettracer='/usr/local/bin/pt'" >> "$RC"
        fi
    fi
done

# Créer raccourci bureau
cat > ~/Desktop/PacketTracer.desktop <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Cisco Packet Tracer
Comment=Network Simulation Tool
Exec=/usr/local/bin/pt
Icon=/opt/pt/art/app.png
Terminal=false
Categories=Education;Network;
DESKTOP
chmod +x ~/Desktop/PacketTracer.desktop

echo -e "${GREEN}[✓] Raccourci créé : commande 'pt' et icône bureau.${NC}"

# ============================================================
# ÉTAPE 7 : Vérification finale
# ============================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[ÉTAPE 7/7] Vérification finale...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f "/usr/local/bin/packettracer" ]; then
    echo -e "${GREEN}[✓] Packet Tracer installé avec succès !${NC}"
else
    echo -e "${RED}[✗] Problème détecté, vérifie les erreurs ci-dessus.${NC}"
fi

# ============================================================
# RÉSUMÉ FINAL
# ============================================================
echo -e "\n${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║               Installation Terminée !                ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Pour lancer Packet Tracer :                         ║"
echo "║                                                      ║"
echo "║    → Commande :  pt                                  ║"
echo "║    → Ou :        /opt/pt-extracted/AppRun            ║"
echo "║    → Ou :        Double-clic sur le bureau           ║"
echo "║                                                      ║"
echo "║  ⚠️  Connecte-toi avec ton compte Netacad            ║"
echo "║     au premier lancement !                           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Lancer Packet Tracer automatiquement
echo -e "${YELLOW}Lancer Packet Tracer maintenant ? (o/n)${NC}"
read -p "> " LAUNCH
if [[ "$LAUNCH" == "o" || "$LAUNCH" == "O" ]]; then
    /usr/local/bin/pt &
fi
