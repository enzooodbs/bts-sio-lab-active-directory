# Infrastructure et installation

## Environnement hôte

**Configuration PC :**
- Processeur : Intel i5-13600K
- RAM : 32 Go
- Stockage : SSD NVMe 2 To
- Virtualisation : VMware Workstation 17

## Réseau virtuel VMware

**Configuration VMnet2 (Host-only) :**
- Subnet : 192.168.10.0/24
- DHCP VMware : Désactivé (géré par SRV-DC01)

**Création du réseau :**
1. VMware → Edit → Virtual Network Editor
2. Add Network → VMnet2
3. Type : Host-only
4. Subnet IP : 192.168.10.0
5. Subnet mask : 255.255.255.0
6. Décocher "Use local DHCP service"

## Machine virtuelle : SRV-DC01 (Contrôleur de domaine)

### Spécifications
- **OS** : Windows Server 2025 Standard (Desktop Experience)
- **Firmware** : UEFI
- **Secure Boot** : Activé
- **TPM** : 2.0
- **RAM** : 6144 MB (6 Go)
- **CPU** : 4 cores
- **Disque 1** : 60 Go (système)
- **Disque 2** : 50 Go (sauvegardes)
- **Réseau** : VMnet2

### Installation Windows Server 2025

**Prérequis VMware :**
```
Firmware : UEFI
Secure Boot : Yes
TPM : Present (2.0)
```

**Installation :**
1. Créer la VM avec UEFI
2. Monter l'ISO Windows Server 2025
3. Boot sur l'ISO
4. Installation : Custom
5. Supprimer toutes les partitions existantes
6. Créer une nouvelle partition (utilise tout l'espace)
7. Installer

**Configuration initiale :**
```powershell
# Définir le mot de passe administrateur
net user Administrateur Motdepasse1
```

⚠️ **Important :** Utiliser "Administrateur" (français), pas "Administrator"

**Configuration réseau statique :**
```powershell
# Identifier l'interface
Get-NetAdapter

# Configuration IP statique
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 192.168.10.1 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1
```

**Vérification :**
```powershell
Get-NetIPAddress -InterfaceAlias "Ethernet0"
Get-DnsClientServerAddress -InterfaceAlias "Ethernet0"
```

**Renommer le serveur :**
```powershell
Rename-Computer -NewName "SRV-DC01" -Restart
```

### Connexion automatique (optionnel)

Pour éviter de taper le mot de passe à chaque démarrage en environnement lab :
```
regedit
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon

DefaultUserName = Administrateur
DefaultPassword = Motdepasse1
AutoAdminLogon = 1
```

## Machines virtuelles : CLIENT01 & CLIENT02

### Spécifications (identiques)
- **OS** : Windows 11 Pro 25H2
- **Firmware** : UEFI
- **Secure Boot** : Activé
- **TPM** : 2.0
- **RAM** : 4096 MB (4 Go)
- **CPU** : 2 cores
- **Disque** : 60 Go
- **Réseau** : VMnet2

### Configuration réseau
- **IP** : DHCP (attribuée par SRV-DC01)
- **DNS** : 192.168.10.1 (automatique via DHCP)
- **Passerelle** : 192.168.10.1 (automatique via DHCP)

### Compte local CLIENT02
- Utilisateur : utilisateur
- Mot de passe : Motdepasse1

## Snapshots de sauvegarde

Après configuration complète du lab :

**Pour chaque VM :**
1. Clic droit → Snapshot → Take Snapshot
2. Nom : `Baseline-Lab-Fonctionnel-26jan2026`
3. ☑️ Snapshot the virtual machine's memory
4. Take Snapshot

**VMs sauvegardées :**
- ✅ SRV-DC01
- ✅ CLIENT01
- ✅ CLIENT02

## Commandes de vérification réseau

**Sur le serveur :**
```powershell
Get-NetIPAddress
Get-DnsClientServerAddress
Test-NetConnection -ComputerName 192.168.10.1
```

**Sur les clients :**
```cmd
ipconfig /all
ping 192.168.10.1
nslookup lab.local
```

## Troubleshooting commun

**Problème : IP APIPA (169.254.x.x) sur client**
- Cause : Serveur éteint ou DHCP non démarré
- Solution :
```cmd
  ipconfig /release
  ipconfig /renew
```

**Problème : Pas de résolution DNS**
- Vérifier que DNS pointe vers 192.168.10.1
- Vérifier service DNS sur serveur :
```powershell
  Get-Service DNS
  Restart-Service DNS
```