#!/bin/bash

# ===== CONFIG VIA ENV =====
EWS_URL="${EWS_URL}"
USERNAME="${USERNAME}"
PASSWORD="${PASSWORD}"
DAY="$1"

# ===== VALIDATION =====
if [ -z "$EWS_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$DAY" ]; then
  echo "Usage: DAY=<YYYY-MM-DD> EWS_URL=... USERNAME=... PASSWORD=... $0 <YYYY-MM-DD>"
  echo "Missing env vars. Please set EWS_URL, USERNAME and PASSWORD."
  exit 1
fi

# Build full day range
START_DATE="${DAY}T00:00:00"
END_DATE="${DAY}T23:59:59"

# ===== SOAP REQUEST =====
read -r -d '' SOAP_BODY <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages"
               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <t:RequestServerVersion Version="Exchange2016" />
  </soap:Header>
  <soap:Body>
    <m:FindItem Traversal="Shallow">
      <m:ItemShape>
        <t:BaseShape>AllProperties</t:BaseShape>
      </m:ItemShape>
      <m:CalendarView StartDate="$START_DATE"
                      EndDate="$END_DATE" />
      <m:ParentFolderIds>
        <t:DistinguishedFolderId Id="calendar"/>
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