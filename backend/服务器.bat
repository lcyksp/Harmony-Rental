@echo off
:: 使用 /d 参数可以同时切换驱动器和目录，更保险
cd /d D:\HarmonyOpenProject\Rental-main\backend

:: 关键修改：使用 call 来调用 npm，这样执行完才会继续往下走
call npm start

:: 暂停，让你能看清窗口
pause
