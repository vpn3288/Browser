@echo off
REM Microsoft Edge ???? - ?????

start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" ^
--lang=zh-CN ^
--accept-lang="zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" ^
--user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0" ^
--disable-blink-features=AutomationControlled ^
--exclude-switches=enable-automation ^
--disable-features=UserAgentClientHints,PrivacySandboxSettings4,FederatedCredentialManagement,AutofillServerCommunication ^
--disable-client-side-phishing-detection ^
--disable-sync ^
--disable-background-networking ^
--disable-default-apps ^
--disable-component-extensions-with-background-pages ^
--disable-breakpad ^
--disable-crash-reporter ^
--metrics-recording-only ^
--no-first-run ^
--no-default-browser-check ^
--no-service-autorun ^
--force-webrtc-ip-handling-policy=disable_non_proxied_udp ^

echo Microsoft Edge ???
echo [????] ????

