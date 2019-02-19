set podcast_id 3
set episode_id 5
set filepath "/Users/ericteubert/Downloads/amazon-icon.svg"

set filename (string split -n -r -m1 / $filepath | tail -n 1)

# PUT $storage_url uploads file
# GET $storage_url downloads file
set storage_url "http://localhost:4000/api/podcasts/$podcast_id/episodes/$episode_id/upload/$filename"

# get presigned url
set presigned_url (curl -s -X POST $storage_url | jq -r .upload_url)

set curl_date (date -R)

echo "=== upload file ==="
echo ""
curl -i -X PUT -T "$filepath" \
    -H "Date: $curl_date" \
    -H "Content-Type: application/octet-stream" \
    $presigned_url

echo "=== test access the file ==="
echo ""
curl -I $storage_url
