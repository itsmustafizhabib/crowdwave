#!/bin/bash
# Check Google Cloud Translation API Quota using gcloud CLI

echo "🔍 Checking Translation API Quota..."
echo ""

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ No project set. Run: gcloud config set project PROJECT_ID"
    exit 1
fi

echo "📊 Project: $PROJECT_ID"
echo ""

# Check if Translation API is enabled
echo "Checking if Translation API is enabled..."
API_ENABLED=$(gcloud services list --enabled --filter="name:translate.googleapis.com" --format="value(name)" 2>/dev/null)

if [ -z "$API_ENABLED" ]; then
    echo "❌ Translation API is NOT enabled"
    echo ""
    echo "To enable it, run:"
    echo "  gcloud services enable translate.googleapis.com"
    exit 1
else
    echo "✅ Translation API is enabled"
fi

echo ""
echo "============================================================"
echo "📈 Quota Information"
echo "============================================================"

# Estimate translation requirements
if [ -f "assets/translations/en.json" ]; then
    EN_CHARS=$(cat assets/translations/en.json | wc -m)
    LANGUAGES=30
    TOTAL_CHARS=$((EN_CHARS * LANGUAGES))
    
    echo "  English JSON size:       $(printf '%,d' $EN_CHARS) characters"
    echo "  Target languages:        $LANGUAGES"
    echo "  Total to translate:      $(printf '%,d' $TOTAL_CHARS) characters"
    echo ""
    
    if [ $TOTAL_CHARS -lt 500000 ]; then
        REMAINING=$((500000 - TOTAL_CHARS))
        echo "  ✅ Should fit in free tier (500K/month)"
        echo "  Estimated remaining:     $(printf '%,d' $REMAINING) characters"
    else
        OVERAGE=$((TOTAL_CHARS - 500000))
        COST=$(echo "scale=2; $OVERAGE / 1000000 * 20" | bc)
        echo "  ⚠️  Will exceed free tier by $(printf '%,d' $OVERAGE) characters"
        echo "  Estimated cost:          \$$COST"
    fi
else
    echo "  ⚠️  en.json not found - cannot estimate"
fi

echo "============================================================"
echo ""
echo "🔗 View detailed quota in Cloud Console:"
echo "   https://console.cloud.google.com/apis/api/translate.googleapis.com/quotas?project=$PROJECT_ID"
echo ""
echo "📊 View usage metrics:"
echo "   https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID&pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22translate.googleapis.com%2Fcharacter_count%5C%22%22%7D%7D%5D%7D%7D"
echo ""
echo "💡 The free tier provides 500,000 characters per month"
echo "   After that, it's \$20 per 1 million characters"
echo ""
