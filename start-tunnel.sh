#!/bin/bash
LOG_FILE="/tmp/cloudflared.log"
REDIRECT_REPO="$Home/Desktop/我的程式/web_page_2/Dit_Official_Website/frontend"

cloudflared tunnel --url http://localhost:5173 >"$LOG_FILE" 2>&1 &
CLOUDFLARED_PID=$!

while true;do
URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$LOG_FILE"|head -n 1)
if [ -n "$URL" ];then
break
fi
sleep 1
done

cat >"$REDIRECT_REPO/index.html" <<EOF
<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="0;url=$URL">
<script>
window.location.replace("$URL")
</script>
</head>
<body></body>
</html>
EOF

cd "$REDIRECT_REPO"||exit 1
git add index.html

if ! git diff --cached --quiet;then
git commit -m "Update Cloudflare Tunnel URL"
git push
fi

echo "Tunnel URL: $URL"

wait $CLOUDFLARED_PID