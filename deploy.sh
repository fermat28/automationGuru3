#!/bin/bash

set -e

trap 'echo "❌ Erreur détectée à la ligne $LINENO. Arrêt du script." >&2' ERR

cd terraform-config || { echo "Erreur : impossible d'accéder au dossier terraform-config" >&2; exit 1; }

echo "🚀 Initialisation Terraform..."
terraform init || { echo "Erreur : échec de l'initialisation Terraform" >&2; exit 1; }

echo "✅ Application Terraform..."
terraform apply -auto-approve || { echo "Erreur : échec de l'application Terraform" >&2; exit 1; }

cd ../ansible-project || { echo "Erreur : impossible d'accéder au dossier ansible-project" >&2; exit 1; }

echo "📦 Déploiement Ansible avec inventaire généré par Terraform..."
ansible-playbook -i inventory.ini frontend-install.yaml || { echo "Erreur : échec du playbook frontend-install.yaml" >&2; exit 1; }
ansible-playbook -i inventory.ini deploy-website.yaml || { echo "Erreur : échec du playbook deploy-website.yaml" >&2; exit 1; }
ansible-playbook -i inventory.ini deploy-certificate.yml || { echo "Erreur : échec du playbook deploy-certificate.yml" >&2; exit 1; }
ansible-playbook -i inventory.ini backend-install.yaml || { echo "Erreur : échec du playbook backend-install.yaml" >&2; exit 1; }

echo "✅ Déploiement terminé."