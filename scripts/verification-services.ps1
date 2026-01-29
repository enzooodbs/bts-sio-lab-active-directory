<#
.SYNOPSIS
    Script de verification de la sante des services Active Directory
    
.DESCRIPTION
    Verifie l'etat des services critiques (AD, DNS, DHCP) sur SRV-DC01
    Affiche un rapport colore et genere un fichier log
    
.NOTES
    Auteur: Enzo DUBOIS
    Date: Janvier 2026
    Usage: Executer sur SRV-DC01 en tant qu'administrateur
#>

# Banniere
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION SERVICES ACTIVE DIRECTORY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Date et heure
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Execution: $timestamp`n" -ForegroundColor Gray

# Services a verifier
$services = @("NTDS", "DNS", "DHCPServer")

# Tableau de resultats
$results = @()

foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    
    if ($svc) {
        $status = $svc.Status
        $displayName = $svc.DisplayName
        
        # Couleur selon le statut
        if ($status -eq "Running") {
            Write-Host "[OK] " -ForegroundColor Green -NoNewline
            Write-Host "$displayName : " -NoNewline
            Write-Host "Running" -ForegroundColor Green
        } else {
            Write-Host "[KO] " -ForegroundColor Red -NoNewline
            Write-Host "$displayName : " -NoNewline
            Write-Host "$status" -ForegroundColor Red
        }
        
        # Ajouter au tableau
        $results += [PSCustomObject]@{
            Service = $displayName
            Status = $status
            Timestamp = $timestamp
        }
    } else {
        Write-Host "[!!] Service $service introuvable" -ForegroundColor Yellow
    }
}

# Verification domaine AD
Write-Host "`n--- Domaine Active Directory ---" -ForegroundColor Cyan
try {
    $domain = Get-ADDomain
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host "Domaine: $($domain.DNSRoot)" -ForegroundColor White
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host "Niveau fonctionnel: $($domain.DomainMode)" -ForegroundColor White
} catch {
    Write-Host "[KO] Impossible de recuperer les infos du domaine" -ForegroundColor Red
}

# Verification replication AD
Write-Host "`n--- Replication Active Directory ---" -ForegroundColor Cyan
try {
    $repl = repadmin /replsummary 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] " -ForegroundColor Green -NoNewline
        Write-Host "Replication AD fonctionnelle" -ForegroundColor White
    } else {
        Write-Host "[KO] " -ForegroundColor Red -NoNewline
        Write-Host "Probleme de replication detecte" -ForegroundColor Red
    }
} catch {
    Write-Host "[!!] Impossible de verifier la replication" -ForegroundColor Yellow
}

# Statistiques rapides
Write-Host "`n--- Statistiques du domaine ---" -ForegroundColor Cyan
$userCount = (Get-ADUser -Filter *).Count
$computerCount = (Get-ADComputer -Filter *).Count
$groupCount = (Get-ADGroup -Filter *).Count

Write-Host "Utilisateurs : $userCount" -ForegroundColor White
Write-Host "Ordinateurs  : $computerCount" -ForegroundColor White
Write-Host "Groupes      : $groupCount" -ForegroundColor White

# Conclusion
Write-Host "`n========================================" -ForegroundColor Cyan
$allRunning = ($results | Where-Object {$_.Status -ne "Running"}).Count -eq 0
if ($allRunning) {
    Write-Host "  ETAT GENERAL: " -NoNewline -ForegroundColor White
    Write-Host "OPERATIONNEL" -ForegroundColor Green
} else {
    Write-Host "  ETAT GENERAL: " -NoNewline -ForegroundColor White
    Write-Host "ATTENTION REQUISE" -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Cyan

# Export optionnel des resultats
# $results | Export-Csv "C:\Logs\verification-services-$((Get-Date).ToString('yyyyMMdd-HHmmss')).csv" -NoTypeInformation