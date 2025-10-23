/**
 * Auto-translate JSON translation files using Google Cloud Translate API
 * Usage: node translate_json.js
 */

const fs = require('fs').promises;
const path = require('path');
const { Translate } = require('@google-cloud/translate').v2;

// Language mappings
const LANGUAGES = {
  'de': 'German',
  'fr': 'French',
  'es': 'Spanish',
  'lt': 'Lithuanian',
  'el': 'Greek'
};

// Initialize Translate client
const translate = new Translate();

/**
 * Translate text to target language
 */
async function translateText(text, targetLanguage) {
  if (!text || text.trim() === "") {
    return text;
  }
  
  try {
    const [translation] = await translate.translate(text, {
      from: 'en',
      to: targetLanguage
    });
    return translation;
  } catch (error) {
    console.error(`Error translating '${text}' to ${targetLanguage}:`, error.message);
    return text;
  }
}

/**
 * Recursively translate all string values in an object
 */
async function translateDict(data, targetLanguage, path = "") {
  if (typeof data === 'object' && data !== null && !Array.isArray(data)) {
    const result = {};
    for (const [key, value] of Object.entries(data)) {
      const currentPath = path ? `${path}.${key}` : key;
      console.log(`Translating: ${currentPath}`);
      result[key] = await translateDict(value, targetLanguage, currentPath);
    }
    return result;
  } else if (typeof data === 'string') {
    // Skip if string contains only special characters or is a placeholder
    if (data.trim() && !data.startsWith('{') && !data.endsWith('}')) {
      const translated = await translateText(data, targetLanguage);
      console.log(`  '${data}' -> '${translated}'`);
      return translated;
    }
    return data;
  } else {
    return data;
  }
}

async function main() {
  console.log("Initializing Google Cloud Translate API...\n");
  
  // Get the assets/translations directory
  const translationsDir = path.join(__dirname, 'assets', 'translations');
  
  // Read English JSON
  const enFile = path.join(translationsDir, 'en.json');
  console.log(`Reading English translations from: ${enFile}\n`);
  
  const enData = JSON.parse(await fs.readFile(enFile, 'utf-8'));
  console.log(`Found ${Object.keys(enData).length} top-level keys to translate\n`);
  
  // Translate to each language
  for (const [langCode, langName] of Object.entries(LANGUAGES)) {
    console.log('='.repeat(60));
    console.log(`Translating to ${langName} (${langCode})...`);
    console.log('='.repeat(60) + '\n');
    
    // Translate the entire structure
    const translatedData = await translateDict(enData, langCode);
    
    // Save to file
    const outputFile = path.join(translationsDir, `${langCode}.json`);
    console.log(`\nSaving to: ${outputFile}`);
    
    await fs.writeFile(
      outputFile,
      JSON.stringify(translatedData, null, 2),
      'utf-8'
    );
    
    console.log(`✅ ${langName} translation complete!\n`);
  }
  
  console.log('='.repeat(60));
  console.log('🎉 ALL TRANSLATIONS COMPLETE!');
  console.log('='.repeat(60));
  console.log('\nTranslated files:');
  for (const [langCode, langName] of Object.entries(LANGUAGES)) {
    console.log(`  ✅ ${langName}: assets/translations/${langCode}.json`);
  }
}

main().catch(console.error);
