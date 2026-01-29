@echo off
REM Script de connexion utilisateur
REM Execute lors de l'ouverture de session via GPO (tache planifiee)

REM Afficher un message de bienvenue
msg * "Bienvenue %USERNAME% sur le domaine LAB !"

REM Logger la connexion (optionnel)
REM echo %DATE% %TIME% - Connexion de %USERNAME% >> \\SRV-DC01\Scripts\logs\connexions.log