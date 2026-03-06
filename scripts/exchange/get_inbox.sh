#!/bin/bash

# ===== CONFIG VIA ENV =====
EWS_URL="${EWS_URL}"
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"

# ===== VALIDATION =====
if [ -z "$EWS_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Missing env vars. Please set EWS_URL, USERNAME and PASSWORD."
  exit 1
fi

# ===== SOAP REQUEST =====
read -r -d '' SOAP_BODY <<EOF
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
        <t:BaseShape>AllProperties</t:BaseShape>
      </m:ItemShape>
      <m:IndexedPageItemView MaxEntriesReturned="20" Offset="0" BasePoint="Beginning"/>
      <m:ParentFolderIds>
        <t:DistinguishedFolderId Id="inbox"/>
      </m:ParentFolderIds>
    </m:FindItem>
  </soap:Body>
</soap:Envelope>
EOF

# ===== CURL CALL =====
curl --ntlm \
     --silent \
     --user "$USERNAME:$PASSWORD" \
     --header "Content-Type: text/xml; charset=utf-8" \
     --data "$SOAP_BODY" \
     "$EWS_URL"