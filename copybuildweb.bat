@echo off
rmdir "D:\DEV\Flutter\flutter_mqtt\buildweb"
mkdir "D:\DEV\Flutter\flutter_mqtt\buildweb"
xcopy "D:\DEV\Flutter\flutter_mqtt\build\web" "D:\DEV\Flutter\flutter_mqtt\buildweb" /s /e
git add .
git commit -m "update"
git push -u origin main