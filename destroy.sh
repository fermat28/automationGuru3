#!/bin/bash

set -e

trap 'echo "❌ Erreur détectée à la ligne $LINENO. Arrêt du script." >&2' ERR

cd terraform-config || { echo "Erreur : impossible d'accéder au dossier terraform-config" >&2; exit 1; }

echo "🚨 Initialisation Terraform..."
terraform init || { echo "Erreur : échec de l'initialisation Terraform" >&2; exit 1; }

echo "🗑️  Destruction de l'infrastructure Terraform..."
terraform destroy -auto-approve || { echo "Erreur : échec de la destruction Terraform" >&2; exit 1; }

echo "✅ Infrastructure détruite avec succès."
