@echo off
set size="640x640"
set /p d="Please input the date : "
set convert="C:\imagemagick\convert.exe"
set font="C:\WINDOWS\Fonts\COURBD.TTF"
md tmp
md conv_data
for %%i in (tmp%d%*.ps) do %convert% -density 100x100 %%i conv_data\\%%i.jpg
rmdir /s /q tmp