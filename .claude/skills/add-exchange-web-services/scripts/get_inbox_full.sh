#!/bin/bash

EWS_URL="${EWS_URL}"
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"

if [ -z "$EWS_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Missing env vars. Please set EWS_URL, USERNAME and PASSWORD."
  exit 1
fi

# ===== STEP 1: Get Item IDs =====
read -r -d '' FIND_BODY <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages"
               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <t:RequestServerVersion Version="Exchange2016"/>
  </soap:Header>
  <soap:Body>
    <m:FindItem Traversal="Shallow">
      <m:ItemShape>
        <t:BaseShape>IdOnly</t:BaseShape>
      </m:ItemShape>
      <m:IndexedPageItemView MaxEntriesReturned="10" Offset="0" BasePoint="Beginning"/>
      <m:ParentFolderIds>
        <t:DistinguishedFolderId Id="inbox"/>
      </m:ParentFolderIds>
    </m:FindItem>
  </soap:Body>
</soap:Envelope>
EOF

ITEMS=$(curl --ntlm --silent \
     --user "$USERNAME:$PASSWORD" \
     --header "Content-Type: text/xml; charset=utf-8" \
     --data "$FIND_BODY" \
     "$EWS_URL")

# Extract ItemIds using xmllint
IDS=$(echo "$ITEMS" | xmllint --xpath \
  "//*[local-name()='ItemId']/@Id" - 2>/dev/null | \
  sed 's/Id="\([^"]*\)"/\1\n/g')

# ===== STEP 2: Get Full Message For Each ID =====
for ID in $IDS; do

read -r -d '' GET_BODY <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages"
               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <t:RequestServerVersion Version="Exchange2016"/>
  </soap:Header>
  <soap:Body>
    <m:GetItem>
      <m:ItemShape>
        <t:BaseShape>AllProperties</t:BaseShape>
        <t:BodyType>Text</t:BodyType>
      </m:ItemShape>
      <m:ItemIds>
        <t:ItemId Id="$ID"/>
      </m:ItemIds>
    </m:GetItem>
  </soap:Body>
</soap:Envelope>
EOF

curl --ntlm --silent \
     --user "$USERNAME:$PASSWORD" \
     --header "Content-Type: text/xml; charset=utf-8" \
     --data "$GET_BODY" \
     "$EWS_URL"

echo -e "\n-----------------------------\n"

done