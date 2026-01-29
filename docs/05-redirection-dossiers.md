# Redirection de dossiers utilisateurs

## Principe

La redirection de dossiers permet de stocker les dossiers utilisateur (Documents, Bureau, etc.) sur un serveur de fichiers au lieu du disque local. 

**Avantages :**
- ✅ Sauvegarde centralisée
- ✅ Disponible depuis n'importe quel poste
- ✅ Pas de perte de données si le poste plante
- ✅ Quota et supervision possibles

## Préparation du serveur

### Création du dossier de redirection

**Sur SRV-DC01 :**
```powershell
# Créer le dossier racine
New-Item -Path "C:\Redirections" -ItemType Directory

# Créer le partage (caché avec $)
New-SmbShare -Name "Redirections$" -Path "C:\Redirections" -FullAccess "Utilisateurs du domaine"
```

**Note :** Le `$` à la fin rend le partage invisible dans l'explorateur réseau.

### Configuration des permissions NTFS

**Permissions spéciales pour la redirection de dossiers :**
```powershell
# Désactiver l'héritage
$acl = Get-Acl "C:\Redirections"
$acl.SetAccessRuleProtection($true, $false)
Set-Acl "C:\Redirections" $acl

# Configurer les permissions
$acl = Get-Acl "C:\Redirections"

# SYSTEM - Contrôle total
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM",
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($rule)

# Administrateurs - Contrôle total
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrateurs",
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($rule)

# Utilisateurs du domaine - Parcourir + Créer dossiers (CE DOSSIER UNIQUEMENT)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "LAB\Utilisateurs du domaine",
    "CreateDirectories,AppendData,ReadAndExecute,Traverse",
    "None",
    "None",
    "Allow"
)
$acl.AddAccessRule($rule)

# CREATOR OWNER - Contrôle total (SOUS-DOSSIERS ET FICHIERS UNIQUEMENT)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "CREATOR OWNER",
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "InheritOnly",
    "Allow"
)
$acl.AddAccessRule($rule)

Set-Acl "C:\Redirections" $acl
```

**Vérification :**
```powershell
Get-Acl "C:\Redirections" | Format-List
```

**Résultat attendu :**
- SYSTEM : Contrôle total
- Administrateurs : Contrôle total
- Utilisateurs du domaine : Parcourir/Lister/Créer (Ce dossier uniquement)
- CREATOR OWNER : Contrôle total (Sous-dossiers et fichiers uniquement)

### Explication des permissions CREATOR OWNER

**CREATOR OWNER** est un SID spécial qui s'applique automatiquement à l'utilisateur qui crée un dossier.

**Comportement :**
1. L'utilisateur `cun` se connecte
2. Windows crée automatiquement `C:\Redirections\cun\`
3. CREATOR OWNER s'applique → `cun` devient propriétaire avec Contrôle total
4. Seul `cun` peut accéder à son propre dossier

**Conséquence pour l'admin :**
- ❌ L'administrateur ne peut PAS accéder directement à `C:\Redirections\cun\`
- ✅ C'est NORMAL et VOULU (confidentialité)
- ✅ L'admin peut prendre possession temporairement si nécessaire

## Configuration de la GPO de redirection

### Création de la GPO
```powershell
New-GPO -Name "GPO-Redirection-Dossiers"
New-GPLink -Name "GPO-Redirection-Dossiers" -Target "DC=lab,DC=local"
```

### Configuration de la redirection des Documents

**Chemin dans la GPO :**
```
Configuration utilisateur
└── Stratégies
    └── Paramètres Windows
        └── Redirection de dossiers
            └── Documents
```

**Paramètres :**
1. Clic droit sur **Documents** → Propriétés
2. **Paramètre** : De base - Rediriger les dossiers de tout le monde au même emplacement
3. **Emplacement du dossier cible** : Créer un dossier pour chaque utilisateur sous le chemin racine
4. **Chemin racine** : `\\SRV-DC01\Redirections$`
5. Onglet **Paramètres** :
   - ☑️ Accorder à l'utilisateur des droits exclusifs sur Documents
   - ☑️ Déplacer le contenu de Documents vers le nouvel emplacement
   - Stratégie de suppression : Laisser le dossier dans le nouvel emplacement quand la stratégie est supprimée
6. OK

**Avertissement :** Windows affiche un message sur les chemins UNC. Cliquer **Oui**.

### Configuration de la redirection du Bureau

**Même procédure que Documents :**

**Chemin dans la GPO :**
```
Configuration utilisateur
└── Stratégies
    └── Paramètres Windows
        └── Redirection de dossiers
            └── Bureau
