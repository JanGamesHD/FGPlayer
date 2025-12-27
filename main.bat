@echo off
color c
echo FGPlayer (Public Beta v.1.20)
echo Please wait. Initializing FGPlayer...
set magicnumber=30
rem Here you can specify the log file location. The default is %userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log
rem You should only change this, if you want to run this script on a different device than you´re running Fall Guys on.
rem For example, you could run this script on a laptop, while playing Fall Guys on your main PC.
rem In that case, you can mount a network drive and change its location here accordingly
set logfile=%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log
rem The new ingame system has unlike the regular ingame system the addition, of setting checkpoints after every action ingame,
rem but with the cost of more I/O to disk. (I thought this would improve performance for some devices, but I coudnt verify that yet.
if not defined usenewingamesystem set usenewingamesystem=0
rem If performclip is defined (to 1), the script will automatically copy the map details to the clipboard on every map.
if not defined performclip set performclip=0
rem The lonely ingame system only checks for time updates, round over, main menu and round over details.
rem Once found, the round is over, the script will perform the actions from the regular ingame system once, to fetch the map details before switching
rem to the Round Over state. This should be used on slower devices. 
if not defined lonelyingamesystem set lonelyingamesystem=0
rem If you want to avoid polling the Fall Guys log without break in the main menu, you can uncomment
rem this option below, where the value contains the time in seconds how often the log file should be checked for matchmaking.
rem set genwaitarearest=1
rem If your device takes too long to fetch the player device information, you can skip this by uncommenting this below.
rem set skipplayernums=1
if %usenewingamesystem%==1 echo WARNING: Test 'usenewingamesystem' active. Please report any bugs found.
setlocal enabledelayedexpansion
if not exist STATS\ goto createstats
:afterstatscreation
set sessiondate=%date:/=%
set sessiondate=%sessiondate:.=%
set sessiondate=%sessiondate:-=%
if exist STATS\lastsession.txt goto verifysession
:aftersessioncheck
echo %sessiondate%>STATS\lastsession.txt
set useragent=FGPlayer/1.20 Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0
echo Done. Please start Fall Guys
echo Report any bugs you encounter to https://github.com/JanGamesHD/FGPlayer/issues
echo Note: If you restart Fall Guys, please restart FGPlayer to reset the log file position.
set skipwaitforfallguyslaunch=0
:wffg
timeout 1 >NUL
rem If you arent running Fall Guys on the host device, you can use this to bypass the "Please start Fall Guys" prompt.
rem Make sure to update the location of the log file at the top of the script!
if %skipwaitforfallguyslaunch%==1 goto fgplayerready
tasklist | find /i "FallGuys"
if not %errorlevel%==0 goto wffg
cls
echo Preparing log file status ...
copy "%logfile%" waitforreadyfile.sys >NUL
cls
echo Fall Guys is now starting.
echo Waiting for the log file to update.
echo If the game is already running, please perform an action ingame to update the log file (open menus).
:wfcilf
timeout 1 >NUL
fc "%logfile%" waitforreadyfile.sys >NUL
if %errorlevel%==0 goto wfcilf
if exist exittimer.sys del exittimer.sys /Q /F >NUL
rem start /min fgtimer.bat
:fgplayerready
cls
echo Preparing Fall Guys log file ...
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
echo Preparing FGPlayer ...
if not exist stats.qualified.sys echo 0 >stats.qualified.sys
if not exist stats.eliminated.sys echo 0 >stats.eliminated.sys
if not exist stats.wins.sys echo 0 >stats.wins.sys
set /p stats.qualified=<stats.qualified.sys
set /p stats.eliminated=<stats.eliminated.sys
set /p wins=<stats.wins.sys
set skipmmcolor=0
cls
goto cur_mainmenu
:secretmm
echo.
:cur_mainmenu
if %skipmmcolor%==0 color 1
set skipmmcolor=0
echo Ready (for matchmaking). LFS: %lines%+ TQ: %stats.qualified% TE: %stats.eliminated%
:aftergotopoint
set disconnectallowed=0	
set linesnomagic=%lines%
set bypassattempt=0
REM echo Your log file currently has %lines%+ lines.
REM echo Total Qualifications: %stats.qualified%
REM echo Total Eliminations: %stats.eliminated%
set usereliminated=0
echo a>quittimer.sys
set blockrewards=0
set completedunimapdetection=0
if exist roundlist.sys del roundlist.sys /Q /F >NUL
:general_waitingarea
if defined genwaitarearest timeout %genwaitarearest% >NUL
if not defined genwaitarearest if %lonelyingamesystem%==1 timeout 1 >NUL
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "​[StateMainMenu] Creating or joining private lobby minimal" TEMP.gen >NUL
if %errorlevel%==0 goto cur_joincustomsmini
find /i "​[StateMainMenu] Creating or joining private lobby" TEMP.gen >NUL
if %errorlevel%==0 goto cur_joincustoms
find /i "​[StateMainMenu] No server address specified, attempting to matchmake" TEMP.gen >NUL
if not %errorlevel%==0 goto general_waitingarea
:cur_connectingmatchmaking
color b
cls
echo ^<00P^> Connecting to matchmaking ...
echo a>quittimer.sys
:cur_waitformatchmakingconnected
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[FNMMSRemoteServiceBase] Disposed" TEMP.gen >matchdisconnect.txt
if %errorlevel%==0 call :leavematchverify
if %disconnectallowed%==1 goto cur_cancelledmatchmaking
find /i "[FNMMSRemoteServiceBase] FNMMS Websocket connection succeeded." TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitformatchmakingconnected
:cur_connectedtomatchmaking
color 1
cls
echo ^<33P^> Joining queue ...
start /min cmd /c timer.bat
:cur_waitforqueueconnect
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[FNMMSRemoteServiceBase] Disposed" TEMP.gen >matchdisconnect.txt
if %errorlevel%==0 call :leavematchverify
if %disconnectallowed%==1 goto cur_cancelledmatchmaking
find /i "Queued" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforqueueconnect
color 3
cls
echo ^<66P^> Joining queue (Waiting for Squad) ...
set matchmakehistory=Connected
set seconds=0
set minutes=0
set lastseconds=1
:cur_queueconnected
find /i  "queuedPlayers" TEMP.gen >tempqueue.temp
For /F "UseBackQ Delims==" %%A In ("%cd%\tempqueue.temp") Do Set queuetemp=%%A
set newqueue=%queuetemp:~21%
if not exist tempnum md tempnum
cd tempnum
md %newqueue%
dir /AD /B >loadgoat.sys
set /p currentmatchplayers=<loadgoat.sys
rd %currentmatchplayers% /Q >NUL
del loadgoat.sys /Q /F >NUL
if not defined currentmatchplayers set currentmatchplayers=null
if not defined lastmatchplayers set lastmatchplayers=yes
set curtime=%time:~0,8%
set curtime=%curtime: =0%
set mm_forremove=0
set /p seconds=<..\seconds.sys
set /a minutes=%seconds%/60
set /a mm_forremove=%minutes%*60
set /a seconds=%seconds%-%mm_forremove%
if %seconds% LSS 10 set seconds=0%seconds%
if %minutes% LSS 10 set minutes=0%minutes%
cd ..
if not %seconds%==%lastseconds% goto cur_mmdisplaytext
if %currentmatchplayers%==%lastmatchplayers% goto cur_playermatchmaking_aftertext
:cur_mmdisplaytext
echo a>startcount.sys
if %bypassattempt%==1 goto cur_playermatchmaking_aftertext
cls
if %currentmatchplayers%==null if %bypassattempt%==0 echo Attempting to connect ...
if not %currentmatchplayers%==null echo Queued. Players waiting for a match: %currentmatchplayers% (%curtime%, %minutes%:%seconds%)
if not %currentmatchplayers%==null if not %currentmatchplayers%==%lastmatchplayers% set "matchmakehistory=%currentmatchplayers% <-- %matchmakehistory%"
if not %currentmatchplayers%==null echo History: !matchmakehistory!
:cur_playermatchmaking_aftertext
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
rem set linesnomagic=%lines%
set /a lines=%lines%-%magicnumber%
set lastmatchplayers=%currentmatchplayers%
set lastseconds=%seconds%
:cur_waitforqueueupdate
rem "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
more /e +%linesnomagic% "%logfile%" >TEMP_nomagic.gen
find /i "[FNMMSRemoteServiceBase] Remote disconnection received. waiting 5s until we close our side" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitingforgameserver
find /i "[HazelNetworkTransport] Creating connection with" TEMP.gen >NUL
if %errorlevel%==0 goto cur_connectinggameserver
find /i "[FNMMSRemoteServiceBase] Disposed" TEMP_nomagic.gen >matchdisconnect.txt
if %errorlevel%==0 call :leavematchverify
if %disconnectallowed%==1 goto cur_cancelledmatchmaking
find /i "Queued" TEMP.gen >NUL
if %errorlevel%==0 goto cur_queueconnected
if %lonelyingamesystem%==1 timeout 1 >NUL
goto cur_waitforqueueupdate
:cur_waitingforgameserver
color b
cls
echo Server starting, please wait ...
:cur_waitforserverdetails
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "with FGClient.StateMainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_resettemp
find /i "] Found game on" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforserverdetails
:cur_connectinggameserver
color 7
cls
echo Connecting ...
echo a>quittimer.sys
:cur_waitforlogin
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "Connection 0 created with" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforlogin
color 1
cls
echo Logging In ... (Waiting for server)
set currentround=0
:cur_waitforloginsuccess
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
find /i "is allowing us to connect as a" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforloginsuccess
color 6
cls
echo Connected ...
find /i "[StateConnectToGame] InitiateNetworkConnectRequest with server IP:" TEMP.gen >"%cd%\extractformip.sys"
For /F "UseBackQ Delims==" %%A In ("%cd%\extractformip.sys") Do Set "foripextract=%%A"
set serverip1=%foripextract:*IP: =%
set serverip2=%serverip1:~0,-5%
set serverip2=%serverip2::=%
REM del server_details.sys /Q /F >NUL
REM curl http://ip-api.com/line/%serverip2%?fields=country,regionName,city --silent >server_details.sys
ping %serverip2% -n 1 >"%cd%\pinganswer.sys"
for /f "tokens=1*delims=:" %%G in ('findstr /n "^" %cd%\pinganswer.sys') do if %%G equ 3 set ping1=%%H
md pingtest
set currentcd=%cd%
cd pingtest
md %ping1% 2>NUL
dir *ms /AD /B >"%currentcd%\ping2server.sys
cd ..
rd pingtest /Q /S
set loadping=0ms
set /p loadping=<ping2server.sys
rem if not %loadping%==0ms echo Ping: %loadping%
REM echo You are connected to %serverip2%.
REM echo Your ping is %loadping%.
REM echo Selected Show: Loading ...
REM echo Server location:
REM type server_details.sys
:cur_waitforshowtofetch
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[HandleSuccessfulLogin] Selected show is " TEMP.gen >"%cd%\4showselector.sys"
if not %errorlevel%==0 goto cur_waitforshowtofetch
:9worksuc
set isexplore=0
set issquad=0
For /F "UseBackQ Delims==" %%A In ("%cd%\4showselector.sys") Do Set "showselected=%%A"
find ": True" 4showselector.sys >NUL
if %errorlevel%==0 set isexplore=1
find "squad" 4showselector.sys >NUL
if %errorlevel%==0 set issquad=1
if %issquad%==0 find "duo" 4showselector.sys >NUL
if %issquad%==0 if %errorlevel%==0 set issquad=1
set selectedshow1=%showselected:*is =%
set selectedshow1=%selectedshow1:IsUltimatePartyEpisode=%
set selectedshow1=%selectedshow1:IsUltimatePartyEpisode=%
set selectedshow1=%selectedshow1:: False=%
set selectedshow1=%selectedshow1:: True=%
rem Default max players for shows not saved.
set maxloadedplayers=32
set selectedshow1=%selectedshow1: =%
echo %selectedshow1%>selectedshow.sys
set showname=
if exist FGPLAYER\SHOWSELECTOR\%selectedshow1%.sys set /p maxloadedplayers=<FGPLAYER\SHOWSELECTOR\%selectedshow1%.sys
if exist FGPLAYER\SHOWSELECTOR\%selectedshow1%.name set /p showname=<FGPLAYER\SHOWSELECTOR\%selectedshow1%.name
if not defined showname set showname=unknown
cls
echo Connected. Show: %selectedshow1% Ping: %loadping%
set maplist=
set bypasscancelmatch=
REM echo You are connected to %serverip2%. Ping: %loadping%.
REM if "%showname%"=="unknown" echo Selected Show: %selectedshow1%
REM if not "%showname%"=="unknown" echo Selected Show: %showname% (%selectedshow1%)
REM echo Max players set to %maxloadedplayers%. Server location:
REM type server_details.sys
set /p lines=<lines.sys
find /i "[CreateLocalPlayerInstances] Added new player as Participant, player ID = " TEMP.gen >playeridout.sys
tail.exe -1 playeridout.sys>playeridout2.sys
set /p tempplayerid=<playeridout2.sys
set myplayerid=%tempplayerid:~88%
cls
echo Connected. Show: %selectedshow1% Ping: %loadping% Player ID: %myplayerid% SQ: %issquad%
rem echo Player ID: %myplayerid% SQ: %issquad%
:cur_waitformaploadstart
if %lonelyingamesystem%==1 timeout 1 >NUL
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "​[Hazel] [HazelNetworkTransport] Disconnect request received for connection 0" TEMP.gen >NUL
if %errorlevel%==0 goto serverdisconnectedyou
find /i "with FGClient.StateMainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto serverdisconnectedyou
find /i "​[RoundLoader] Loading finished" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitformaptoappear
find /i "GameMessageServerStartLoadingLevel received" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitformaploadstart
:cur_waitformaptoappear
cls
echo Waiting for Map ...
set completedunimapdetection=0
set completedcreativelevel=0
:cur_waitforanimationtofinish
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "Requesting spawn of local player" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitformaploadtocomplete
find /i "[StateGameLoading] ShowLoadingGameScreenAndLoadLevel" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforanimationtofinish
color c
cls
echo Loading map ...
if exist private\fmedia.bat taskkill /F /IM fmedia.exe >NUL
:cur_waitformaploadtocomplete
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
if %completedunimapdetection%==1 goto cur_onlywaitformapload
find /i "​[RoundLoader] Game level to load:" TEMP.gen >loadearlymapname.txt
if %errorlevel%==0 goto cur_loadearlymapname
if %completedcreativelevel%==1 goto cur_onlywaitformapload
find /i "[RoundLoader] Load UGC via share code" TEMP.gen >creativesharecode.txt
if %errorlevel%==0 goto cur_creativeleveldetected
:cur_onlywaitformapload
find /i "[RoundLoader] Loading finished with state Cancelled" TEMP.gen >NUL
if %errorlevel%==0 goto failedtoloadlevel
find /i "[ClientGameManager] GameLevelLoaded" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitformaploadtocomplete
cls
echo Map loaded. Loading map details ...
color e
if exist private\fmedia.bat taskkill /F /IM fmedia.exe >NUL
type nul>quittimer.sys
find /i "[StateGameLoading] Finished loading game level, assumed to be" TEMP.gen >mapresults1.sys
For /F "UseBackQ Delims==" %%A In ("%cd%\mapresults1.sys") Do Set lastlinemap=%%A
set lastlinemap2=%lastlinemap:~76%
set lastlinemap3=%lastlinemap2:.=%
set lastlinemap4=%lastlinemap3: Duration:=%
set lastlinemap5=%lastlinemap4:,=.%
rem if "%lastlinemap5%"==".=" goto trytofixmapdetection
md MapLookupV2
cd MapLookupV2
md %lastlinemap5%
dir /B>..\loaderoutput.txt
set /p loadtime=<..\loaderoutput.txt
rd %loadtime% /Q
dir /B>..\loaderoutputmap.txt
set /p rawmap=<..\loaderoutputmap.txt
cd ..
rd MapLookupV2 /Q /S
if %completedunimapdetection%==1 goto skipunisearch
find /i "​[RoundLoader] LoadGameLevelSceneASync COMPLETE for scene " TEMP.gen >mapresults2.sys
For /F "UseBackQ Delims==" %%A In ("%cd%\mapresults2.sys") Do Set lastlinemapuni=%%A
set mapworker=%lastlinemapuni:~72%
set mapworker25=%mapworker:e =%
set mapworker2=%mapworker25: on frame=%
md MapLookupV2
cd MapLookupV2
md %mapworker2%
dir fram* /B>..\loaderoutput2.txt
set /p framedata=<..\loaderoutput2.txt
rd %framedata% /Q
dir /B>..\loaderoutputmap2.txt
set /p unimap=<..\loaderoutputmap2.txt
cd ..
rd MapLookupV2 /Q /S
set theunimap=%unimap%
:skipunisearch
set maploadtime=%loadtime%
set themap=%rawmap%
set creativemap=0
if %theunimap%==FallGuy_FraggleBackground_Retro set creativemap=1
if %theunimap%==FallGuy_FraggleBackground_Vanilla set creativemap=2
if %creativemap%==1 if exist MAPS\currentcreativevanilla.sys del MAPS\currentcreativevanilla.sys /Q /F
if %creativemap%==2 if exist MAPS\currentcreative.sys del MAPS\currentcreative.sys /Q /F
if %creativemap%==1 echo %themap%>MAPS\currentcreative.sys
if %creativemap%==2 echo %themap%>MAPS\currentcreativevanilla.sys
rem if %creativemap%==1 if exist MAPS\%themap%.map set /p mapname=<MAPS\%themap%.map
rem if %creativemap%==2 if exist MAPS\%themap%.mapvanilla set /p mapname=<MAPS\%themap%.mapvanilla
rem if %creativemap%==1 if not exist MAPS\%themap%.map goto loadanyway
rem if %creativemap%==2 if not exist MAPS\%themap%.mapvanilla goto loadanyway
if %creativemap%==1 goto cur_afterclassicmap
if %creativemap%==2 goto cur_afterclassicmap
rem we are skipping classic map, since its a creative map, and we dont need to load the classic map name.
set diddosharecode=0
set didmaptest=1
rem if %creativemap%==0 echo Not a creative level.
:loadanyway
echo %unimap%>MAPS\currentmap.sys
if %completedunimapdetection%==1 goto cur_afterclassicmap
rem echo Loading map name...
set mapname=
set curloadedplayers=0
if not exist MAPS\%unimap%.map goto endingnewmap
set /p mapname=<MAPS\%unimap%.map
:cur_afterclassicmap
color e
if %performclip%==1 echo %mapname% (%theunimap%) - %themap% | clip
:endingnewmap
set completedunimapdetection=0
if not defined mapname set mapname=%theunimap:FallGuy_=%
set remain=0
set /a remain=%maxloadedplayers%-%curloadedplayers%
if %usereliminated%==1 goto skip_usereliminated
set /a curloadedplayers2=%curloadedplayers%-1
set /a remain2=%remain%+1
:skip_usereliminated
if %usereliminated%==1 set /a remain2=%remain%+2
if %usereliminated%==1 set /a curloadedplayers2=%curloadedplayers%-2
if %remain2% LEQ 0 goto cur_maploadonlyplayers
cls
echo Players: %curloadedplayers2%/%maxloadedplayers% - Remain: %remain2% - Map: !mapname! (%maploadtime%)
REM echo Map: %mapname% (%theunimap:FallGuy_=%) - %themap%
REM echo Players: %curloadedplayers2%/%maxloadedplayers%
REM echo Remain: %remain2%
:cur_waitforplayerupdate
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
set lastloadedplayers=%curloadedplayers%
find /i "[ClientGameManager] Handling bootstrap for remote player" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set curloadedplayers=%%b
if not %curloadedplayers%==%lastloadedplayers% goto endingnewmap
find /i "[CameraDirector].UseIntroCameras, current camera target type is Close" TEMP.gen >NUL
if %errorlevel%==0 goto waitlastfewplayers
find /i "[StateGameLoading].OnIntroCamerasComplete, spawning players post intro camera" TEMP.gen >NUL
if %errorlevel%==0 goto showintro
find /i "[ClientGameManager] Setting this client as readiness state 'ObjectsSpawned'." TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforplayerupdate
:waitlastfewplayers
color 6
cls
echo Waiting for players ...
:cur_waitforserverintro
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[GameSession] Changing state from Precountdown to Countdown" TEMP.gen >NUL
if %errorlevel%==0 goto showintro
find /i "[CameraDirector].UseIntroCameras, current camera target type is Close" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforserverintro
goto showintro
cls
echo Waiting for server...
:cur_waitforservertostartintro
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[StateGameLoading].OnIntroCamerasComplete, spawning players post intro camera" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforservertostartintro
:showintro
color b
set /a curloadedplayers=%curloadedplayers%-1
cls
echo Map: !mapname! - Players: %curloadedplayers%
REM echo Showing the map ...
REM echo Map: %mapname%
REM echo Players: %curloadedplayers%
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
set pcplayers=0
set pcegplayers=0
set ps4players=0
set ps5players=0
set xboxplayers=0
set switchplayers=0
set xboxoneplayers=0
set iosplayers=0
set androidplayers=0
set botplayers=0
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
if defined skipplayernums goto cur_afterplayerlistings
rem PC STEAM
find /i "[CameraDirector] Adding Spectator target ... (pc_steam)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set pcplayers=%%b
rem echo PC PLAYERS EPIC
find /i "[CameraDirector] Adding Spectator target ... (pc_egs)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set pcegplayers=%%b
rem echo PS4 PLAYERS
find /i "[CameraDirector] Adding Spectator target ... (ps4)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set ps4players=%%b
rem echo PS5 PLAYERS
find /i "[CameraDirector] Adding Spectator target ... (ps5)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set ps5players=%%b
rem echo XBOX PLAYERS
find /i "[CameraDirector] Adding Spectator target ... (xsx)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set xboxplayers=%%b
rem echo SWITCH PLAYERS
find /i "[CameraDirector] Adding Spectator target ... (switch)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set switchplayers=%%b
rem echo XBOX ONE PLAYERS
find /i "[CameraDirector] Adding Spectator target ... (xb1)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set xboxoneplayers=%%b
rem echo MOBILE IOS
find /i "[CameraDirector] Adding Spectator target ... (ios_ega)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set iosplayers=%%b
rem echo MOBILE ANDROID
find /i "[CameraDirector] Adding Spectator target ... (android_ega)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set androidplayers=%%b
rem echo BOTS
find /i "[CameraDirector] Adding Spectator target ... (bots)" TEMP.gen >playerlistfile.log
for /f "usebackq" %%b in (`type playerlistfile.log ^| find "" /v /c`) do set botplayers=%%b
if not %pcegplayers% LEQ 0 set /a pcegplayers=%pcegplayers%-2
if not %pcplayers% LEQ 0 set /a pcplayers=%pcplayers%-2
if not %ps4players% LEQ 0 set /a ps4players=%ps4players%-2
if not %ps5players% LEQ 0 set /a ps5players=%ps5players%-2
if not %xboxplayers% LEQ 0 set /a xboxplayers=%xboxplayers%-2
if not %switchplayers% LEQ 0 set /a switchplayers=%switchplayers%-2
if not %xboxoneplayers% LEQ 0 set /a xboxoneplayers=%xboxoneplayers%-2
if not %iosplayers% LEQ 0 set /a iosplayers=%iosplayers%-2
if not %androidplayers% LEQ 0 set /a androidplayers=%androidplayers%-2
if not %botplayers% LEQ 0 set /a botplayers=%botplayers%-2
set playerlistings=
if %pcplayers% GTR 0 set playerlistings=%playerlistings% PC-Steam: %pcplayers%
if %pcegplayers% GTR 0 set playerlistings=%playerlistings% PC-Epic: %pcegplayers%
if %botplayers% GTR 0 set playerlistings=%playerlistings% BOTS: %botplayers%
if %ps4players% GTR 0 set playerlistings=%playerlistings% PS4: %ps4players%
if %ps5players% GTR 0 set playerlistings=%playerlistings% PS5: %ps5players%
if %xboxplayers% GTR 0 set playerlistings=%playerlistings% XBOX X/S: %xboxplayers%
if %xboxoneplayers% GTR 0 set playerlistings=%playerlistings% XBOX ONE: %xboxoneplayers%
if %switchplayers% GTR 0 set playerlistings=%playerlistings% SWITCH: %switchplayers%
if %iosplayers% GTR 0 set playerlistings=%playerlistings% iOS: %iosplayers%
if %androidplayers% GTR 0 set playerlistings=%playerlistings% ADR: %androidplayers%
if not defined playerlistings set playerlistings=Loading...
rem echo %playerlistings%
set totalplayers=0
set /a totalplayers=%pcplayers%+%pcegplayers%+%ps4players%+%ps5players%+%xboxplayers%+%xboxoneplayers%+%switchplayers%+%iosplayers%+%androidplayers%+%botplayers%
if not %totalplayers%==%curloadedplayers% cls
if not %totalplayers%==%curloadedplayers% echo Map: !mapname! Players: %curloadedplayers%
REM if not %totalplayers%==%curloadedplayers% echo Showing the map ...
REM if not %totalplayers%==%curloadedplayers% echo Map: %mapname%
REM if not %totalplayers%==%curloadedplayers% echo Players: %totalplayers%
:cur_afterplayerlistings
if defined skipplayernums set totalplayers=%curloadedplayers%
if not %totalplayers%==%curloadedplayers% set curloadedplayers=%totalplayers%
if not defined skipplayernums echo %playerlistings:~1%
if not %issquad%==0 goto cur_waitforcountdown
if not %currentround%==0 goto cur_waitforcountdown
find "Squad ID: 1" TEMP.gen >NUL
set error=%errorlevel%
if %error%==0 echo Squads detected and enabled.
if %error%==0 set issquad=1
:cur_waitforcountdown
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[StateMainMenu] Loading scene MainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_checkaddelimmainmenu
find /i "[GameSession] Changing state from Precountdown to Countdown" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforcountdown
color 5
cls
echo Waiting ...
set /a currentround=%currentround%+1
REM echo R%currentround%: %mapname%
REM echo Players: %curloadedplayers%
rem findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys # removed on 28.10.2025 R.I.P Nala :(
:cur_waitforcountdown2
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[GameSession] Changing state from Precountdown to Countdown" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforcountdown2
color c
set /p lines=<lines.sys 
cls
REM echo 3... 2... 1...
rem set /a currentround=%currentround%+1
echo 3... 2... 1... R%currentround%: !mapname! Players: %curloadedplayers%
REM echo Players: %curloadedplayers%
if not defined skipplayernums echo %playerlistings:~1%
start /min timer.bat
if not defined showcounter set showcounter=0

:cur_waitforgamestart
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[GameSession] Changing state from Countdown to Playing" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforgamestart
color e
cls
echo Loading ...
type nul>startcount.sys
set seconds=0
set lastseconds=0
set qualified=0
set qualifiedseconds=0
set playersqualified=0
set lastplayersqualified=0
set playerseliminated=0
set lastplayerseliminated=0
set /p lines=<lines.sys
rem Initial Starting zone
if %usenewingamesystem%==1 goto newingame
if %lonelyingamesystem%==1 goto lonelyingame
call :cur_gamerunning
goto cur_ingame
:cur_gamerunning
if %qualified%==0 set text=TIME: %seconds%
if %qualified%==1 set text=TIME: %seconds% Q: %qualifiedseconds%
set text=%text% R%currentround%: !mapname!
if %playersqualified% GTR 0 set text=%text% - Qualified: %playersqualified%
if %playerseliminated% GTR 0 set text=%text% - Eliminated: %playerseliminated%
if %usereliminated%==1 set text=%text% (Eliminated)
cls
echo %text%
goto :EOF
:cur_ingame
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
if %qualified%==1 goto cur_afterqualifiedcheck
find /i "ClientGameManager::HandleServerPlayerProgress PlayerId=%myplayerid% is succeeded=True" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_afterqualifiedcheck
set qualified=1
set qualifiedseconds=%seconds%
if %blockrewards%==1 call :cur_gamerunning
set /a stats.qualified=%stats.qualified%+1
echo %stats.qualified% >stats.qualified.sys
start /min cmd /c stats_addqualify.bat
call :cur_gamerunning
:cur_afterqualifiedcheck
find /i "[ClientGameSession] NumPlayersAchievingObjective=" TEMP.gen>qualifynumbers.sys
if not %errorlevel%==0 goto cur_aftercheckingqualificationnumbers
tail -1 "%cd%\qualifynumbers.sys">"%cd%\qualifynumbers2.sys"
set /p lastqualify=<"%cd%\qualifynumbers2.sys"
set almostqualifynumber=%lastqualify:*ve=ve%
set playersqualified=%almostqualifynumber:~3%
if %lastplayersqualified%==%playersqualified% goto cur_aftercheckingqualificationnumbers
set lastplayersqualified=%playersqualified%
call :cur_gamerunning
:cur_aftercheckingqualificationnumbers
rem more /e +%lines% "%cd%\TEMP1.log" >"%cd%"\specialtemp.sys
find /i "is succeeded=False" TEMP.gen >elimplayers.sys
if not %errorlevel%==0 goto cur_aftercheckingeliminationnumbers
for /f "usebackq" %%b in (`type elimplayers.sys ^| find "" /v /c`) do set elimnumber=%%b
set /a elimnumber=%elimnumber%-2
if %elimnumber% GTR 0 set playerseliminated=%elimnumber%
if %usereliminated%==1 goto afteringameelimcheck
find /i "Qualified: False" TEMP.gen>NUL
if not %errorlevel%==0 goto afteringameelimcheck
set usereliminated=1
if %blockrewards%==1 goto afteringameelimcheck
set /a stats.eliminated=%stats.eliminated%+1
echo %stats.eliminated% >stats.eliminated.sys
start /min cmd /c stats_addelimination.bat
:afteringameelimcheck
if %playerseliminated%==%lastplayerseliminated% goto cur_aftercheckingeliminationnumbers
set lastplayerseliminated=%playerseliminated%
call :cur_gamerunning
:cur_aftercheckingeliminationnumbers
set newseconds=
set /p newseconds=<seconds.sys
if not defined newseconds set newseconds=%seconds%
if %newseconds%==%seconds% goto cur_aftercheckingseconds
set seconds=%newseconds%
set lastseconds=%seconds%
call :cur_gamerunning
:cur_aftercheckingseconds
:aftercheckingseconds
find /i "[StateMainMenu] Loading scene MainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_checkaddelimmainmenu
if not %isexplore%==1 goto afterexplorecheck
find /i "[GameplaySpectatorUltimatePartyFlowViewModel] Matchmaking begins!" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
find /i "[MatchmakeWhileInGameHandler] Begin matchmaking..." TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
:afterexplorecheck
find /i "[GameSession] Changing state from Playing to GameOver" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_ingame
if not %playersqualified%==0 goto skipsurvivalmaptest
find /C "is succeeded=True" TEMP.gen | find "-" >abuild.txt
set /p inl=<abuild.txt
set playersqualified=%inl:~-2%
set playersqualified=%playersqualified: =%
:skipsurvivalmaptest
color c
cls
echo Round %currentround% Over! Took: %seconds: =%s - Map: !mapname!
find /i "is succeeded=True" TEMP.gen >successlist.txt
more /e +2 successlist.txt >successlist2.txt
findstr /R /N "^" "successlist2.txt" | find /C ":" >qualplayers.txt
set /p playersqualified=<qualplayers.txt
cls
echo Round %currentround% Over! Took: %seconds: =%s - Map: !mapname! - Qualified: %playersqualified%
echo R%currentround%: !mapname! (%maxloadedplayers% --^> %playersqualified%) >>roundlist.sys
set "elimaction=(%maxloadedplayers% --> %playersqualified%)"
set "elimaction2=(--> %playersqualified%)"
if %currentround%==1 (
	set "roundhistory=R%currentround%: !mapname! !elimaction!"
	)

if %currentround% GTR 1 (
	set "roundhistory=!roundhistory! R%currentround%: !mapname! !elimaction2!"
	)

rem set roundhistory=%roundhistory%
REM if defined maplist set maplist=%maplist% R%currentround%: %mapname% (%maxloadedplayers% --^> %playersqualified%)
REM if not defined maplist set maplist=R%currentround%: %mapname% (%maxloadedplayers% --^> %playersqualified%)
set maxloadedplayers=%playersqualified%
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
type nul>quittimer.sys
:cur_waitfortotalrounddisplay
if %lonelyingamesystem%==1 timeout 1 >NUL
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" "%cd%"\TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
if %usereliminated%==1 goto cur_afterrounddisplaycheck
find /i "Qualified: False" TEMP.gen>NUL
if not %errorlevel%==0 goto cur_afterrounddisplaycheck
set usereliminated=1
if %blockrewards%==1 goto cur_afterroundoverelimwrite
set /a stats.eliminated=%stats.eliminated%+1
echo %stats.eliminated% >stats.eliminated.sys
start /min cmd /c stats_addelimination.bat
:cur_afterroundoverelimwrite
echo You have been eliminated. (Just now)
:cur_afterrounddisplaycheck
find /i "[StateMainMenu] Loading scene MainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_checkaddelimmainmenu
find /i "[GameStateMachine] Replacing FGClient.StateGameInProgress with FGClient.StateVictoryScreen" TEMP.gen>NUL
if %errorlevel%==0 goto showend
if not %isexplore%==1 goto afterexplorecheck2
find /i "[GameplaySpectatorUltimatePartyFlowViewModel] Matchmaking begins!" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
find /i "[MatchmakeWhileInGameHandler] Begin matchmaking..." TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
:afterexplorecheck2
set /p lines=<lines.sys
find /i "[StateQualificationScreen] Reloading for next round" TEMP.gen>NUL
if not %errorlevel%==0 goto cur_waitfortotalrounddisplay
color 5
cls
REM echo Mhh. Which round will come next?
rem type roundlist.sys
echo !roundhistory!
REM echo %maplist%
goto cur_waitformaploadstart

:showend
cls
echo Victory screen
set skipmmclolor=1
if %usereliminated%==1 goto lostshow2
if %blockrewards%==1 goto showend_blockrewards
goto cur_waitforrewards_decision
if %qualified%==1 goto cur_afterwoncheck
if %usereliminated%==1 goto lostshow2
goto cur_waitforrewards_decision
find /i "ClientGameManager::HandleServerPlayerProgress PlayerId=%myplayerid% is succeeded=True" TEMP.gen >NUL
if not %errorlevel%==0 goto lostshow
:cur_afterwoncheck
cls
color 6
set /a wins=%wins%+1
echo %wins% >stats.wins.sys
echo You have %wins% Wins in Fall Guys.
echo !roundhistory!
echo Qualified in Final Round: %playersqualified%
goto secretmm

:lostshow
if %issquad%==1 goto cur_waitforrewards_decision
:afterdecision
color 5
cls
set /a stats.eliminated=%stats.eliminated%+1
echo %stats.eliminated% >stats.eliminated.sys
:lostshow2
cls
echo You lost.
echo !roundhistory!
echo Qualified in Final Round: %playersqualified%
goto secretmm

:cur_clsmainmenu
cls
goto cur_mainmenu

:cur_waitforexplorematchmaking
cls
echo a>quittimer.sys
echo Waiting for matchmaking ...
set bypasscancelmatch=1
goto cur_connectingmatchmaking

:showresultsmsg
echo !roundhistory!
echo Qualified in Final Round: %playersqualified%
goto :EOF
:cur_maploadonlyplayers
cls
echo Players: %curloadedplayers2% - Map: !mapname! (%maploadtime%).
REM echo Map loaded in %maploadtime%. Waiting for players.
REM echo Map: %mapname% (%theunimap:FallGuy_=%) - %themap%
REM echo Players: %curloadedplayers2%
goto cur_waitforplayerupdate

:cur_waitforrewards_decision
cls
echo Victory Screen
echo Waiting for rewards ...
set /a lines=%lines%-200
:loop_waitforrewards_decision
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[StateMainMenu] Loading scene MainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_clsmainmenu
REM find /i "[PlayerStats] [UpdateCache] Player stats updated" TEMP.gen >NUL
REM if %errorlevel%==0 goto cur_processingrewards
REM find /i "[RewardService] Processing claimed rewards" TEMP.gen >NUL
REM if not %errorlevel%==0 goto loop_waitforrewards_decision
find /i "BadgeId: " TEMP.gen >NUL
if not %errorlevel%==0 goto loop_waitforrewards_decision
:cur_processingrewards
cls
echo Victory Screen
echo Processing rewards ...
find "Qualified: False" TEMP.gen >NUL
if %errorlevel%==0 goto afterdecision
goto cur_afterwoncheck

:cur_joincustomsmini
cls
set blockrewards=1
echo NOTE: This is a discovery level. Rewards are disabled.
echo.
echo Connecting to matchmaking ...
goto cur_waitformatchmakingconnected

:cur_joincustoms
cls
set blockrewards=1
echo Connected to Custom Show.
echo NOTE: This is a custom show. Rewards are disabled.
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
echo.
echo Waiting for the host to start ...
:cur_waitforcustomstart
rem copy "%userprofile%\AppData\LocalLow\Mediatonic\FallGuys_client\Player.log" TEMP1.log >NUL
more /e +%lines% "%logfile%" >TEMP.gen
find /i "[PartyStateManager] Attempting to create core party after returning to main menu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_resettemp
find /i "[GameStateMachine] Replacing FGClient.StatePrivateLobby with FGClient.StateConnectToGame" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_waitforcustomstart
goto cur_connectinggameserver

:showend_blockrewards
echo Rewards are disabled for Custom Shows.
echo No changes have been made to your stats.
goto cur_mainmenu

:leavematchverify
if not exist pastmatchdisconnect.txt goto disconnectcorrect
fc pastmatchdisconnect.txt matchdisconnect.txt >NUL
if %errorlevel%==0 goto dontdisconnect
if defined bypasscancelmatch goto dontdisconnect
:disconnectcorrect
copy matchdisconnect.txt pastmatchdisconnect.txt >nul
set disconnectallowed=1
goto :EOF

:dontdisconnect
set disconnectallowed=0
goto :EOF
:cur_cancelledmatchmaking
echo FGPlayer Log File Manager
echo.
echo Please wait, resetting log file ...
echo a>quittimer.sys
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
set disconnectallowed=0
cls
echo Matchmaking cancelled. Disconnected from matchmaking.
cls && goto cur_mainmenu

:cur_resettemp
cls
echo FGPlayer Log File Manager
echo.
echo Please wait, resetting log file ...
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
cls
goto cur_mainmenu

:cur_loadearlymapname
rem loadearlymapname.txt
tail -1 loadearlymapname.txt >earlymapname.txt
set /p earlymapname=<earlymapname.txt
set earlymapname=%earlymapname:~49%
if exist earlymapname\ rd earlymapname /Q /S
md earlymapname
cd earlymapname
md %earlymapname% 2>NUL
dir FallGuy_* /OD /B >correctmap.txt
set /p theunimap=<correctmap.txt
cd ..
set completedunimapdetection=1
set unimap=%theunimap%
if not exist MAPS\%unimap%.map set mapname=%unimap:FallGuy_=%
set /p mapname=<MAPS\%unimap%.map
cls
echo Loading Map !mapname! (%theunimap%) ...
if %performclip%==1 echo %mapname% (%theunimap%) | clip
goto cur_onlywaitformapload

:serverdisconnectedyou
cls
set skipmmcolor=1
color c
echo Disconnected from game server. Checking status ...
find "[ClientGlobalGameState] sending graceful disconnect message" TEMP.gen >NUL
if %errorlevel%==0 goto disconnect_notserverfault
cls
echo You have been disconnected by the server!
echo For some reason, the server closed your connection. Thats all we know.
:cur_recalclinesafterdisconnect
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
goto cur_mainmenu

:disconnect_notserverfault
cls
echo Player requested disconnection. Returning to main menu.
goto cur_recalclinesafterdisconnect

rem [GameStateMachine] Replacing FGClient.StateMatchmaking with FGClient.StateDisconnectingFromServer
:createstats
echo Creating stats ...
echo This shoudnt take long.
md STATS
md STATS\ALLTIME
md STATS\SESSION
md STATS\PASTSESSIONS
rem Important: No crossover of stats are ever allowed.
rem SESSION stats start when FGPlayer starts. FGPlayer records the current date and uses it to identify the current session.
rem This means that if you restart Fall Guys and FGPlayer, if its still the same date as before, the same session will be used.
rem Old sessions will be moved into STATS\PASTSESSIONS, and the FGStatsView.bat can be used to view stats based on those past sessions.
goto afterstatscreation

:failedtoloadlevel
cls
echo Failed to load level.
color c
findstr /R /N "^" "%logfile%" | find /C ":" >lines.sys
set /p lines=<lines.sys
set skipmmcolor=1
goto cur_mainmenu

:verifysession
set /p lastsession=<STATS\lastsession.txt
if %sessiondate%==%lastsession% goto aftersessioncheck
ren STATS\SESSION %lastsession%
move STATS\%lastsession% STATS\PASTSESSIONS\
md STATS\SESSION
goto aftersessioncheck

:cur_creativeleveldetected
rem @echo on
more /e +2 creativesharecode.txt >onlysharecode.txt
rem set /p sharecode=<onlysharecode.txt
REM for /f "tokens=*" %%A in ('findstr /C:"Load UGC via share code:" onlysharecode.txt') do (
    REM set "sharecode=%%A"
REM )
for /f "tokens=*" %%A in ('findstr /R "[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]:[0-9][0-9]" onlysharecode.txt') do (
    set "sharecode=%%A"
)
set "sharecode=%sharecode:*share code: =%"
rem Thanks Copilot for helping me with this. I no longer like weird characters in UTF-8 BOM ...
rem set sharecode=%sharecode:~56%
set sharecode=%sharecode::= ZDEL%
md GetCreative
cd GetCreative
md %sharecode%
dir /ON /B >onlysharecode.txt
set /p sharecode=<onlysharecode.txt
cd ..
rd GetCreative /Q /S
if exist MAPS\CREATIVE-%sharecode%.txt goto cur_loadsharecache
cls
echo Looking up level: %sharecode% ...
echo ^[----------^] 00
set lvlcode=%sharecode%
if defined dontperformlvllookup set mapname=%sharecode% && goto cur_displaycreativelevel
curl -q -A "%useragent%" https://api2.fallguysdb.info/api/creative/%lvlcode%.json>levelcodedown.txt
cls
echo Extracting level ...
echo ^[#####-----^] 50
powershell -Command "& {Get-Content levelcodedown.txt | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Out-File getlevelcode.txt}"
REM del getlevelcode.txt /q /f >NUL
REM start /min cmd /c DecodeLevel.bat
REM rem pause
REM :cur_waitforlevelextracted
REM if not exist getlevelcode.txt goto cur_waitforlevelextracted
find "title" getlevelcode.txt >outlevelcode.txt
if not %errorlevel%==0 goto cur_getcodefailed
more /e +3 outlevelcode.txt >outlevelcode2.txt
set /p levelname=<outlevelcode2.txt
set mapname=!levelname:~42,-2!
set completedcreativelevel=1
echo !mapname!>MAPS\CREATIVE-%sharecode%.txt
goto cur_displaycreativelevel

:cur_loadsharecache
set /p mapname=<MAPS\CREATIVE-%sharecode%.txt
set completedcreativelevel=1
goto cur_displaycreativelevel

:cur_getcodefailed
set mapname=%sharecode%
set completedcreativelevel=1
:cur_displaycreativelevel
set mapname=!mapname:\u0027='!
cls
echo Loading map !mapname! (%sharecode%) ...
goto cur_onlywaitformapload

:newingame
REM set byownqualcheck=0
REM set byglobqualcheck=0
REM set byglobelimcheck=0
REM set byglobtimercheck=0
set ingameline=0
set skipitelim=0
type nul>empty.sys
echo debug:
echo lines: %lines%
echo ingameline: %ingameline%
rem insert call command here
call :cur_gamerunning2
goto cur_returnnewingame
:cur_gamerunning2
if %qualified%==0 set text=TIME: %seconds%
if %qualified%==1 set text=TIME: %seconds% Q: %qualifiedseconds%
set text=%text% R%currentround%: !mapname!
if %playersqualified% GTR 0 set text=%text% - Qualified: %playersqualified%
if %playerseliminated% GTR 0 set text=%text% - Eliminated: %playerseliminated%
if %usereliminated%==1 set text=%text% (Eliminated)
rem if %usereliminated%==1 echo eliminated
cls
echo %text%
rem echo ownqual: %byownqualcheck%, globqual: %byglobqualcheck%, globelim: %byglobelimcheck%, timer: %byglobtimercheck%
goto :EOF
:cur_newingametimecheck
set newseconds=
set /p newseconds=<seconds.sys
if not defined newseconds set newseconds=%seconds%
if %newseconds%==%seconds% goto cur_letitupdategen
set seconds=%newseconds%
set lastseconds=%seconds%
call :cur_gamerunning2
rem Hier muss noch ein Display generator sein, das die Ingame Stats anzeigt. Nach dem letzten Ingame-Befehlsblock, muss der ingameline wert aktualisiert werden.
:cur_returnnewingame
:cur_ingame2
findstr /R /N "^" "TEMP.gen" | find /C ":" >ingameline.sys
:cur_letitupdategen
more /e +%lines% "%logfile%" >TEMP.gen
set /p ingameline=<ingameline.sys
more /e +%ingameline% TEMP.gen >InGame.gen
fc InGame.gen empty.sys >NUL
if %errorlevel%==0 goto cur_newingametimecheck
rem New lines for processing found, so we´re processing those lines now!
if %qualified%==1 goto cur_afterqualifiedcheck2
find /i "ClientGameManager::HandleServerPlayerProgress PlayerId=%myplayerid% is succeeded=True" InGame.gen >NUL
if not %errorlevel%==0 goto cur_afterqualifiedcheck2
set qualified=1
set qualifiedseconds=%seconds%
REM set /a byownqualcheck=%byownqualcheck%+1
if %blockrewards%==1 call :cur_gamerunning2
set /a stats.qualified=%stats.qualified%+1
echo %stats.qualified% >stats.qualified.sys
start /min cmd /c stats_addqualify.bat
call :cur_gamerunning2
:cur_afterqualifiedcheck2
find /i "[ClientGameSession] NumPlayersAchievingObjective=" InGame.gen>qualifynumbers.sys
if not %errorlevel%==0 goto cur_aftercheckingqualificationnumbers2
tail -1 "%cd%\qualifynumbers.sys">"%cd%\qualifynumbers2.sys"
set /p lastqualify=<"%cd%\qualifynumbers2.sys"
set almostqualifynumber=%lastqualify:*ve=ve%
set playersqualified2=%almostqualifynumber:~3%
if %playersqualified2%==%lastplayersqualified% goto cur_aftercheckingqualificationnumbers2
set playersqualified=%playersqualified2%
set lastplayersqualified=%playersqualified%
rem set /a byglobqualcheck=%byglobqualcheck%+1
call :cur_gamerunning2
:cur_aftercheckingqualificationnumbers2
find /i "is succeeded=False" InGame.gen >elimplayers.sys
if not %errorlevel%==0 goto cur_aftercheckingeliminationnumbers233
for /f "usebackq" %%b in (`type elimplayers.sys ^| find "" /v /c`) do set elimnumber=%%b
set /a elimnumber=%elimnumber%-2
if %elimnumber% GTR 0 set playerseliminated2=%elimnumber%
:cur_aftercheckingeliminationnumbers23
if %usereliminated%==1 goto afteringameelimcheck2
find /i "Qualified: False" InGame.gen>NUL
if not %errorlevel%==0 goto afteringameelimcheck2
set usereliminated=1
if %blockrewards%==1 goto afteringameelimcheck2
set /a stats.eliminated=%stats.eliminated%+1
echo %stats.eliminated% >stats.eliminated.sys
start /min cmd /c stats_addelimination.bat
:afteringameelimcheck2
if %skipitelim%==1 goto cur_aftercheckingeliminationnumbers2
if %playerseliminated2%==0 goto cur_aftercheckingeliminationnumbers2
set /a playerseliminated=%playerseliminated%+%playerseliminated2%
rem set /a byglobelimcheck=%byglobelimcheck%+1
call :cur_gamerunning2
:cur_aftercheckingeliminationnumbers2
set skipitelim=0
rem Hier täten die Sekunden her kommen, aber wir werden die Sekunden nur MIST, nvm,
rem wir werden die Sekunden doppelt checken, falls es immernoch zu langsamerer PCs gibt ...
set newseconds=
set /p newseconds=<seconds.sys
if not defined newseconds set newseconds=%seconds%
if %newseconds%==%seconds% goto cur_aftercheckingseconds2
set seconds=%newseconds%
set lastseconds=%seconds%
rem set /a byglobtimercheck=%byglobtimercheck%+1
call :cur_gamerunning2
:cur_aftercheckingseconds2
:aftercheckingseconds2
find /i "[StateMainMenu] Loading scene MainMenu" InGame.gen >NUL
if %errorlevel%==0 goto cur_checkaddelimmainmenu
if not %isexplore%==1 goto afterexplorecheck2
find /i "[GameplaySpectatorUltimatePartyFlowViewModel] Matchmaking begins!" InGame.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
find /i "[MatchmakeWhileInGameHandler] Begin matchmaking..." InGame.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
rem Ich meine hier müssen wir keine 2te version vom goto machen
:afterexplorecheck2
find /i "[GameSession] Changing state from Playing to GameOver" InGame.gen >NUL
if not %errorlevel%==0 goto cur_ingame2
if not %playersqualified%==0 goto skipsurvivalmaptest2
find /C "is succeeded=True" TEMP.gen | find "-" >abuild.txt
rem Hier muss man TEMP.gen nehmen ...
set /p inl=<abuild.txt
set playersqualified=%inl:~-2%
set playersqualified=%playersqualified: =%
:skipsurvivalmaptest2
rem Hier ist die Runde beendet.
goto skipsurvivalmaptest

:cur_aftercheckingeliminationnumbers233
set skipitelim=1
goto cur_aftercheckingeliminationnumbers23

:lonelyingame
cls
call :cur_gamerunning_lonely
:cur_ingame_lonely
more /e +%lines% "%logfile%" >TEMP.gen
set newseconds=
set /p newseconds=<seconds.sys
if not defined newseconds set newseconds=%seconds%
if %newseconds%==%seconds% goto cur_aftercheckingseconds_lonely
set seconds=%newseconds%
set lastseconds=%seconds%
call :cur_gamerunning_lonely
:cur_aftercheckingseconds_lonely
:aftercheckingseconds_lonely
find /i "[StateMainMenu] Loading scene MainMenu" TEMP.gen >NUL
if %errorlevel%==0 goto cur_checkaddelimmainmenu
if not %isexplore%==1 goto afterexplorecheck_lonely
find /i "[GameplaySpectatorUltimatePartyFlowViewModel] Matchmaking begins!" TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
find /i "[MatchmakeWhileInGameHandler] Begin matchmaking..." TEMP.gen >NUL
if %errorlevel%==0 goto cur_waitforexplorematchmaking
:afterexplorecheck_lonely
find /i "[GameSession] Changing state from Playing to GameOver" TEMP.gen >NUL
if not %errorlevel%==0 goto cur_ingame_lonely
echo Round Over! && goto cur_ingame
:cur_gamerunning_lonely
cls
echo TIME: %seconds% R%currentround%: !mapname!
timeout 1 >NUL
goto :EOF

:cur_checkaddelimmainmenu
if %usereliminated%==1 goto cur_clsmainmenu
set /a stats.eliminated=%stats.eliminated%+1
echo %stats.eliminated% >stats.eliminated.sys
start /min cmd /c stats_addelimination.bat
goto cur_clsmainmenu