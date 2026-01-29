# Script de connexion utilisateur (version PowerShell)
# Execute lors de l'ouverture de session via GPO (tache planifiee)

# Message de bienvenue
$user = $env:USERNAME
msg * "Bienvenue $user sur le domaine LAB !"

# Logger la connexion (optionnel)
# $logFile = "\\SRV-DC01\Scripts\logs\connexions.log"
# $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
# "$timestamp - Connexion de $user" | Add-Content $logFile