#!/usr/bin/env python3
"""
Script to add receiver details translation keys to all language JSON files
"""

import json
import os
from pathlib import Path

# Translation keys and their English values
RECEIVER_DETAILS_KEYS = {
    "step_receiver_details": "Receiver Details",
    "subtitle_receiver_details": "Who will receive this package at the destination?",
    "receiver_details_title": "Receiver Information",
    "receiver_details_subtitle": "Enter the contact details of the person receiving this package",
    "receiver_name": "Receiver Name",
    "receiver_name_hint": "Full name of the recipient",
    "receiver_name_required": "Please enter the receiver's name",
    "receiver_phone": "Receiver Phone Number",
    "receiver_phone_hint": "+1234567890",
    "receiver_phone_required": "Please enter the receiver's phone number",
    "receiver_phone_invalid": "Please enter a valid phone number",
    "receiver_email": "Receiver Email (Optional)",
    "receiver_email_hint": "recipient@email.com",
    "receiver_email_invalid": "Please enter a valid email address",
    "receiver_alt_phone": "Alternative Phone (Optional)",
    "receiver_alt_phone_hint": "Backup contact number",
    "receiver_notes": "Delivery Notes for Receiver",
    "receiver_notes_hint": "e.g., Ring doorbell, call upon arrival, leave with neighbor...",
    "receiver_details_info": "💡 The receiver doesn't need a CrowdWave account. We'll contact them when the package is ready for delivery.",
    "validation_receiver_required": "Please provide receiver details",
}

# Language-specific translations (optional - for better translations)
LANGUAGE_TRANSLATIONS = {
    "de": {
        "step_receiver_details": "Empfänger-Details",
        "subtitle_receiver_details": "Wer wird dieses Paket am Zielort empfangen?",
        "receiver_details_title": "Empfängerinformationen",
        "receiver_details_subtitle": "Geben Sie die Kontaktdaten der Person ein, die dieses Paket empfängt",
        "receiver_name": "Name des Empfängers",
        "receiver_name_hint": "Vollständiger Name des Empfängers",
        "receiver_name_required": "Bitte geben Sie den Namen des Empfängers ein",
        "receiver_phone": "Telefonnummer des Empfängers",
        "receiver_phone_hint": "+1234567890",
        "receiver_phone_required": "Bitte geben Sie die Telefonnummer des Empfängers ein",
        "receiver_phone_invalid": "Bitte geben Sie eine gültige Telefonnummer ein",
        "receiver_email": "E-Mail des Empfängers (Optional)",
        "receiver_email_hint": "empfaenger@email.com",
        "receiver_email_invalid": "Bitte geben Sie eine gültige E-Mail-Adresse ein",
        "receiver_alt_phone": "Alternative Telefonnummer (Optional)",
        "receiver_alt_phone_hint": "Backup-Kontaktnummer",
        "receiver_notes": "Lieferhinweise für Empfänger",
        "receiver_notes_hint": "z.B. Klingeln, bei Ankunft anrufen, beim Nachbarn abgeben...",
        "receiver_details_info": "💡 Der Empfänger benötigt kein CrowdWave-Konto. Wir kontaktieren ihn, wenn das Paket zur Lieferung bereit ist.",
        "validation_receiver_required": "Bitte geben Sie die Empfängerdaten an",
    },
    "fr": {
        "step_receiver_details": "Détails du Destinataire",
        "subtitle_receiver_details": "Qui recevra ce colis à destination ?",
        "receiver_details_title": "Informations sur le Destinataire",
        "receiver_details_subtitle": "Entrez les coordonnées de la personne qui recevra ce colis",
        "receiver_name": "Nom du Destinataire",
        "receiver_name_hint": "Nom complet du destinataire",
        "receiver_name_required": "Veuillez entrer le nom du destinataire",
        "receiver_phone": "Numéro de Téléphone du Destinataire",
        "receiver_phone_hint": "+33123456789",
        "receiver_phone_required": "Veuillez entrer le numéro de téléphone du destinataire",
        "receiver_phone_invalid": "Veuillez entrer un numéro de téléphone valide",
        "receiver_email": "Email du Destinataire (Optionnel)",
        "receiver_email_hint": "destinataire@email.com",
        "receiver_email_invalid": "Veuillez entrer une adresse email valide",
        "receiver_alt_phone": "Téléphone Alternatif (Optionnel)",
        "receiver_alt_phone_hint": "Numéro de contact de secours",
        "receiver_notes": "Notes de Livraison pour le Destinataire",
        "receiver_notes_hint": "par ex., Sonner à la porte, appeler à l'arrivée, laisser chez le voisin...",
        "receiver_details_info": "💡 Le destinataire n'a pas besoin de compte CrowdWave. Nous le contacterons lorsque le colis sera prêt pour la livraison.",
        "validation_receiver_required": "Veuillez fournir les détails du destinataire",
    },
    "es": {
        "step_receiver_details": "Detalles del Receptor",
        "subtitle_receiver_details": "¿Quién recibirá este paquete en el destino?",
        "receiver_details_title": "Información del Receptor",
        "receiver_details_subtitle": "Ingrese los datos de contacto de la persona que recibirá este paquete",
        "receiver_name": "Nombre del Receptor",
        "receiver_name_hint": "Nombre completo del destinatario",
        "receiver_name_required": "Por favor ingrese el nombre del receptor",
        "receiver_phone": "Número de Teléfono del Receptor",
        "receiver_phone_hint": "+34123456789",
        "receiver_phone_required": "Por favor ingrese el número de teléfono del receptor",
        "receiver_phone_invalid": "Por favor ingrese un número de teléfono válido",
        "receiver_email": "Correo del Receptor (Opcional)",
        "receiver_email_hint": "receptor@email.com",
        "receiver_email_invalid": "Por favor ingrese una dirección de correo válida",
        "receiver_alt_phone": "Teléfono Alternativo (Opcional)",
        "receiver_alt_phone_hint": "Número de contacto de respaldo",
        "receiver_notes": "Notas de Entrega para el Receptor",
        "receiver_notes_hint": "ej., Tocar timbre, llamar al llegar, dejar con vecino...",
        "receiver_details_info": "💡 El receptor no necesita una cuenta de CrowdWave. Lo contactaremos cuando el paquete esté listo para la entrega.",
        "validation_receiver_required": "Por favor proporcione los detalles del receptor",
    },
    "it": {
        "step_receiver_details": "Dettagli del Destinatario",
        "subtitle_receiver_details": "Chi riceverà questo pacco a destinazione?",
        "receiver_details_title": "Informazioni sul Destinatario",
        "receiver_details_subtitle": "Inserisci i dettagli di contatto della persona che riceverà questo pacco",
        "receiver_name": "Nome del Destinatario",
        "receiver_name_hint": "Nome completo del destinatario",
        "receiver_name_required": "Inserisci il nome del destinatario",
        "receiver_phone": "Numero di Telefono del Destinatario",
        "receiver_phone_hint": "+39123456789",
        "receiver_phone_required": "Inserisci il numero di telefono del destinatario",
        "receiver_phone_invalid": "Inserisci un numero di telefono valido",
        "receiver_email": "Email del Destinatario (Opzionale)",
        "receiver_email_hint": "destinatario@email.com",
        "receiver_email_invalid": "Inserisci un indirizzo email valido",
        "receiver_alt_phone": "Telefono Alternativo (Opzionale)",
        "receiver_alt_phone_hint": "Numero di contatto di backup",
        "receiver_notes": "Note di Consegna per il Destinatario",
        "receiver_notes_hint": "es., Suonare il campanello, chiamare all'arrivo, lasciare dal vicino...",
        "receiver_details_info": "💡 Il destinatario non ha bisogno di un account CrowdWave. Lo contatteremo quando il pacco sarà pronto per la consegna.",
        "validation_receiver_required": "Fornisci i dettagli del destinatario",
    },
}

