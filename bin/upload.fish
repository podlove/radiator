set filepath "/Users/ericteubert/Downloads/teensy.dmg"

set filename (string split -n -r -m1 / $filepath | tail -n 1)

set get_upload_url "http://localhost:4000/api/v1/upload/?filename=$filename"
set access_url "http://localhost:4000/api/v1/files/$filename"

# get presigned url
set presigned_url (curl -s -X POST $get_upload_url | jq -r .upload_url)

set curl_date (date -R)

echo "=== upload file ==="
echo ""
curl -i -X PUT -T "$filepath" \
    -H "Date: $curl_date" \
    -H "Content-Type: application/octet-stream" \
    $presigned_url

echo "=== test access the file ==="
echo ""
curl -s $access_url | jq
