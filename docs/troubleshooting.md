# Guide de dépannage (Troubleshooting)

## Problèmes rencontrés et solutions

Ce document recense tous les problèmes rencontrés lors de la mise en place du lab et leurs solutions.

---

## 1. Installation Windows Server

### ❌ Problème : Boot en Network au lieu du disque

**Symptôme :** La VM tente de booter en PXE au lieu de l'ISO.

**Cause :** Boot order mal configuré ou firmware en BIOS au lieu d'UEFI.

**Solution :**
1. Configurer la VM en **firmware UEFI**
2. VMware → VM Settings → Options → Advanced → Firmware type : **UEFI**
3. Supprimer toutes les partitions existantes lors de l'install
4. Créer une nouvelle partition propre

---

## 2. Active Directory

### ❌ Problème : Promotion AD échoue (mot de passe vide)

**Symptôme :**
```
Install-ADDSForest échoue avec erreur mot de passe administrateur
```

**Cause :** Le compte Administrateur local n'a pas de mot de passe.

**Solution :**
```powershell
net user Administrateur Motdepasse1
```

**⚠️ Important :** Utiliser "Administrateur" (français), **pas "Administrator"**.

---

## 3. Réseau et DHCP

### ❌ Problème : Client obtient une IP APIPA (169.254.x.x)

**Symptôme :**
```cmd
ipconfig
# Affiche : 169.254.x.x au lieu de 192.168.10.x
```

**Cause :** Serveur éteint ou service DHCP non démarré.

**Solution :**
1. Démarrer SRV-DC01
2. Attendre que tous les services démarrent (AD, DNS, DHCP)
3. Sur le client :
```cmd
ipconfig /release
ipconfig /renew
```

**Vérification sur le serveur :**
```powershell
Get-Service DHCP
Restart-Service DHCP
```

---

### ❌ Problème : Client ne résout pas le domaine lab.local

**Symptôme :**
```cmd
nslookup lab.local
# Erreur : Can't find lab.local: Non-existent domain
```

**Cause :** Le client ne pointe pas vers le bon serveur DNS (192.168.10.1).

**Solution :**
1. Vérifier la config DHCP sur le serveur :
```powershell
Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0
```
DNS doit être : 192.168.10.1

2. Sur le client, renouveler l'IP :
```cmd
ipconfig /release
ipconfig /renew
ipconfig /all
```
DNS Servers doit afficher : 192.168.10.1

---

## 4. Stratégies de groupe (GPO)

### ❌ Problème : Scripts PowerShell ne s'exécutent pas (fenêtre blanche figée)

**Symptôme :** Script .ps1 avec interface WPF affiche une fenêtre blanche qui ne répond pas.

**Cause :** Code WPF incompatible ou mal configuré.

**Solution :** Utiliser `msg *` au lieu de MessageBox WPF :
```powershell
msg * "Message ici"
```

---

### ❌ Problème : GPO scripts refusés (liaison lente détectée)

**Symptôme :**
```cmd
gpresult /r
# Affiche : "Les objets stratégie de groupe n'ont pas été appliqués car ils ont été refusés"
```

**Cause :** Windows détecte une liaison réseau lente (< 500 kbps) et refuse d'appliquer les scripts classiques.

**Solution :** **Ne PAS utiliser les scripts classiques** (Configuration utilisateur → Stratégies → Scripts).

**✅ Solution robuste : Tâches planifiées via Préférences GPO**

**Chemin :**
```
Configuration utilisateur
└── Préférences
    └── Paramètres du Panneau de configuration
        └── Tâches planifiées
```

**Configuration :**
- Type : Tâche immédiate
- Déclencheur : À l'ouverture de session
- Action : `cmd.exe /c msg * "Message"`

