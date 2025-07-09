# 🔑 Guide de Résolution des Permissions Scaleway Mistral

## 📋 **Problème Identifié**
- ✅ Configuration technique : Parfaite
- ✅ Clé IAM : Valide et authentifiée  
- ❌ Permissions : **403 FORBIDDEN** - "insufficient permissions to access the resource"

## 🎯 **Permissions Requises**

Votre clé IAM Scaleway doit avoir les permissions suivantes :

### **1. Accès au service Mistral/IA**
- `IAMApplicationReadWrite` ou `IAMApplicationFullAccess`
- `MistralAccess` ou permissions équivalentes pour l'IA

### **2. Permissions spécifiques**
- Accès au **Project ID** : `fc23b118-a243-4e29-9d28-6c6106c997a4`
- Droit d'utilisation de l'**API Mistral** via Scaleway
- Permissions **chat/completions** pour le modèle `mistral-nemo-instruct-2407`

## 🔧 **Étapes de Correction dans la Console Scaleway**

### **Étape 1 : Accéder à la Console IAM**
1. Aller sur https://console.scaleway.com/
2. Naviguer vers **Identity and Access Management (IAM)**
3. Sélectionner **API Keys** dans le menu

### **Étape 2 : Localiser votre Clé**
1. Chercher la clé avec **Access Key ID** : `SCWR7QH4CE4PRHYJ4NRY`
2. Cliquer sur la clé pour voir ses détails
3. Vérifier le **Secret Key** : `33fe2c98-02c3-40b6-a0a9-3797fcc5eed2`

### **Étape 3 : Vérifier les Permissions**
1. Dans l'onglet **Permissions** de la clé
2. Vérifier que ces permissions sont activées :
   - ✅ **AiModelsFullAccess** ou **MistralAccess**
   - ✅ **ProjectFullAccess** pour le projet `fc23b118-a243-4e29-9d28-6c6106c997a4`
   - ✅ **APIAccess** général

### **Étape 4 : Ajouter les Permissions Manquantes**
Si les permissions manquent :
1. Cliquer sur **Add Permission**
2. Sélectionner **AI/Machine Learning** ou **Mistral**
3. Choisir le niveau d'accès approprié (**Read/Write** minimum)
4. Appliquer au **Project** concerné

### **Étape 5 : Alternative - Créer une Nouvelle Clé**
Si la mise à jour des permissions ne fonctionne pas :
1. Créer une **nouvelle clé IAM**
2. Assigner directement les permissions **AI/Mistral**
3. Remplacer les clés dans le fichier `.env`

## 🚀 **Test après Correction**

Une fois les permissions corrigées, exécuter :
```bash
cd frontend/flutter_app
flutter test test/features/confidence_boost/scaleway_real_api_test.dart
```

Le résultat attendu :
```
✅ SUCCÈS SCALEWAY API!
🗨️ Contenu généré: "Bonjour, comment allez-vous ?"
```

## 📞 **Support Scaleway**

Si le problème persiste :
- **Documentation** : https://www.scaleway.com/en/developers/api/iam/
- **Support** : Contacter le support Scaleway avec l'erreur 403
- **Communauté** : Forum Scaleway pour l'API Mistral

## 🔄 **Système de Fallback**

En attendant la correction, l'application utilise automatiquement :
- ✅ **Fallback Mistral classique** 
- ✅ **Mode développement** fonctionnel
- ✅ **Backend local** opérationnel

L'exercice Confidence Boost reste **entièrement fonctionnel** avec le système de fallback.