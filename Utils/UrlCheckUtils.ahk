!r::
Send, cd /home/t-kanda/HDQL16/src_debian-750/%clipboard%
Send, find . -mindepth 2 -maxdepth 2 -name "README*" | xargs more{Enter}
return


!e::
IfWinExist, PackageList.csv - Excel
 WinActivate

Send, {Down}{Home}
Send, ^c
return