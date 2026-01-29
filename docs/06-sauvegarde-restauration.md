# Sauvegarde et restauration

## Vue d'ensemble

**Mécanismes de protection du lab :**
1. ✅ **Snapshots VMware** (sauvegarde instantanée de l'état des VMs)
2. ✅ **Windows Server Backup** (sauvegarde planifiée de SRV-DC01)
3. ✅ **Corbeille Active Directory** (récupération d'objets AD supprimés)

## 1. Snapshots VMware

### Principe

Un snapshot capture l'état complet d'une VM à un instant T :
- État de la mémoire vive
- État du disque dur
- Configuration VM

**Avantages :**
- ⚡ Instantané (quelques secondes)
- 🔄 Restauration complète en 1 clic
- 🎯 Parfait pour tester des configs risquées

**Inconvénient :**
- Consomme de l'espace disque sur l'hôte

### Création d'un snapshot

**Pour chaque VM (SRV-DC01, CLIENT01, CLIENT02) :**

1. Dans VMware Workstation, clic droit sur la VM
2. **VM → Snapshot → Take Snapshot...**
3. Nom : `Baseline-Lab-Fonctionnel-26jan2026`
4. Description : `AD+DNS+DHCP+GPO+Redirection - Lab complet fonctionnel`
5. ☑️ **Snapshot the virtual machine's memory**
6. **Take Snapshot**

**Note :** Le snapshot avec mémoire capture l'état exact de la RAM. La VM se fige brièvement.

### Gestion des snapshots

**Voir les snapshots :**
1. Clic droit sur VM → **Snapshot → Snapshot Manager**
2. Arborescence des snapshots avec dates

**Restaurer un snapshot :**
1. Snapshot Manager
2. Sélectionner le snapshot
3. **Go To**
4. Confirmer

**Supprimer un snapshot :**
1. Snapshot Manager
2. Sélectionner le snapshot
3. **Delete** (libère l'espace disque)

**⚠️ Important :** La suppression du snapshot fusionne les modifications dans le disque principal. Impossible de restaurer ensuite.

### Snapshots créés dans ce lab

| VM | Snapshot | Date | État |
|----|----------|------|------|
| SRV-DC01 | Baseline-Lab-Fonctionnel-26jan2026 | 26/01/2026 | AD/DNS/DHCP/GPO/Backup actifs |
| CLIENT01 | Baseline-Lab-Fonctionnel-26jan2026 | 26/01/2026 | Domaine + GPO appliquées |
| CLIENT02 | Baseline-Lab-Fonctionnel-26jan2026 | 26/01/2026 | Domaine + GPO appliquées |

## 2. Windows Server Backup

### Principe

Windows Server Backup sauvegarde :
- État du système (AD, DNS, DHCP, Registre)
- Données du serveur (C:\)
- Configuration système complète

### Préparation du disque de sauvegarde

**Ajouter un 2ème disque virtuel à SRV-DC01 :**

1. Éteindre SRV-DC01 proprement
2. VMware : Clic droit sur SRV-DC01 → Settings
3. Add → Hard Disk → SCSI → Create new virtual disk
4. Taille : **50 GB**
5. Store as single file → Finish
6. Redémarrer SRV-DC01

**Initialiser et formater le disque :**
```powershell
# Lister les disques
Get-Disk

# Initialiser le Disk 1
Initialize-Disk -Number 1 -PartitionStyle GPT

# Créer une partition
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter E

# Formater en NTFS
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "Backup" -Confirm:$false
```

**Vérification :**
```powershell
Get-Volume -DriveLetter E
```

### Installation de Windows Server Backup
```powershell
Install-WindowsFeature Windows-Server-Backup -IncludeManagementTools
```

### Configuration de la sauvegarde planifiée

**Ouvrir l'outil graphique :**
- Gestionnaire de serveur → Outils → **Sauvegarde Windows Server**

**Planification de sauvegarde :**

1. Menu Actions → **Planification de sauvegarde...**
2. **Configuration** : Personnalisée → Suivant
3. **Sélectionner les éléments** :
   - ☑️ État du système
   - ☑️ C:\
   - Suivant
4. **Heure** : Une fois par jour à **23:00** → Suivant
5. **Destination** : Sauvegarder sur un disque dur dédié → Suivant
6. **Disque** : ☑️ Disque 1 (50 GB) → Suivant
7. **Avertissement formatage** : Oui
8. **Confirmation** : Terminer

**Résultat :** Sauvegarde quotidienne à 23h automatiquement.

### Lancement manuel d'une sauvegarde

**Pour avoir une première sauvegarde immédiatement :**

1. Menu Actions → **Sauvegarde ponctuelle...**
2. **Options** : Options de sauvegarde planifiées → Suivant
3. **Confirmation** : Sauvegarder
4. Attendre la fin (~5-10 minutes pour la première)

### Vérification de la sauvegarde
```powershell
# Voir le résumé des sauvegardes
Get-WBSummary

# Voir les détails de la dernière sauvegarde
Get-WBJob -Previous 1
```

**Résultat attendu :**
- Dernière sauvegarde : Date et heure récente
- État : Réussite
- Prochaine sauvegarde : Aujourd'hui 23:00

**⚠️ Note :** Le lecteur E: n'est plus accessible après configuration de WSB (c'est normal, Windows en prend possession).

### Test de restauration de fichier

**Créer un fichier test :**
```powershell
New-Item -Path "C:\Partages\Commun\test-backup.txt" -ItemType File -Value "Fichier de test pour validation backup"
```

**Supprimer le fichier :**
```powershell
Remove-Item "C:\Partages\Commun\test-backup.txt" -Force
```

**Restaurer depuis la sauvegarde :**

1. Sauvegarde Windows Server → Menu Actions → **Récupérer...**
2. **Serveur** : Ce serveur (SRV-DC01) → Suivant
3. **Date** : Sélectionner la sauvegarde récente → Suivant
4. **Type** : Fichiers et dossiers → Suivant
5. **Éléments** : Naviguer vers C:\Partages\Commun\ et cocher `test-backup.txt` → Suivant
6. **Emplacement** : Emplacement d'origine → Suivant
7. **Confirmation** : Récupérer

**Vérification :**
```powershell
Get-Content "C:\Partages\Commun\test-backup.txt"
```
Doit afficher : "Fichier de test pour validation backup"

✅ **La restauration fonctionne !**

### Restauration complète du système

**En cas de panne majeure :**

1. Booter sur le DVD d'installation Windows Server
2. Réparer l'ordinateur → Dépannage → Récupération de l'image système
3. Sélectionner la sauvegarde Windows Server Backup
4. Suivre l'assistant

**Note :** Pour les labs, préférer restaurer un snapshot VMware (plus rapide).

## 3. Corbeille Active Directory

### Principe

La corbeille AD conserve les objets supprimés pendant **180 jours** par défaut.

**Objets récupérables :**
- Utilisateurs
- Groupes
- Ordinateurs
- Unités d'organisation

**⚠️ Important :**
- Une fois activée, **ne peut plus être désactivée**
- Seuls les objets supprimés **après activation** sont récupérables
- Nécessite niveau fonctionnel ≥ Windows Server 2008 R2

### Activation de la corbeille AD
```powershell
# Activer la corbeille
Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target "lab.local" -Confirm:$false
```

**Vérification :**
```powershell
Get-ADOptionalFeature -Filter * | Where-Object {$_.Name -like "*Recycle*"} | Select-Object Name, EnabledScopes
```

**Résultat attendu :**
- Name : Recycle Bin Feature
- EnabledScopes : {CN=Partitions,CN=Configuration,DC=lab,DC=local}

### Test de suppression et restauration

**Créer un utilisateur test :**
```powershell
New-ADUser -Name "TestUser" -SamAccountName "testuser" `
  -Path "OU=LAB-Users,DC=lab,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Enabled $true
```

**Supprimer l'utilisateur :**
```powershell
Remove-ADUser testuser -Confirm:$false
```

**Vérifier qu'il n'existe plus :**
```powershell
Get-ADUser testuser
```
❌ Erreur : "Cannot find an object with identity"

**Voir les objets supprimés :**
```powershell
Get-ADObject -Filter {Name -like "TestUser*"} -IncludeDeletedObjects | Select-Object Name, Deleted, DistinguishedName
```

**Résultat :**
- Name : TestUser\0ADEL:...
- Deleted : True
- DistinguishedName : CN=TestUser\0ADEL:...,CN=Deleted Objects,DC=lab,DC=local

**Restaurer l'utilisateur :**
```powershell
Get-ADObject -Filter {Name -like "TestUser*"} -IncludeDeletedObjects | Restore-ADObject
```

**Vérifier la restauration :**
```powershell
Get-ADUser testuser | Select-Object Name, Enabled, DistinguishedName
```

✅ **L'utilisateur est revenu dans LAB-Users, activé !**

**Nettoyage :**
```powershell
Remove-ADUser testuser -Confirm:$false
```

### Restauration d'un groupe

**Même principe :**
```powershell
# Restaurer un groupe supprimé
Get-ADObject -Filter {Name -eq "GRP-Test"} -IncludeDeletedObjects | Restore-ADObject
```

### Restauration d'une OU avec tout son contenu
```powershell
# Restaurer une OU et tous ses objets enfants
Get-ADObject -Filter {Name -eq "LAB-Test"} -IncludeDeletedObjects | Restore-ADObject -Recursive
```

## Stratégie de sauvegarde globale

### Protection en couches

| Niveau | Méthode | Objectif | Fréquence |
|--------|---------|----------|-----------|
| 1 | Snapshots VMware | État complet des VMs | Avant chaque modif majeure |
| 2 | Windows Server Backup | Sauvegarde données serveur | Quotidienne (23h) |
| 3 | Corbeille AD | Récupération objets AD | Automatique (180j rétention) |

### Scénarios de récupération

**Scénario 1 : Utilisateur supprimé par erreur**
→ Corbeille AD (< 5 min)

**Scénario 2 : Fichier supprimé du partage**
→ Windows Server Backup (10-15 min)

**Scénario 3 : GPO mal configurée qui bloque tout**
→ Snapshot VMware (1 min)

**Scénario 4 : Serveur complètement planté**
→ Snapshot VMware (restauration complète)

## Commandes de diagnostic
```powershell
# Vérifier Windows Server Backup
Get-WBSummary
Get-WBJob -Previous 5

# Vérifier la corbeille AD
Get-ADOptionalFeature -Filter {Name -like "*Recycle*"}

# Voir les objets supprimés
Get-ADObject -Filter {isDeleted -eq $true} -IncludeDeletedObjects -Properties * | Select-Object Name, whenChanged, isDeleted

# Vérifier l'espace disque
Get-Volume
```

## Bonnes pratiques

✅ Prendre un snapshot **avant toute modification importante**  
✅ Tester régulièrement les restaurations (1x/mois minimum)  
✅ Vérifier les logs de sauvegarde Windows Server Backup  
✅ Documenter les procédures de restauration  
✅ Conserver plusieurs versions de snapshots  
✅ Surveiller l'espace disque disponible  

❌ Ne pas supprimer les snapshots trop rapidement  
❌ Ne pas oublier de sauvegarder avant tests risqués  
❌ Ne pas ignorer les alertes de sauvegarde échouée  

## Troubleshooting

**Problème : Sauvegarde WSB échoue**
- Vérifier l'espace disponible sur le disque de backup
- Vérifier les logs : Observateur d'événements → Windows → Backup

**Problème : Snapshot VMware consomme trop d'espace**
- Supprimer les anciens snapshots
- Fusionner les snapshots intermédiaires

**Problème : Objet AD non récupérable**
- Vérifier que la corbeille était activée avant suppression
- Vérifier le délai de rétention (180j par défaut)
- Utiliser une sauvegarde WSB pour restaurer l'état système complet