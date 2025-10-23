#!/usr/bin/env python3
"""
Check Google Cloud Translation API usage and quota.
"""

from google.cloud import monitoring_v3
from google.oauth2 import service_account
from datetime import datetime, timedelta
import sys
import os

def check_quota_usage():
    """Check Translation API usage from Google Cloud Monitoring."""
    
    # Load service account credentials
    credentials_path = os.path.join('assets', 'service_account.json')
    
    if not os.path.exists(credentials_path):
        print("❌ Error: service_account.json not found in assets/ directory")
        print("Please follow TRANSLATION_SETUP_GUIDE.md to set up your credentials")
        return False
    
    try:
        credentials = service_account.Credentials.from_service_account_file(credentials_path)
        
        # Extract project ID from credentials
        with open(credentials_path, 'r', encoding='utf-8') as f:
            import json
            creds_data = json.load(f)
            project_id = creds_data.get('project_id')
        
        if not project_id:
            print("❌ Error: Could not find project_id in service account file")
            return False
        
        print(f"📊 Checking quota usage for project: {project_id}\n")
        
        # Create monitoring client
        client = monitoring_v3.MetricServiceClient(credentials=credentials)
        project_name = f"projects/{project_id}"
        
        # Query for the last 30 days
        now = datetime.utcnow()
        end_time = now
        start_time = now - timedelta(days=30)
        
        interval = monitoring_v3.TimeInterval({
            "start_time": {"seconds": int(start_time.timestamp())},
            "end_time": {"seconds": int(end_time.timestamp())},
        })
        
        # Query for character count
        results = client.list_time_series(
            request={
                "name": project_name,
                "filter": 'metric.type = "translate.googleapis.com/character_count"',
                "interval": interval,
                "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
            }
        )
        
        total_characters = 0
        results_found = False
        
        for result in results:
            results_found = True
            for point in result.points:
                total_characters += point.value.int64_value
        
        if not results_found:
            print("ℹ️  No usage data found yet. This could mean:")
            print("   • You haven't used the Translation API yet")
            print("   • Metrics haven't been collected yet (can take a few hours)")
            print("\n💡 Alternative: Check directly in Cloud Console")
            print("   https://console.cloud.google.com/apis/api/translate.googleapis.com/quotas")
        else:
            quota_limit = 500000  # 500K free tier
            remaining = quota_limit - total_characters
            percentage_used = (total_characters / quota_limit) * 100
            
            print("=" * 60)
            print(f"📈 Translation API Usage (Last 30 Days)")
            print("=" * 60)
            print(f"  Characters Used:     {total_characters:,}")
            print(f"  Quota Limit:         {quota_limit:,}")
            print(f"  Remaining:           {remaining:,}")
            print(f"  Usage:               {percentage_used:.2f}%")
            print("=" * 60)
            
            if remaining < 50000:
                print("\n⚠️  Warning: Less than 50K characters remaining!")
                print("   Consider upgrading or waiting for quota reset")
            elif percentage_used < 50:
                print("\n✅ Good: Plenty of quota remaining")
            else:
                print("\n⚠️  Caution: Over 50% of quota used")
        
        print(f"\n🔗 View detailed metrics:")
        print(f"   https://console.cloud.google.com/monitoring/metrics-explorer?project={project_id}")
        print(f"\n🔗 View quotas:")
        print(f"   https://console.cloud.google.com/apis/api/translate.googleapis.com/quotas?project={project_id}")
        
        return True
        
    except ImportError:
        print("❌ Error: google-cloud-monitoring library not installed")
        print("\nInstall with:")
        print("   pip install google-cloud-monitoring")
        return False
        
    except Exception as e:
        print(f"❌ Error checking quota: {str(e)}")
        print("\n💡 You can check manually in Google Cloud Console:")
        print("   1. Go to https://console.cloud.google.com")
        print("   2. Select your project")
        print("   3. Navigate to: APIs & Services → Cloud Translation API → Quotas")
        return False

def estimate_translation_cost():
    """Estimate how many characters will be translated."""
    
    print("\n" + "=" * 60)
    print("📊 Estimating Translation Requirements")
    print("=" * 60)
    
    try:
        import json
        
        en_json_path = os.path.join('assets', 'translations', 'en.json')
        
        if not os.path.exists(en_json_path):
            print("❌ Error: en.json not found")
            return
        
        with open(en_json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Count total characters
        def count_chars(obj):
            total = 0
            if isinstance(obj, dict):
                for val in obj.values():
                    total += count_chars(val)
            elif isinstance(obj, str):
                total += len(obj)
            elif isinstance(obj, list):
                for item in obj:
                    total += count_chars(item)
            return total
        
        total_chars = count_chars(data)
        num_languages = 30  # 30 languages as per your requirement
        total_to_translate = total_chars * num_languages
        
        print(f"  English text length:     {total_chars:,} characters")
        print(f"  Number of languages:     {num_languages}")
        print(f"  Total to translate:      {total_to_translate:,} characters")
        print("=" * 60)
        
        if total_to_translate < 500000:
            print(f"\n✅ Good news! Translation should fit within free tier")
            print(f"   ({500000 - total_to_translate:,} characters remaining after)")
        else:
            overage = total_to_translate - 500000
            cost = (overage / 1000000) * 20  # $20 per 1M characters
            print(f"\n⚠️  Warning: Will exceed free tier by {overage:,} characters")
            print(f"   Estimated cost: ${cost:.2f}")
        
    except Exception as e:
        print(f"❌ Error estimating cost: {str(e)}")

if __name__ == '__main__':
    print("🔍 Google Cloud Translation API Quota Checker\n")
    
    # Estimate what you'll need
    estimate_translation_cost()
    
    # Check current usage
    print("\n")
    check_quota_usage()
