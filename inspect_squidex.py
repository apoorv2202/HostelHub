import json
import urllib.request
import urllib.parse

client_id = 'hostel-hub:default'
client_secret = '1sgqb4en6pzeul5fckl4kyzp2j3xxcr2adnegtx8kegx'
app_name = 'hostel-hub'
api_url = 'https://cloud.squidex.io/api/content/hostel-hub'

# Authenticate
token_url = 'https://cloud.squidex.io/identity-server/connect/token'
data = urllib.parse.urlencode({
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'squidex-api'
}).encode('utf-8')

req = urllib.request.Request(token_url, data=data, headers={'Content-Type': 'application/x-www-form-urlencoded'})
try:
    with urllib.request.urlopen(req) as response:
        res_data = json.loads(response.read().decode('utf-8'))
        access_token = res_data['access_token']
        print("Authenticated successfully.")
except Exception as e:
    print("Error authenticating:", e)
    exit(1)

# Get food items
items_url = f"{api_url}/food-items"
req_items = urllib.request.Request(items_url, headers={
    'Authorization': f'Bearer {access_token}',
    'Cache-Control': 'no-cache'
})

try:
    with urllib.request.urlopen(req_items) as response:
        res_items = json.loads(response.read().decode('utf-8'))
        print("Food Items fetched successfully.")
        # Pretty print the first item's data to inspect fields
        if res_items.get('items'):
            print(json.dumps(res_items['items'][0], indent=2))
        else:
            print("No items found.")
except Exception as e:
    print("Error fetching items:", e)
