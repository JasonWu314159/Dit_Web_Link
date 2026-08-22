#!/bin/bash
LOG_FILE="/tmp/cloudflared.log"
REDIRECT_REPO="$HOME/Desktop/我的程式/web_page_2/Dit_Web_Linker"

cloudflared tunnel --url http://localhost:5173 >"$LOG_FILE" 2>&1 &
CLOUDFLARED_PID=$!

while true;do
URL=$(grep -ao 'https://[^ ]*\.trycloudflare\.com' "$LOG_FILE"|head -n 1)

if [ -n "$URL" ];then
break
fi

if ! kill -0 "$CLOUDFLARED_PID" 2>/dev/null;then
echo "Cloudflare Tunnel 啟動失敗"
cat "$LOG_FILE"
exit 1
fi

sleep 1
done

cat >"$REDIRECT_REPO/index.html" <<EOF
<!doctype html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Cache-Control" content="no-cache,no-store,must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
<title>DIT Robotics</title>
<style>
*{box-sizing:border-box}
body{
margin:0;
min-height:100vh;
display:flex;
align-items:center;
justify-content:center;
background:#111;
color:#fff;
font-family:Arial,sans-serif;
}
.container{
text-align:center;
padding:30px;
}
h1{
font-size:32px;
margin-bottom:12px;
}
p{
color:#aaa;
font-size:16px;
}
.loading{
width:32px;
height:32px;
margin:25px auto;
border:3px solid #333;
border-top-color:#fff;
border-radius:50%;
animation:spin 1s linear infinite;
}
.error{
display:none;
}
.error h1{
color:#ff6b6b;
}
button{
margin-top:20px;
padding:10px 24px;
border:0;
border-radius:8px;
cursor:pointer;
font-size:15px;
}
@keyframes spin{
to{transform:rotate(360deg)}
}
</style>
</head>
<body>
<div class="container">
<div id="checking">
<h1>DIT Robotics</h1>
<p>正在連接伺服器...</p>
<div class="loading"></div>
</div>

<div id="error" class="error">
<h1>Server Offline</h1>
<p>目前無法連接至 DIT Robotics Server。</p>
<p>請稍後再試，或聯絡網站管理員。</p>
<button onclick="location.reload()">重新嘗試</button>
</div>
</div>

<script>
const server="$URL"

function offline(){
document.getElementById("checking").style.display="none"
document.getElementById("error").style.display="block"
}

function checkServer(){
const img=new Image()
let finished=false

const timeout=setTimeout(()=>{
if(finished)return
finished=true
offline()
},5000)

img.onload=success
img.onerror=success

function success(){
if(finished)return
finished=true
clearTimeout(timeout)
location.replace(server)
}

img.src=server+"/favicon.ico?t="+Date.now()
}

checkServer()
</script>
</body>
</html>
EOF

cd "$REDIRECT_REPO"||exit 1
git add index.html

if ! git diff --cached --quiet;then
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "Update Cloudflare Tunnel URL - $TIMESTAMP"
git push
fi

echo "Tunnel URL: $URL"

wait "$CLOUDFLARED_PID"