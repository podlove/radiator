set podcast_id 3
set episode_id 5
set filepath "/Users/ericteubert/Downloads/amazon-icon.svg"

set filename (string split -n -r -m1 / $filepath | tail -n 1)

# get presigned url
set requester_url "http://localhost:4000/api/podcasts/$podcast_id/episodes/$episode_id/upload/$filename"
set presigned_url (curl -s -X POST $requester_url | jq -r .upload_url)

set curl_date (date -R)

# do actual upload
curl -i -X PUT -T "$filepath" \
    -H "Date: $curl_date" \
    -H "Content-Type: application/octet-stream" \
    $presigned_url
