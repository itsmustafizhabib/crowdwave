import json
import os
import glob

# Translations for "Description" in each language
translations = {
    "en.json": "Description",
    "bg.json": "Описание",
    "cs.json": "Popis",
    "da.json": "Beskrivelse",
    "de.json": "Beschreibung",
    "el.json": "Περιγραφή",
    "es.json": "Descripción",
    "et.json": "Kirjeldus",
    "fi.json": "Kuvaus",
    "fr.json": "Description",
    "ga.json": "Cur síos",
    "hr.json": "Opis",
    "hu.json": "Leírás",
    "it.json": "Descrizione",
    "lt.json": "Aprašymas",
    "lv.json": "Apraksts",
    "mt.json": "Deskrizzjoni",
    "nl.json": "Beschrijving",
    "pl.json": "Opis",
    "pt.json": "Descrição",
    "ro.json": "Descriere",
    "sk.json": "Popis",
    "sl.json": "Opis",
    "sv.json": "Beskrivning",
}

translations_dir = "assets/translations"

for filename, translation in translations.items():
    filepath = os.path.join(translations_dir, filename)
    
    if not os.path.exists(filepath):
        print(f"Skipping {filename} - file not found")
        continue
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Add description key if it doesn't exist
        if "common" in data:
            if "description" not in data["common"]:
                # Find the position after "search" to insert
                keys = list(data["common"].keys())
                if "search" in keys:
                    search_idx = keys.index("search")
                    # Create new dict with description inserted after search
                    new_common = {}
                    for i, key in enumerate(keys):
                        new_common[key] = data["common"][key]
                        if i == search_idx:
                            new_common["description"] = translation
                    data["common"] = new_common
                else:
                    # Just add it at the end if search not found
                    data["common"]["description"] = translation
                
                # Write back
                with open(filepath, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                
                print(f"✓ Added 'description' to {filename}")
            else:
                print(f"○ {filename} already has 'description' key")
        else:
            print(f"✗ {filename} has no 'common' section")
    
    except Exception as e:
        print(f"✗ Error processing {filename}: {e}")

print("\nDone!")
