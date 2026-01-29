# 🖥️ Lab Active Directory - BTS SIO SISR

Lab complet d'infrastructure Active Directory sous Windows Server 2025, réalisé dans le cadre d'une remise à niveau BTS SIO option SISR.

## 📋 Vue d'ensemble

Ce projet documente la mise en place d'une infrastructure Active Directory complète avec gestion centralisée des utilisateurs, partages réseau, GPO et mécanismes de sauvegarde/restauration.

**Technologies utilisées :**
- Windows Server 2025 (AD DS, DNS, DHCP)
- Windows 11 Pro (clients domaine)
- VMware Workstation 17
- PowerShell

## 🏗️ Architecture
```
lab.local (Domaine AD)
├── SRV-DC01 (192.168.10.1)
│   ├── Active Directory
│   ├── DNS Server
│   ├── DHCP Server
│   └── Windows Server Backup
│
└── Clients (DHCP 192.168.10.100-200)
    ├── CLIENT01 (Windows 11 Pro)
    └── CLIENT02 (Windows 11 Pro)
```

**Réseau :** VMnet2 (Host-only) - 192.168.10.0/24

## 📚 Documentation

- [01 - Infrastructure et installation](docs/01-infrastructure.md)
- [02 - Active Directory](docs/02-active-directory.md)
- [03 - Partages réseau et permissions NTFS](docs/03-partages-permissions.md)
- [04 - Stratégies de groupe (GPO)](docs/04-gpo.md)
- [05 - Redirection de dossiers](docs/05-redirection-dossiers.md)
- [06 - Sauvegarde et restauration](docs/06-sauvegarde-restauration.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🎯 Compétences démontrées

✅ Installation et configuration Windows Server 2025  
✅ Déploiement Active Directory Domain Services  
✅ Configuration DNS et DHCP  
✅ Gestion des utilisateurs, groupes et OU  
✅ Configuration de partages réseau avec permissions NTFS  
✅ Création et déploiement de GPO  
✅ Scripts de connexion (PowerShell/Batch)  
✅ Redirection de dossiers utilisateurs  
✅ Windows Server Backup  
✅ Corbeille Active Directory  
✅ Troubleshooting méthodique  

## 🔧 Scripts disponibles

- [`logon.bat`](scripts/logon.bat) - Script de connexion utilisateur
- [`logon.ps1`](scripts/logon.ps1) - Version PowerShell du script de connexion
- [`verification-services.ps1`](scripts/verification-services.ps1) - Vérification santé AD/DNS/DHCP

## 📊 Structure Active Directory
```
lab.local
├── LAB-Users
│   ├── Comptabilite
│   ├── RH
│   ├── IT
│   └── Direction
├── LAB-Computers
└── LAB-Groupes
    ├── GRP-Comptabilite
    ├── GRP-RH
    ├── GRP-IT
    └── GRP-Direction
```

## 🚀 Déploiement rapide

Voir [01-infrastructure.md](docs/01-infrastructure.md) pour les instructions complètes de déploiement.

## 📝 Notes

Ce lab a été réalisé dans un environnement VMware isolé (Host-only). Tous les mots de passe utilisés sont des mots de passe de lab et ne doivent pas être utilisés en production.

## 👤 Auteur

**Enzo DUBOIS**  
Diplômé BTS SIO option SISR  
[GitHub](https://github.com/enzooodbs)

---

*Projet réalisé en janvier 2026*