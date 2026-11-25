@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================================
echo   宿舍维修系统 · 开发启动脚本
echo   当前阶段：项目启动中，功能逐步补齐
echo ------------------------------------------------------------
echo   后端计划  http://localhost:8082/api/v1/health
echo   AI 计划   http://localhost:8001/health
echo   前端计划  学生 5173 / 师傅 5174 / 管理端 5175
echo ------------------------------------------------------------
echo   本脚本启动 AI + 后端两个服务；三个前端待建好后另开终端 npm run dev。
echo   关掉窗口就是停服务。
echo   数据库：计划使用 MySQL 8 的 dorm_repair 库。
echo   开发期可用 APP_STORE=memory 跑内存模式，重启数据清空。
echo ============================================================
echo.

echo [提示] 尚未完成的服务目录会在后续提交中补齐，脚本按计划端口预留。

start "宿舍维修 AI" cmd /k "cd /d %~dp0app\ai && python -m uvicorn app:app --host 127.0.0.1 --port 8001"

timeout /t 3 >nul
start "" http://localhost:8082/api/v1/health

if "%DB_USER%"=="" set DB_USER=root
if "%DB_PASSWORD%"=="" set DB_PASSWORD=123456
cd /d "%~dp0app\server"
if not exist "target\dorm-repair-server-1.0.0.jar" (
  echo 第一次跑，先打包……
  call mvn -q -DskipTests package
)
java -jar target\dorm-repair-server-1.0.0.jar
pause