**Alternative (non recommandée) :** Modifier la Default Domain Policy pour autoriser les scripts sur liaison lente (peut causer d'autres problèmes).

---

### ❌ Problème : Script non trouvé dans SYSVOL

**Symptôme :**
```
Le système ne peut pas trouver le fichier spécifié : \\lab.local\SysVol\...
```

**Cause :** Le script .bat ou .ps1 n'est pas dans le bon dossier SYSVOL.

**Solution :**
```powershell
# Trouver le GUID de la GPO
Get-GPO -Name "GPO-Script-Logon" | Select-Object Id

# Copier le script dans le bon emplacement
Copy-Item "C:\Scripts\logon.bat" "\\lab.local\SysVol\lab.local\Policies\{GUID}\User\Scripts\Logon\"
```

**Mais rappel : Utiliser les tâches planifiées GPO est plus fiable.**

---

### ❌ Problème : Fond d'écran GPO disparaît après redémarrage

**Symptôme :** Le fond d'écran s'applique bien, puis disparaît au redémarrage suivant.

**Cause :** Cache GPO corrompu ou chemin UNC temporairement inaccessible.

**Solution :**
1. Sur le client :
```cmd
gpupdate /force
```

2. Redémarrer complètement :
```cmd
shutdown /r /t 0
```

3. Vérifier l'accès au partage :
```cmd
dir \\SRV-DC01\Commun
```

Si le problème persiste, régénérer la GPO.

---

### ❌ Problème : GPO ne s'applique pas du tout

**Diagnostic étape par étape :**

**1. Vérifier la liaison :**
```powershell
Get-GPInheritance -Target "DC=lab,DC=local"
```
La GPO doit apparaître dans la liste.

**2. Vérifier le filtrage de sécurité :**
- Ouvrir la GPO → Onglet Étendue
- Vérifier que "Utilisateurs authentifiés" (ou le groupe cible) a le droit "Appliquer la stratégie de groupe"

**3. Forcer la mise à jour :**
```cmd
gpupdate /force
```

**4. Vérifier l'application :**
```cmd
gpresult /r
```
Regarder la section "Objets stratégie de groupe appliqués".

**5. Vérifier les logs :**
```
Observateur d'événements
└── Journaux des applications et des services
    └── Microsoft
        └── Windows
            └── GroupPolicy
                └── Operational
```

---

## 5. Redirection de dossiers

### ❌ Problème : Accès refusé à C:\Redirections\cun depuis l'admin

**Symptôme :**
```powershell
Get-ChildItem C:\Redirections\cun
# Erreur : Accès refusé
```

**Cause :** Permissions CREATOR OWNER empêchent l'accès de l'admin.

**Explication :** **C'est NORMAL et VOULU.** CREATOR OWNER donne le contrôle exclusif à l'utilisateur propriétaire (cun).

**Solution si vraiment nécessaire (support technique) :**
```powershell
# Prendre temporairement possession
takeown /F "C:\Redirections\cun" /R /D Y
icacls "C:\Redirections\cun" /grant Administrateurs:F /T
```

**⚠️ Attention :** Cela modifie les permissions. À faire uniquement en cas de nécessité absolue.

---

### ❌ Problème : Dossiers ne se redirigent pas

**Diagnostic :**
```cmd
gpresult /h C:\gpo-report.html
```
Ouvrir le rapport, chercher "Redirection de dossiers" et vérifier les erreurs.

**Logs :**
```
Observateur d'événements
└── Journaux des applications et des services
    └── Microsoft
        └── Windows
            └── Folder Redirection
                └── Operational
```

**Causes courantes :**
- Partage inaccessible : `\\SRV-DC01\Redirections$`
- Permissions NTFS mal configurées sur C:\Redirections
- GPO pas liée ou pas appliquée

---

## 6. Partages réseau

### ❌ Problème : Utilisateur ne peut pas accéder au partage de son service

**Diagnostic :**

**1. Vérifier l'appartenance au groupe :**
```powershell
Get-ADGroupMember -Identity "GRP-IT"
```
L'utilisateur doit apparaître.

**2. Vérifier les permissions de partage :**
```powershell
Get-SmbShareAccess -Name "IT"
```
Le groupe doit avoir "Full" ou "Change".

**3. Vérifier les permissions NTFS :**
```powershell
Get-Acl "C:\Partages\IT" | Format-List
```
Le groupe doit avoir "Modify" minimum.

**4. Déconnecter/reconnecter l'utilisateur**
→ Rafraîchir le token Kerberos pour prendre en compte l'appartenance au groupe.

---

## 7. Sauvegarde et restauration

### ❌ Problème : Lecteur E: n'apparaît plus après config WSB

**Symptôme :**
```powershell
Get-Volume -DriveLetter E
# Erreur : Cannot find drive
```

**Cause :** Windows Server Backup prend possession exclusive du disque.

**Explication :** **C'est NORMAL.** Le disque est géré par WSB, plus de lettre de lecteur accessible.

**Vérification :**
```powershell
Get-WBSummary
```
Si ça affiche les infos de sauvegarde, tout va bien.

---

### ❌ Problème : Sauvegarde WSB échoue

**Diagnostic :**
```powershell
Get-WBJob -Previous 1
```

**Logs détaillés :**
```
Observateur d'événements
└── Journaux Windows
    └── Application
        → Filtrer par source : "Windows Backup"
```

**Causes courantes :**
- Espace disque insuffisant sur le disque de backup
- Service VSS (Volume Shadow Copy) non démarré
- Permissions insuffisantes

**Solutions :**
```powershell
# Vérifier l'espace
Get-Volume

# Vérifier le service VSS
Get-Service VSS
Restart-Service VSS

# Relancer une sauvegarde manuelle
Start-WBBackup -BackupTarget $target
```

---

## 8. Divers

### ❌ Problème : Erreur Out-File avec chemins UNC

**Symptôme :**
```powershell
"Texte" | Out-File "\\SRV-DC01\Scripts\log.txt"
# Erreur
```

**Cause :** Out-File ne supporte pas bien les chemins UNC.

**Solution :** Utiliser `Set-Content` :
```powershell
"Texte" | Set-Content "\\SRV-DC01\Scripts\log.txt"
```

Ou logger en local puis copier :
```powershell
"Texte" | Out-File "C:\Temp\log.txt"
Copy-Item "C:\Temp\log.txt" "\\SRV-DC01\Scripts\"
```

---

## Commandes de diagnostic générales

### Sur le serveur
```powershell
# Vérifier tous les services critiques
Get-Service NTDS, DNS, DHCP | Select-Object Name, Status

# Vérifier la réplication AD
repadmin /replsummary

# Voir les GPO appliquées
Get-GPInheritance -Target "DC=lab,DC=local"

# Voir les utilisateurs du domaine
Get-ADUser -Filter * | Select-Object Name, Enabled

# Voir les ordinateurs du domaine
Get-ADComputer -Filter * | Select-Object Name

# Vérifier les partages
Get-SmbShare

# Vérifier les sauvegardes
Get-WBSummary
```

### Sur le client
```cmd
REM Infos réseau complètes
ipconfig /all

REM Tester la connectivité
ping 192.168.10.1

REM Résolution DNS
nslookup lab.local

REM GPO appliquées
gpresult /r
gpresult /h C:\gpo-report.html

REM Forcer mise à jour GPO
gpupdate /force

REM Qui suis-je ?
whoami

REM Accès aux partages
net use
```

---

## Méthodologie de dépannage

**Approche systématique :**

1. **Identifier le symptôme précis**
   - Quel est le comportement attendu ?
   - Quel est le comportement observé ?

2. **Isoler la cause**
   - Le problème est-il côté serveur ou client ?
   - Est-ce un problème réseau, AD, GPO, permissions ?

3. **Vérifier les fondamentaux**
   - Connectivité réseau : `ping 192.168.10.1`
   - Résolution DNS : `nslookup lab.local`
   - Services serveur : `Get-Service NTDS, DNS, DHCP`

4. **Consulter les logs**
   - Observateur d'événements (serveur et client)
   - `gpresult /h` pour les GPO
   - Logs WSB pour les sauvegardes

5. **Tester avec un utilisateur/ordinateur test**
   - Créer un user de test
   - Vérifier si le problème se reproduit

6. **Appliquer la solution**
   - Documenter ce qui a fonctionné
   - Vérifier que le problème est résolu

7. **Documenter**
   - Ajouter la solution à ce guide
   - Expliquer la cause racine

---

## Ressources utiles

**Documentation Microsoft :**
- Active Directory : https://learn.microsoft.com/windows-server/identity/ad-ds/
- Group Policy : https://learn.microsoft.com/windows-server/identity/ad-ds/manage/group-policy/
- Windows Server Backup : https://learn.microsoft.com/windows-server/administration/windows-server-backup/

**Communauté :**
- r/sysadmin (Reddit)
- Server Fault (Stack Exchange)
- TechNet Forums