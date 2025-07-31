# 🌐 **CONFIGURATION DNS HOSTINGER - N8N**

## 📋 **Votre serveur Scaleway**
- **IP**: `51.159.110.4`
- **Domaine**: `dashboard-n8n.eu`

## 🔧 **Configuration DNS sur Hostinger**

### **Étape 1: Accéder au panneau Hostinger**

1. Connectez-vous à [Hostinger Panel](https://hpanel.hostinger.com)
2. Allez dans **Domaines** 
3. Trouvez votre domaine `dashboard-n8n.eu`
4. Cliquez sur **Gérer** ou **Manage**

### **Étape 2: Accéder à la zone DNS**

1. Dans la gestion du domaine, cherchez **Zone DNS** ou **DNS Zone**
2. Ou allez dans **DNS/Nameservers** → **DNS Zone Editor**

### **Étape 3: Ajouter les enregistrements A**

Ajoutez ces 2 enregistrements :

#### **Enregistrement 1 (domaine principal)**
```
Type: A
Name: @ (ou laissez vide)
Points to: 51.159.110.4
TTL: 14400 (ou Auto)
```

#### **Enregistrement 2 (sous-domaine www)**
```
Type: A
Name: www
Points to: 51.159.110.4
TTL: 14400 (ou Auto)
```

### **Étape 4: Supprimer les anciens enregistrements (si nécessaire)**

Si vous voyez des enregistrements A existants pour `@` et `www`, supprimez-les avant d'ajouter les nouveaux.

## 📱 **Interface Hostinger - Guide visuel**

### **Dans hPanel:**
1. **Domaines** → Votre domaine → **Gérer**
2. **Zone DNS** ou **DNS Zone Editor**
3. **Ajouter un enregistrement** ou **Add Record**
4. Sélectionnez **Type: A**
5. **Name/Host**: `@` (pour le domaine principal)
6. **Value/Points to**: `51.159.110.4`
7. **TTL**: Laissez par défaut ou 14400
8. **Sauvegarder**

Répétez pour `www`.

## ⚡ **Configuration rapide**

Si vous préférez, voici le résumé :

```
@ IN A 51.159.110.4
www IN A 51.159.110.4
```

## 🕐 **Temps de propagation Hostinger**

- **Hostinger**: Généralement 15-30 minutes
- **Propagation mondiale**: 1-2 heures maximum

## ✅ **Vérification**

### **Test immédiat**
```bash
# Depuis votre serveur
dig dashboard-n8n.eu @8.8.8.8 +short
```

### **Test en ligne**
- [DNS Checker](https://dnschecker.org) → Recherchez `dashboard-n8n.eu`
- Vérifiez que l'IP `51.159.110.4` apparaît

## 🚨 **Si vous avez des problèmes**

### **Problème 1: Interface différente**
Hostinger a parfois des interfaces différentes selon le plan :
- Cherchez **"DNS"**, **"Zone DNS"**, **"DNS Records"**
- Ou contactez le support Hostinger

### **Problème 2: Enregistrements existants**
Si vous avez déjà des enregistrements A :
1. **Supprimez** les anciens enregistrements A pour `@` et `www`
2. **Ajoutez** les nouveaux avec l'IP `51.159.110.4`

### **Problème 3: Nameservers**
Vérifiez que votre domaine utilise les nameservers Hostinger :
- `ns1.dns-parking.com`
- `ns2.dns-parking.com`

## 🔄 **Alternative: Sous-domaine**

Si vous voulez garder votre site principal ailleurs, créez un sous-domaine :

```
Type: A
Name: n8n
Points to: 51.159.110.4
```

Puis modifiez `/opt/n8n/.env` :
```bash
DOMAIN_NAME=n8n.dashboard-n8n.eu
N8N_HOST=n8n.dashboard-n8n.eu
```

Accès : `https://n8n.dashboard-n8n.eu`

## 📞 **Support Hostinger**

Si vous ne trouvez pas l'option DNS :
- **Chat support** : Disponible 24/7 dans hPanel
- **Email** : support@hostinger.com
- Demandez : "Comment modifier les enregistrements DNS A pour mon domaine"

---

## ✅ **Résumé pour Hostinger**

1. **hPanel** → **Domaines** → **dashboard-n8n.eu** → **Gérer**
2. **Zone DNS** → **Ajouter enregistrement**
3. **Type A** → **Name: @** → **Value: 51.159.110.4**
4. **Type A** → **Name: www** → **Value: 51.159.110.4**
5. **Sauvegarder** et attendre 15-30 minutes

Après propagation : `https://dashboard-n8n.eu`