```

**Paramètres :**
1. Clic droit sur **Bureau** → Propriétés
2. **Paramètre** : De base - Rediriger les dossiers de tout le monde au même emplacement
3. **Emplacement du dossier cible** : Créer un dossier pour chaque utilisateur sous le chemin racine
4. **Chemin racine** : `\\SRV-DC01\Redirections$`
5. Onglet **Paramètres** :
   - ☑️ Accorder à l'utilisateur des droits exclusifs sur Bureau
   - ☑️ Déplacer le contenu de Bureau vers le nouvel emplacement
6. OK

## Test de la redirection

### Sur CLIENT01 (utilisateur cun)

**1. Appliquer la GPO :**
```cmd
gpupdate /force
```

**2. Se déconnecter et se reconnecter**

**3. Vérifier la redirection :**
```cmd
echo %USERPROFILE%\Documents
```
Doit afficher : `\\SRV-DC01\Redirections$\cun\Documents`

**4. Créer un fichier test :**
```cmd
echo Test > %USERPROFILE%\Documents\test-redirection.txt
```

### Sur SRV-DC01 (vérification serveur)

**Vérifier que le dossier utilisateur a été créé :**
```powershell
Get-ChildItem "C:\Redirections"
```

Doit afficher : `cun` (et autres utilisateurs connectés)

**Vérifier le fichier test (en tant qu'admin, nécessite prise de possession) :**
```powershell
# Lister le contenu (erreur Accès refusé normal)
Get-ChildItem "C:\Redirections\cun"

# Vérifier l'existence du sous-dossier
Test-Path "C:\Redirections\cun\Documents"
```

**Note :** L'admin ne peut pas accéder directement au contenu à cause de CREATOR OWNER. C'est normal.

## Vérification avec un autre utilisateur

**Sur CLIENT01, connexion avec cdeux :**

**Vérifier la redirection :**
```cmd
echo %USERPROFILE%\Documents
```
Doit afficher : `\\SRV-DC01\Redirections$\cdeux\Documents`

**Sur le serveur :**
```powershell
Get-ChildItem "C:\Redirections"
```
Doit maintenant afficher : `cun`, `cdeux`

## Structure finale sur le serveur
```
C:\Redirections\
├── cun\
│   ├── Desktop\
│   └── Documents\
├── cdeux\
│   ├── Desktop\
│   └── Documents\
├── mdupont\
│   ├── Desktop\
│   └── Documents\
└── pmartin\
    ├── Desktop\
    └── Documents\
```

## Accès administrateur aux dossiers redirigés

**Si besoin d'accéder au dossier d'un utilisateur :**

### Méthode 1 : Prise de possession temporaire
```powershell
# Prendre possession (en admin)
takeown /F "C:\Redirections\cun" /R /D Y

# Accorder les droits
icacls "C:\Redirections\cun" /grant Administrateurs:F /T
```

**⚠️ Attention :** Cela modifie les permissions. À faire uniquement en cas de nécessité absolue.

### Méthode 2 : Utiliser un compte de service dédié

Créer un compte de service avec délégation pour la gestion des dossiers redirigés.

## Dossiers supplémentaires redirigeables

Outre Documents et Bureau, on peut rediriger :
- Bureau (Desktop) ✅ Fait
- Documents ✅ Fait
- Images (Pictures)
- Musique (Music)
- Vidéos (Videos)
- Favoris (Favorites)
- AppData (Roaming)
- Menu Démarrer (Start Menu)
- Téléchargements (Downloads)

**Note :** AppData peut causer des ralentissements. À éviter sauf nécessité.

## Troubleshooting

### Problème : Dossiers ne se redirigent pas

**Diagnostic :**
```cmd
gpresult /h C:\gpo-report.html
```
Vérifier dans le rapport :
- La GPO est-elle appliquée ?
- Y a-t-il des erreurs dans la section "Redirection de dossiers" ?

**Logs d'événements :**
```
Observateur d'événements
└── Journaux des applications et des services
    └── Microsoft
        └── Windows
            └── Folder Redirection
                └── Operational
```

### Problème : Accès refusé au partage

**Vérifier les permissions :**
```powershell
Get-SmbShareAccess -Name "Redirections$"
Get-Acl "C:\Redirections" | Format-List
```

**Solution :** Vérifier que "Utilisateurs du domaine" a accès au partage.

### Problème : Dossier utilisateur créé mais vide

**Cause probable :** Option "Déplacer le contenu" pas cochée dans la GPO.

**Solution :** Rééditer la GPO, onglet Paramètres, cocher "Déplacer le contenu".

### Problème : Lenteur de connexion

**Cause :** Fichiers volumineux dans les dossiers redirigés.

**Solutions :**
- Éviter de rediriger AppData
- Configurer le mode hors connexion pour les fichiers
- Augmenter la bande passante réseau

## Commandes de diagnostic
```cmd
REM Voir où pointe Documents
echo %USERPROFILE%\Documents

REM Voir les mappages réseau actifs
net use

REM Forcer la mise à jour des GPO
gpupdate /force

REM Vérifier les journaux de redirection
eventvwr
```
```powershell
# Vérifier les dossiers créés sur le serveur
Get-ChildItem "C:\Redirections"

# Vérifier les permissions
Get-Acl "C:\Redirections" | Format-List

# Vérifier le partage
Get-SmbShare -Name "Redirections$"
```

## Bonnes pratiques

✅ Utiliser un partage caché (`$`) pour la redirection  
✅ Configurer CREATOR OWNER pour la confidentialité  
✅ Rediriger Documents et Bureau (minimum)  
✅ Activer "Déplacer le contenu" pour ne pas perdre de données  
✅ Tester avec un utilisateur avant déploiement général  
✅ Documenter les permissions spécifiques  

❌ Ne pas rediriger AppData (sauf cas spécifique)  
❌ Ne pas donner accès complet aux admins sur les dossiers users  
❌ Ne pas oublier de configurer les sauvegardes du serveur