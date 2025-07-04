@echo off
echo ==========================================================================
echo SCRIPT POUR POUSSER LE PROJET NETTOYE VERS GITHUB
echo ==========================================================================
echo.
echo IMPORTANT: Avant d'executer ce script, assurez-vous :
echo 1. D'avoir clone le depot "25Eloquence-Finalisation" sur votre machine.
echo    Si ce n'est pas fait, executez :
echo    git clone https://github.com/gramyfied/25Eloquence-Finalisation.git
echo    cd 25Eloquence-Finalisation
echo.
echo 2. D'etre sur la branche "feature/cleanup-and-fixes".
echo    Si vous venez de cloner, ou si vous etes sur une autre branche, executez :
echo    git checkout feature/cleanup-and-fixes
echo    (Si la branche n'existe pas localement mais existe sur le remote, utilisez :
echo     git checkout -t origin/feature/cleanup-and-fixes )
echo.
echo 3. D'avoir copie TOUS les fichiers de votre projet nettoye
echo    (celui sur lequel nous avons travaille, actuellement dans
echo    c:\Users\User\Desktop\25Eloquence-Finalisation)
echo    DANS le repertoire du depot que vous venez de cloner,
echo    EN REMPLACANT les fichiers existants si necessaire.
echo.
echo Ce script va maintenant executer les commandes suivantes :
echo   - git add .
echo   - git commit -m "Push cleaned and refactored project structure with fixes."
echo   - git push origin feature/cleanup-and-fixes
echo.
pause
echo.

echo Ajout de tous les fichiers au staging...
git add .
if errorlevel 1 (
    echo ERREUR: "git add ." a echoue. Verifiez les messages d'erreur ci-dessus.
    pause
    exit /b %errorlevel%
)
echo Fichiers ajoutes avec succes.
echo.

echo Creation du commit...
git commit -m "Push cleaned and refactored project structure with fixes."
if errorlevel 1 (
    echo ERREUR: "git commit" a echoue. Verifiez les messages d'erreur ci-dessus.
    pause
    exit /b %errorlevel%
)
echo Commit cree avec succes.
echo.

echo Poussee des modifications vers origin/feature/cleanup-and-fixes...
git push origin feature/cleanup-and-fixes
if errorlevel 1 (
    echo ERREUR: "git push" a echoue. Verifiez les messages d'erreur ci-dessus.
    echo Assurez-vous d'avoir les droits d'acces et que votre connexion internet fonctionne.
    pause
    exit /b %errorlevel%
)
echo Modifications poussees avec succes vers la branche feature/cleanup-and-fixes !
echo.
echo ==========================================================================
echo Operation terminee.
echo ==========================================================================
pause