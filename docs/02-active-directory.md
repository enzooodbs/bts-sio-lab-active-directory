# Active Directory Domain Services

## Installation du rôle AD DS

**Sur SRV-DC01, PowerShell en administrateur :**
```powershell
# Installer le rôle AD DS
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

## Promotion en contrôleur de domaine
```powershell
# Promouvoir en DC et créer la forêt
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Force:$true
```

**Paramètres :**
- Domaine : `lab.local`
- Niveau fonctionnel : Windows Server 2016 (WinThreshold)
- DNS : Installé automatiquement
- Mot de passe DSRM : Motdepasse1

Le serveur redémarre automatiquement après la promotion.

## Vérification post-installation

**Après redémarrage :**
```powershell
# Vérifier le domaine
Get-ADDomain

# Vérifier la forêt
Get-ADForest

# Vérifier le service AD
Get-Service NTDS

# Vérifier DNS
Get-Service DNS

# Lister les contrôleurs de domaine
Get-ADDomainController
```

**Résultat attendu :**
- Domain : lab.local
- Forest : lab.local
- NTDS : Running
- DNS : Running

## Structure des Unités d'Organisation (OU)

### Création des OU principales
```powershell
# OU pour les utilisateurs
New-ADOrganizationalUnit -Name "LAB-Users" -Path "DC=lab,DC=local"

# OU pour les ordinateurs
New-ADOrganizationalUnit -Name "LAB-Computers" -Path "DC=lab,DC=local"

# OU pour les groupes
New-ADOrganizationalUnit -Name "LAB-Groupes" -Path "DC=lab,DC=local"
```

### Création des sous-OU par service
```powershell
# Sous-OU dans LAB-Users
New-ADOrganizationalUnit -Name "Comptabilite" -Path "OU=LAB-Users,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "RH" -Path "OU=LAB-Users,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "IT" -Path "OU=LAB-Users,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Direction" -Path "OU=LAB-Users,DC=lab,DC=local"
```

### Vérification de la structure
```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName | Sort-Object Name
```

**Structure finale :**
```
lab.local
├── LAB-Users
│   ├── Comptabilite
│   ├── RH
│   ├── IT
│   └── Direction
├── LAB-Computers
└── LAB-Groupes
```

## Création des groupes de sécurité
```powershell
# Groupes par service
New-ADGroup -Name "GRP-Comptabilite" -GroupScope Global -GroupCategory Security -Path "OU=LAB-Groupes,DC=lab,DC=local"
New-ADGroup -Name "GRP-RH" -GroupScope Global -GroupCategory Security -Path "OU=LAB-Groupes,DC=lab,DC=local"
New-ADGroup -Name "GRP-IT" -GroupScope Global -GroupCategory Security -Path "OU=LAB-Groupes,DC=lab,DC=local"
New-ADGroup -Name "GRP-Direction" -GroupScope Global -GroupCategory Security -Path "OU=LAB-Groupes,DC=lab,DC=local"
```

**Vérification :**
```powershell
Get-ADGroup -Filter * -SearchBase "OU=LAB-Groupes,DC=lab,DC=local"
```

## Création des utilisateurs

### Utilisateurs de test
```powershell
# Utilisateur Comptabilité
New-ADUser -Name "cun" -SamAccountName "cun" -UserPrincipalName "cun@lab.local" `
  -Path "OU=Comptabilite,OU=LAB-Users,DC=lab,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Enabled $true

# Utilisateur IT
New-ADUser -Name "cdeux" -SamAccountName "cdeux" -UserPrincipalName "cdeux@lab.local" `
  -Path "OU=IT,OU=LAB-Users,DC=lab,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Enabled $true

# Utilisateur RH
New-ADUser -Name "Marie Dupont" -GivenName "Marie" -Surname "Dupont" `
  -SamAccountName "mdupont" -UserPrincipalName "mdupont@lab.local" `
  -Path "OU=RH,OU=LAB-Users,DC=lab,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Enabled $true

# Utilisateur Direction
New-ADUser -Name "Paul Martin" -GivenName "Paul" -Surname "Martin" `
  -SamAccountName "pmartin" -UserPrincipalName "pmartin@lab.local" `
  -Path "OU=Direction,OU=LAB-Users,DC=lab,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Motdepasse1" -AsPlainText -Force) `
  -Enabled $true
```

### Ajout des utilisateurs aux groupes
```powershell
Add-ADGroupMember -Identity "GRP-Comptabilite" -Members cun
Add-ADGroupMember -Identity "GRP-IT" -Members cdeux
Add-ADGroupMember -Identity "GRP-RH" -Members mdupont
Add-ADGroupMember -Identity "GRP-Direction" -Members pmartin
```

**Vérification :**
```powershell
# Voir les membres d'un groupe
Get-ADGroupMember -Identity "GRP-IT"

# Voir les groupes d'un utilisateur
Get-ADUser cdeux -Properties MemberOf | Select-Object -ExpandProperty MemberOf
```

## Configuration DHCP

### Installation du rôle
```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
```

### Autorisation du serveur DHCP dans AD
```powershell
Add-DhcpServerInDC -DnsName "SRV-DC01.lab.local" -IPAddress 192.168.10.1
```

### Création de l'étendue DHCP
```powershell
# Créer l'étendue
Add-DhcpServerv4Scope -Name "LAB-Scope" -StartRange 192.168.10.100 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0

# Configurer les options (passerelle et DNS)
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -Router 192.168.10.1 -DnsServer 192.168.10.1
```

**Vérification :**
```powershell
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0
```

## Jonction des clients au domaine

### Sur CLIENT01 et CLIENT02

**Méthode graphique :**
1. Paramètres → Système → Informations système
2. Renommer ce PC (avancé)
3. Modifier → Domaine : `lab.local`
4. Identifiants : `LAB\Administrateur` / Motdepasse1
5. Redémarrer

**Méthode PowerShell :**
```powershell
Add-Computer -DomainName "lab.local" -Credential LAB\Administrateur -Restart
```

### Déplacer les ordinateurs dans la bonne OU

**Sur SRV-DC01 :**
```powershell
# Déplacer CLIENT01
Get-ADComputer CLIENT01 | Move-ADObject -TargetPath "OU=LAB-Computers,DC=lab,DC=local"

# Déplacer CLIENT02
Get-ADComputer CLIENT02 | Move-ADObject -TargetPath "OU=LAB-Computers,DC=lab,DC=local"
```

**Vérification :**
```powershell
Get-ADComputer -Filter * -SearchBase "OU=LAB-Computers,DC=lab,DC=local"
```

## Commandes de vérification courantes
```powershell
# Lister tous les utilisateurs
Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled

# Lister tous les groupes
Get-ADGroup -Filter * | Select-Object Name, GroupScope

# Lister tous les ordinateurs du domaine
Get-ADComputer -Filter * | Select-Object Name, DNSHostName

# Vérifier les services critiques
Get-Service NTDS, DNS, DHCP | Select-Object Name, Status

# Tester la réplication AD
repadmin /replsummary
```

## Troubleshooting

**Problème : Promotion AD échoue (mot de passe administrateur vide)**
```powershell
net user Administrateur Motdepasse1
```

**Problème : Client ne trouve pas le domaine**
- Vérifier DNS client : `nslookup lab.local`
- Doit pointer vers 192.168.10.1

**Problème : Erreur "Cannot find object" lors de Get-ADUser**
- L'utilisateur n'existe pas ou mauvais nom
- Vérifier : `Get-ADUser -Filter *`