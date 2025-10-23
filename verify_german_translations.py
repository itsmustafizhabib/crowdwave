import json

def get_all_values(d, prefix=''):
    """Recursively get all key-value pairs from nested dictionary"""
    items = []
    for k, v in d.items():
        full_key = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            items.extend(get_all_values(v, full_key))
        else:
            items.append((full_key, v))
    return items

# Load both JSON files
with open('assets/translations/en.json', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open('assets/translations/de.json', 'r', encoding='utf-8') as f:
    de_data = json.load(f)

# Get all key-value pairs
en_items = {k: v for k, v in get_all_values(en_data)}
de_items = {k: v for k, v in get_all_values(de_data)}

# Check how many translations are identical (not translated)
identical_count = 0
different_count = 0
identical_examples = []

for key in en_items:
    if key in de_items:
        en_val = str(en_items[key]).strip()
        de_val = str(de_items[key]).strip()
        
        # Skip keys that shouldn't be translated (like app name, URLs, etc)
        skip_keys = ['app.name', 'common.debug', 'common.ok']
        if any(key.startswith(sk) for sk in skip_keys):
            continue
            
        if en_val == de_val:
            identical_count += 1
            if len(identical_examples) < 10:
                identical_examples.append(f"{key}: '{en_val}' = '{de_val}'")
        else:
            different_count += 1

total = identical_count + different_count
print(f"Total comparable keys: {total}")
print(f"Identical (not translated): {identical_count} ({identical_count/total*100:.1f}%)")
print(f"Different (translated): {different_count} ({different_count/total*100:.1f}%)")

if identical_examples:
    print("\n=== Examples of identical (possibly not translated) ===")
    for example in identical_examples:
        print(f"  {example}")

# Sample some German translations to verify
print("\n=== Sample German translations ===")
sample_keys = [
    'common.yes',
    'common.no', 
    'common.cancel',
    'home.title',
    'home.greeting',
    'profile.title',
    'wallet.title',
    'orders.title'
]

for key in sample_keys:
    if key in de_items:
        print(f"{key}: '{de_items[key]}'")

print("\n" + "="*60)
if identical_count < total * 0.1:  # Less than 10% identical
    print("✅ The German file appears to be properly translated!")
else:
    print("⚠️ Warning: Many keys have identical values - may need translation review")
