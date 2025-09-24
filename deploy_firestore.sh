#!/bin/bash

# Deploy Firestore indexes and rules
echo "Deploying Firestore configuration..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Login to Firebase (if not already logged in)
echo "Checking Firebase authentication..."
firebase login --no-localhost

# Deploy Firestore indexes
echo "Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

# Deploy Firestore security rules
echo "Deploying Firestore security rules..."
firebase deploy --only firestore:rules --project-config-file updated_firestore_security_rules.rules

echo "✅ Firestore configuration deployed successfully!"
echo "🔍 Indexes may take a few minutes to build. Check the Firebase Console for progress."
