# Partages réseau et permissions NTFS

## Structure des dossiers de partage

### Création de la structure

**Sur SRV-DC01 :**
```powershell
# Créer le répertoire principal
New-Item -Path "C:\Partages" -ItemType Directory

# Créer les sous-dossiers par service
New-Item -Path "C:\Partages\Commun" -ItemType Directory
New-Item -Path "C:\Partages\Comptabilite" -ItemType Directory
New-Item -Path "C:\Partages\IT" -ItemType Directory
New-Item -Path "C:\Partages\Direction" -ItemType Directory
New-Item -Path "C:\Partages\RH" -ItemType Directory
```

**Structure finale :**
```
C:\Partages\
├── Commun
├── Comptabilite
├── IT
├── Direction
└── RH
```

## Configuration des partages réseau

### Partage Commun (accessible par tous)
```powershell
# Créer le partage
New-SmbShare -Name "Commun" -Path "C:\Partages\Commun" -FullAccess "Utilisateurs du domaine"

# Vérifier
Get-SmbShare -Name "Commun"
Get-SmbShareAccess -Name "Commun"
```

### Partages par service (accès restreint)
```powershell
# Partage Comptabilité
New-SmbShare -Name "Comptabilite" -Path "C:\Partages\Comptabilite" -FullAccess "GRP-Comptabilite"

# Partage IT
New-SmbShare -Name "IT" -Path "C:\Partages\IT" -FullAccess "GRP-IT"

# Partage Direction
New-SmbShare -Name "Direction" -Path "C:\Partages\Direction" -FullAccess "GRP-Direction"

# Partage RH
New-SmbShare -Name "RH" -Path "C:\Partages\RH" -FullAccess "GRP-RH"
```

**Vérification de tous les partages :**
```powershell
Get-SmbShare | Where-Object {$_.Name -notlike "*$"}
```

## Configuration des permissions NTFS

### Principe général

**2 niveaux de permissions :**
1. **Permissions de partage** (niveau réseau) : qui peut accéder via le réseau
2. **Permissions NTFS** (niveau fichier) : ce qu'on peut faire une fois connecté

**Règle** : Le plus restrictif des deux s'applique.

### Partage Commun - Permissions standard
```powershell
# Permissions NTFS : Utilisateurs du domaine en Modifier
$acl = Get-Acl "C:\Partages\Commun"
$permission = "LAB\Utilisateurs du domaine","Modify","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Partages\Commun" $acl
```

### Partages par service - Désactivation de l'héritage

**Pour chaque partage métier, on désactive l'héritage et on configure manuellement.**

#### Exemple avec le partage IT

**1. Désactiver l'héritage :**
```powershell
$acl = Get-Acl "C:\Partages\IT"
$acl.SetAccessRuleProtection($true, $false)  # true = désactiver héritage, false = ne pas copier les ACL existantes
Set-Acl "C:\Partages\IT" $acl
```

**2. Ajouter les permissions manuellement :**
```powershell
$acl = Get-Acl "C:\Partages\IT"

# SYSTEM - Contrôle total
$permission = "NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)

# Administrateurs - Contrôle total
$permission = "BUILTIN\Administrateurs","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)

# Groupe IT - Modifier
$permission = "LAB\GRP-IT","Modify","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)

Set-Acl "C:\Partages\IT" $acl
```

**Vérification :**
```powershell
Get-Acl "C:\Partages\IT" | Format-List
```

#### Répéter pour les autres partages

**Comptabilité :**
```powershell
# Désactiver héritage
$acl = Get-Acl "C:\Partages\Comptabilite"
$acl.SetAccessRuleProtection($true, $false)
Set-Acl "C:\Partages\Comptabilite" $acl

# Ajouter permissions
$acl = Get-Acl "C:\Partages\Comptabilite"
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrateurs","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("LAB\GRP-Comptabilite","Modify","ContainerInherit,ObjectInherit","None","Allow")))
Set-Acl "C:\Partages\Comptabilite" $acl
```

**Direction :**
```powershell
$acl = Get-Acl "C:\Partages\Direction"
$acl.SetAccessRuleProtection($true, $false)
Set-Acl "C:\Partages\Direction" $acl

$acl = Get-Acl "C:\Partages\Direction"
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrateurs","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("LAB\GRP-Direction","Modify","ContainerInherit,ObjectInherit","None","Allow")))
Set-Acl "C:\Partages\Direction" $acl
```

**RH :**
```powershell
$acl = Get-Acl "C:\Partages\RH"
$acl.SetAccessRuleProtection($true, $false)
Set-Acl "C:\Partages\RH" $acl

$acl = Get-Acl "C:\Partages\RH"
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrateurs","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("LAB\GRP-RH","Modify","ContainerInherit,ObjectInherit","None","Allow")))
Set-Acl "C:\Partages\RH" $acl
```

## Vérification des permissions

### Permissions de partage
```powershell
Get-SmbShareAccess -Name "IT"
```

**Résultat attendu :**
```
Name ScopeName AccountName          AccessControlType AccessRight
---- --------- -----------          ----------------- -----------
IT   *         LAB\GRP-IT           Allow             Full
```

### Permissions NTFS
```powershell
Get-Acl "C:\Partages\IT" | Format-List
```

**Résultat attendu :**
- SYSTEM : Contrôle total
- Administrateurs : Contrôle total
- GRP-IT : Modifier

## Test d'accès depuis un client

### Sur CLIENT01 (connecté avec cdeux, membre de GRP-IT)

**Accès au partage IT :**
```cmd
\\SRV-DC01\IT
```
✅ Doit fonctionner (lecture/écriture)

**Tentative d'accès au partage Comptabilite :**
```cmd
\\SRV-DC01\Comptabilite
```
❌ Doit refuser (pas membre du groupe)

## Tableau récapitulatif des permissions

| Partage | Permissions partage | Permissions NTFS | Groupe autorisé |
|---------|---------------------|------------------|-----------------|
| Commun | Utilisateurs du domaine : Contrôle total | Utilisateurs du domaine : Modifier | Tous |
| Comptabilite | GRP-Comptabilite : Contrôle total | GRP-Comptabilite : Modifier | GRP-Comptabilite |
| IT | GRP-IT : Contrôle total | GRP-IT : Modifier | GRP-IT |
| Direction | GRP-Direction : Contrôle total | GRP-Direction : Modifier | GRP-Direction |
| RH | GRP-RH : Contrôle total | GRP-RH : Modifier | GRP-RH |

**Permissions communes à tous les partages (NTFS) :**
- SYSTEM : Contrôle total
- Administrateurs : Contrôle total

## Troubleshooting

**Problème : Accès refusé malgré appartenance au groupe**
```powershell
# Vérifier l'appartenance
Get-ADGroupMember -Identity "GRP-IT"

# Vérifier les permissions du partage
Get-SmbShareAccess -Name "IT"

# Vérifier les permissions NTFS
Get-Acl "C:\Partages\IT" | Format-List
```

**Solution courante :** Déconnexion/reconnexion pour rafraîchir le token Kerberos du client.

**Problème : Permissions héritées non désirées**
- Vérifier si l'héritage est bien désactivé :
```powershell
$acl = Get-Acl "C:\Partages\IT"
$acl.AreAccessRulesProtected  # Doit être True
```