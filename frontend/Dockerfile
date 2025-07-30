# Étape 1: Build de l'application Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de configuration
COPY pubspec.yaml pubspec.lock ./

# Installer les dépendances Flutter
RUN flutter pub get

# Copier le reste du code source
COPY . .

# Configurer Flutter pour le web
RUN flutter config --enable-web

# Builder l'application pour le web
RUN flutter build web --release

# Étape 2: Servir l'application avec nginx
FROM nginx:alpine

# Copier les fichiers buildés vers nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copier la configuration nginx personnalisée
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Commande par défaut
CMD ["nginx", "-g", "daemon off;"]