def add_keys_to_json_file(file_path: Path, lang_code: str):
    """Add receiver details keys to a single JSON file"""
    try:
        # Read existing JSON
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Check if post_package section exists
        if 'post_package' not in data:
            print(f"⚠️  'post_package' section not found in {file_path.name}")
            return False
        
        # Get appropriate translations
        translations = LANGUAGE_TRANSLATIONS.get(lang_code, RECEIVER_DETAILS_KEYS)
        
        # Add keys to post_package section
        added_count = 0
        for key, value in RECEIVER_DETAILS_KEYS.items():
            if key not in data['post_package']:
                # Use language-specific translation if available, otherwise use English
                data['post_package'][key] = translations.get(key, value)
                added_count += 1
        
        # Write back to file
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {file_path.name}: Added {added_count} keys")
        return True
        
    except Exception as e:
        print(f"❌ Error processing {file_path.name}: {e}")
        return False

def main():
    # Get the translations directory
    script_dir = Path(__file__).parent
    translations_dir = script_dir / 'assets' / 'translations'
    
    if not translations_dir.exists():
        print(f"❌ Translations directory not found: {translations_dir}")
        return
    
    print("🌍 Adding receiver details keys to all translation files...\n")
    
    # Process all JSON files
    json_files = list(translations_dir.glob('*.json'))
    success_count = 0
    
    for json_file in sorted(json_files):
        lang_code = json_file.stem  # Get language code from filename
        if add_keys_to_json_file(json_file, lang_code):
            success_count += 1
    
    print(f"\n✨ Completed! Successfully updated {success_count}/{len(json_files)} files")

if __name__ == '__main__':
    main()
