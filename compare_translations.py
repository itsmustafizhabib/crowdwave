import json

def get_all_keys(d, prefix=''):
    """Recursively get all keys from nested dictionary"""
    keys = []
    for k, v in d.items():
        if isinstance(v, dict):
            keys.extend(get_all_keys(v, prefix + k + '.'))
        else:
            keys.append(prefix + k)
    return keys

# Load both JSON files
with open('assets/translations/en.json', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open('assets/translations/de.json', 'r', encoding='utf-8') as f:
    de_data = json.load(f)

# Get all keys
en_keys = set(get_all_keys(en_data))
de_keys = set(get_all_keys(de_data))

# Find differences
missing_in_de = sorted(en_keys - de_keys)
extra_in_de = sorted(de_keys - en_keys)

print(f"Total keys in EN: {len(en_keys)}")
print(f"Total keys in DE: {len(de_keys)}")
print(f"\nMissing in DE: {len(missing_in_de)}")
print(f"Extra in DE: {len(extra_in_de)}")

if missing_in_de:
    print("\n=== MISSING KEYS IN GERMAN (First 50) ===")
    for key in missing_in_de[:50]:
        print(f"  - {key}")
    if len(missing_in_de) > 50:
        print(f"  ... and {len(missing_in_de) - 50} more")

if extra_in_de:
    print("\n=== EXTRA KEYS IN GERMAN (First 20) ===")
    for key in extra_in_de[:20]:
        print(f"  - {key}")

# Check if structures match
print(f"\n{'='*60}")
if missing_in_de or extra_in_de:
    print("❌ The German translation is NOT complete/exact!")
    print(f"   {len(missing_in_de)} keys are missing")
    print(f"   {len(extra_in_de)} extra keys exist")
else:
    print("✅ The German translation has the exact same structure as English!")
