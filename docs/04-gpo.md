# Stratégies de groupe (GPO)

## Vue d'ensemble

Les GPO créées dans ce lab :
- **Mappage lecteur Z:** (partage Commun)
- **GPO-Fond-Ecran** (fond d'écran personnalisé)
- **GPO-Restrictions** (verrouillage Panneau de configuration)
- **GPO-Script-Logon** (message de bienvenue via tâche planifiée)
- **GPO-Redirection-Dossiers** (Documents et Bureau vers serveur)

## Création d'une GPO

### Méthode graphique

1. Gestionnaire de serveur → Outils → **Gestion des stratégies de groupe**
2. Développer : Forêt → Domaines → lab.local
3. Clic droit sur **Objets de stratégie de groupe** → Nouvelle
4. Nom : `GPO-[Nom]`
5. OK

### Méthode PowerShell
```powershell
New-GPO -Name "GPO-Exemple" -Comment "Description de la GPO"
```

## Liaison d'une GPO

**Lier au domaine (s'applique à tous) :**
```powershell
New-GPLink -Name "GPO-Exemple" -Target "DC=lab,DC=local"
```

**Vérifier les GPO liées :**
```powershell
Get-GPInheritance -Target "DC=lab,DC=local"
```

## GPO 1 : Mappage de lecteur réseau

### Configuration

**Chemin de la GPO :**
```
Configuration utilisateur
└── Préférences
    └── Paramètres Windows
        └── Mappages de lecteurs
```

**Paramètres :**
1. Clic droit → Nouveau → Lecteur mappé
2. **Action** : Créer
3. **Emplacement** : `\\SRV-DC01\Commun`
4. **Reconnecter** : ☑️ Activé
5. **Lettre de lecteur** : Z:
6. **Étiquette** : Partage Commun
7. OK

**Vérification sur client :**
```cmd
net use
```
Doit afficher : `Z: \\SRV-DC01\Commun`

## GPO 2 : Fond d'écran

### Préparation

**Copier une image dans le partage :**
```powershell
# Sur SRV-DC01
Copy-Item "C:\Windows\Web\Wallpaper\Windows\img0.jpg" "C:\Partages\Commun\wallpaper.jpg"
```

### Configuration

**Chemin de la GPO :**
```
Configuration utilisateur
└── Stratégies
    └── Modèles d'administration
        └── Bureau
            └── Bureau
```

**Paramètres :**
1. Double-clic sur **Papier peint du Bureau**
2. ☑️ **Activé**
3. **Nom du papier peint** : `\\SRV-DC01\Commun\wallpaper.jpg`
4. **Style du papier peint** : Remplir
5. OK

**Vérification sur client :**
- Le fond d'écran doit changer après `gpupdate /force` et reconnexion

## GPO 3 : Restrictions utilisateur

### Configuration

**Chemin de la GPO :**
```
Configuration utilisateur
└── Stratégies
    └── Modèles d'administration
        └── Panneau de configuration
```

**Paramètres :**
1. Double-clic sur **Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC**
2. ☑️ **Activé**
3. OK

**Vérification sur client :**
```cmd
control
```
Message d'erreur : "Cette opération a été annulée en raison de restrictions..."

## GPO 4 : Script de connexion (via Tâche planifiée)

### Problème rencontré avec les scripts classiques

**❌ Scripts classiques (Configuration utilisateur → Stratégies → Scripts) NE FONCTIONNENT PAS**

**Cause :** Détection de liaison lente par Windows.

**Vérification du problème :**
```cmd
gpresult /r
```
Affiche : "Les objets stratégie de groupe n'ont pas été refusés car ils ont été refusés (liaison lente)"

### Solution : Tâche planifiée via Préférences GPO

**Chemin de la GPO :**
```
Configuration utilisateur
└── Préférences
    └── Paramètres du Panneau de configuration
        └── Tâches planifiées
```

**Configuration :**
1. Clic droit → Nouveau → Tâche immédiate (Windows 7 et versions ultérieures)
2. Onglet **Général** :
   - **Nom** : Script de connexion
   - **Exécuter avec les privilèges** : décoché
   - **Configurer pour** : Windows 7 et ultérieur

3. Onglet **Déclencheurs** :
   - Nouveau
   - **Commencer la tâche** : À l'ouverture de session
   - **Utilisateur spécifique** : %LogonUser%
   - OK

4. Onglet **Actions** :
   - Nouvelle
   - **Action** : Démarrer un programme
   - **Programme** : `cmd.exe`
   - **Arguments** : `/c msg * "Bienvenue %USERNAME% sur le domaine LAB !"`
   - OK

5. Onglet **Conditions** :
   - Décocher toutes les conditions (réseau, alimentation)

6. Onglet **Paramètres** :
   - ☑️ Autoriser l'exécution de la tâche à la demande
   - ☑️ Si la tâche est déjà en cours, arrêter l'instance existante

7. OK

**Vérification sur client :**
- Après connexion utilisateur : popup "Bienvenue [nom] sur le domaine LAB !"

### Modification de la Default Domain Policy (pour scripts classiques)

**Si on voulait utiliser des scripts classiques, il faudrait :**

**Chemin :**
```
Configuration ordinateur
└── Stratégies
    └── Modèles d'administration
        └── Système
            └── Stratégie de groupe
```

**Paramètres à activer :**
1. **Traitement de la stratégie de script de groupe**
   - ☑️ Activé
   - ☑️ Autoriser le traitement lors d'une connexion réseau lente

2. **Traitement de la stratégie de Registre**
   - ☑️ Activé
   - ☑️ Traiter même si les objets n'ont pas changé
   - ☑️ Autoriser le traitement lors d'une connexion réseau lente

3. **Traitement de la stratégie de préférences de groupe**
   - ☑️ Activé
   - ☑️ Autoriser le traitement lors d'une connexion réseau lente

**Mais on utilise les tâches planifiées, méthode plus robuste.**

## Diagnostic et vérification des GPO

### Sur le client

**Forcer la mise à jour :**
```cmd
gpupdate /force
```

**Voir les GPO appliquées :**
```cmd
gpresult /r
```

**Rapport HTML détaillé :**
```cmd
gpresult /h C:\gpo-report.html
```

**Voir uniquement les GPO utilisateur :**
```cmd
gpresult /r /scope:user
```

### Sur le serveur

**Lister toutes les GPO :**
```powershell
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime
```

**Voir les détails d'une GPO :**
```powershell
Get-GPO -Name "GPO-Fond-Ecran" | Select-Object *
```

**Voir où une GPO est liée :**
```powershell
Get-GPO -Name "GPO-Fond-Ecran" | Get-GPOReport -ReportType Xml
```

**Récupérer le GUID d'une GPO :**
```powershell
Get-GPO -Name "GPO-Script-Logon" | Select-Object DisplayName, Id
```

## Ordre d'application des GPO

**Ordre (du moins prioritaire au plus prioritaire) :**
1. Site
2. Domaine
3. OU (de la plus haute à la plus basse)

**Règle :** Le dernier appliqué l'emporte (sauf si "Appliqué" est forcé).

## Filtrage de sécurité

Par défaut, les GPO s'appliquent à **Utilisateurs authentifiés**.

**Pour restreindre une GPO à un groupe spécifique :**
1. GPO → Onglet **Étendue**
2. Section **Filtrage de sécurité**
3. Supprimer "Utilisateurs authentifiés"
4. Ajouter le groupe cible (ex: GRP-IT)

**En PowerShell :**
```powershell
# Supprimer Utilisateurs authentifiés
Set-GPPermission -Name "GPO-Exemple" -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None

# Ajouter un groupe
Set-GPPermission -Name "GPO-Exemple" -TargetName "GRP-IT" -TargetType Group -PermissionLevel GpoApply
```

## Troubleshooting GPO

### Problème : GPO ne s'applique pas

**Diagnostic étape par étape :**

1. **Vérifier que la GPO est liée :**
```powershell
Get-GPInheritance -Target "DC=lab,DC=local"
```

2. **Vérifier le filtrage de sécurité :**
- Le groupe/utilisateur a-t-il le droit "Appliquer la stratégie de groupe" ?

3. **Forcer la mise à jour sur le client :**
```cmd
gpupdate /force
```

4. **Vérifier avec gpresult :**
```cmd
gpresult /r
```
Regarder la section "Objets stratégie de groupe appliqués"

5. **Vérifier les logs d'événements :**
```
Observateur d'événements
└── Journaux des applications et des services
    └── Microsoft
        └── Windows
            └── GroupPolicy
                └── Operational
```

### Problème : Script ne s'exécute pas

**Solution :** Utiliser les **Tâches planifiées via Préférences GPO** au lieu des scripts classiques.

**Raison :** Windows détecte des liaisons lentes et refuse d'appliquer les scripts classiques.

### Problème : Fond d'écran ne s'applique pas

**Vérifications :**
1. Chemin UNC accessible : `\\SRV-DC01\Commun\wallpaper.jpg`
2. Permissions de partage : Utilisateurs du domaine en lecture
3. GPO bien liée au domaine
4. `gpupdate /force` + reconnexion utilisateur

## Commandes utiles
```powershell
# Créer une GPO
New-GPO -Name "GPO-Test"

# Lier une GPO
New-GPLink -Name "GPO-Test" -Target "DC=lab,DC=local"

# Supprimer une GPO
Remove-GPO -Name "GPO-Test"

# Délier une GPO (sans la supprimer)
Remove-GPLink -Name "GPO-Test" -Target "DC=lab,DC=local"

# Sauvegarder une GPO
Backup-GPO -Name "GPO-Fond-Ecran" -Path "C:\GPO-Backup"

# Restaurer une GPO
Restore-GPO -Name "GPO-Fond-Ecran" -Path "C:\GPO-Backup"

# Générer un rapport HTML
Get-GPOReport -Name "GPO-Fond-Ecran" -ReportType Html -Path "C:\gpo-report.html"
```

## Bonnes pratiques

✅ Nommer les GPO de manière claire et descriptive  
✅ Documenter chaque GPO (commentaire)  
✅ Tester sur une OU de test avant déploiement général  
✅ Utiliser le filtrage de sécurité pour cibler des groupes  
✅ Sauvegarder les GPO critiques régulièrement  
✅ Privilégier les Préférences GPO pour les scripts  
✅ Désactiver les sections inutilisées (Ordinateur ou Utilisateur)  

❌ Ne pas multiplier les GPO inutilement  
❌ Ne pas modifier la Default Domain Policy sauf nécessité  
❌ Ne pas utiliser de chemins locaux (C:\...) dans les GPO