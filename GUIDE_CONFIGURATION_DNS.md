# 🌐 **GUIDE CONFIGURATION DNS - N8N SCALEWAY**

## 📋 **Informations de votre serveur**

- **IP IPv4**: `51.159.110.4`
- **IP IPv6**: `2001:bc8:1201:51:1618:77ff:fe59:2cc8`
- **Domaine configuré**: `dashboard-n8n.eu`

## 🔧 **Configuration DNS requise**

### 1. **Enregistrements A (IPv4)**

```dns
dashboard-n8n.eu.        A    51.159.110.4
www.dashboard-n8n.eu.    A    51.159.110.4
```

### 2. **Enregistrements AAAA (IPv6) - Optionnel**

```dns
dashboard-n8n.eu.        AAAA    2001:bc8:1201:51:1618:77ff:fe59:2cc8
www.dashboard-n8n.eu.    AAAA    2001:bc8:1201:51:1618:77ff:fe59:2cc8
```

## 🏢 **Configuration selon votre fournisseur DNS**

### **Option 1: Cloudflare**

1. Connectez-vous à [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Sélectionnez votre domaine `dashboard-n8n.eu`
3. Allez dans l'onglet **DNS**
4. Ajoutez les enregistrements :

```
Type: A
Name: @
Content: 51.159.110.4
TTL: Auto
Proxy: 🔴 DNS only (désactivé)

Type: A  
Name: www
Content: 51.159.110.4
TTL: Auto
Proxy: 🔴 DNS only (désactivé)
```

### **Option 2: OVH**

1. Connectez-vous à [OVH Manager](https://www.ovh.com/manager/)
2. Allez dans **Domaines** → `dashboard-n8n.eu`
3. Onglet **Zone DNS**
4. Ajoutez les enregistrements :

```
Sous-domaine: (vide)
Type: A
Cible: 51.159.110.4

Sous-domaine: www
Type: A
Cible: 51.159.110.4
```

### **Option 3: Gandi**

1. Connectez-vous à [Gandi](https://admin.gandi.net)
2. Allez dans **Domaines** → `dashboard-n8n.eu`
3. **Enregistrements DNS**
4. Ajoutez :

```
@ IN A 51.159.110.4
www IN A 51.159.110.4
```

### **Option 4: Namecheap**

1. Connectez-vous à [Namecheap](https://ap.www.namecheap.com/dashboard)
2. **Domain List** → `dashboard-n8n.eu` → **Manage**
3. **Advanced DNS**
4. Ajoutez :

```
Type: A Record
Host: @
Value: 51.159.110.4
TTL: 1 min

Type: A Record
Host: www
Value: 51.159.110.4
TTL: 1 min
```

### **Option 5: Scaleway Domains (si acheté chez Scaleway)**

1. Connectez-vous à [Scaleway Console](https://console.scaleway.com)
2. **Domains and DNS** → `dashboard-n8n.eu`
3. **DNS Records**
4. Ajoutez :

```
Name: @
Type: A
Data: 51.159.110.4

Name: www
Type: A
Data: 51.159.110.4
```

## ⚡ **Configuration rapide avec dig/nslookup**

### **Vérifier la propagation DNS**

```bash
# Vérifier l'enregistrement A
dig dashboard-n8n.eu A +short

# Vérifier avec www
dig www.dashboard-n8n.eu A +short

# Vérifier depuis différents serveurs DNS
dig @8.8.8.8 dashboard-n8n.eu A +short
dig @1.1.1.1 dashboard-n8n.eu A +short
```

### **Résultat attendu**
```
51.159.110.4
```

## 🕐 **Temps de propagation**

- **TTL court (1-5 min)**: 5-15 minutes
- **TTL standard (1 heure)**: 1-2 heures  
- **TTL long (24h)**: Jusqu'à 48 heures

## 🔍 **Vérification en ligne**

Utilisez ces outils pour vérifier la propagation :

- [DNS Checker](https://dnschecker.org)
- [What's My DNS](https://whatsmydns.net)
- [DNS Propagation Checker](https://www.whatsmydns.net)

Recherchez : `dashboard-n8n.eu` et vérifiez que l'IP `51.159.110.4` apparaît.

## 🚨 **Si vous n'avez pas encore de domaine**

### **Option 1: Acheter un domaine**

**Fournisseurs recommandés :**
- [Namecheap](https://www.namecheap.com) - ~10€/an
- [Gandi](https://www.gandi.net) - ~15€/an  
- [OVH](https://www.ovh.com) - ~8€/an
- [Scaleway Domains](https://www.scaleway.com/en/domains/) - ~12€/an

### **Option 2: Utiliser un sous-domaine gratuit**

**Services gratuits :**
- [DuckDNS](https://www.duckdns.org) - `votrenom.duckdns.org`
- [No-IP](https://www.noip.com) - `votrenom.ddns.net`
- [FreeDNS](https://freedns.afraid.org) - Plusieurs domaines disponibles

### **Option 3: Modifier la configuration pour utiliser l'IP directement**

Si vous voulez tester sans domaine, modifiez `/opt/n8n/.env` :

```bash
# Remplacer
DOMAIN_NAME=dashboard-n8n.eu
N8N_HOST=dashboard-n8n.eu

# Par
DOMAIN_NAME=51.159.110.4
N8N_HOST=51.159.110.4
```

Puis redémarrez :
```bash
/opt/n8n/scripts/n8n-manager.sh restart
```

**Accès**: `http://51.159.110.4` (sans SSL)

## ✅ **Vérification finale**

Une fois le DNS configuré, testez :

```bash
# Test de résolution
ping dashboard-n8n.eu

# Test HTTP
curl -I http://dashboard-n8n.eu

# Test HTTPS (après génération SSL)
curl -I https://dashboard-n8n.eu
```

## 🔐 **Génération automatique SSL**

Une fois le DNS configuré, les certificats SSL Let's Encrypt seront générés automatiquement au premier accès HTTPS.

**Logs SSL** :
```bash
/opt/n8n/scripts/n8n-manager.sh logs certbot
```

---

## 📞 **Support DNS**

Si vous rencontrez des problèmes :

1. **Vérifiez la propagation** avec les outils en ligne
2. **Attendez 1-2 heures** pour la propagation complète
3. **Vérifiez les logs** : `/opt/n8n/scripts/n8n-manager.sh logs nginx`
4. **Testez avec l'IP directement** en cas de problème DNS

---

**Votre serveur Scaleway** : `51.159.110.4`
**Configuration n8n** : `/opt/n8n/.env`
**Gestion** : `/opt/n8n/scripts/n8n-manager.sh`
