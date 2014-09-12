
aborted:=false

FileDelete, LicenseChanged_evaluated.csv

itemCount=1

Loop, read, LicenseChanged.csv, LicenseChanged_evaluated.csv
{
	if (aborted)
	{
		FileAppend, %A_LoopReadLine%`n
		continue
	}

	;MsgBox, %A_LoopReadLine%

	Fields=
	StringSplit, Fields, A_LoopReadLine, `,


	filename := Fields1
	path := Fields2
	if (Fields0 >= 3)
		value := Fields3
	else
		value =

	if (!value)
	{
		SplitPath, filename, , , ext

		pattern = ..\%path%\*.%ext%

		;MsgBox %pattern%

		count := 1
		FileList=
		first=
		Loop %pattern%
		{
			if count=1
			{
				first = %A_LoopFileFullPath%
			}
			else
			{
				FileList = %first% %A_LoopFileFullPath%

				Run, "D:\Portable\Beyond Compare 3\BCompare.exe" %FileList%

				MsgBox, 3, [%itemCount%] %filename% %count%, Is this FP? Cancel to compare more.

				IfMsgBox Yes
				{
					value = f
					break
				}
				else IfMsgBox No
				{
					value = t
					break
				}
				else
				{
					value =
				}

				;first = %A_LoopFileFullPath%
			}

			count+=1
		}

		if (!value)
		{
			MsgBox, 4, [%itemCount%] %filename%, Is this FP? No more files!
			IfMsgBox Yes
			{
				value = f
			}
			else IfMsgBox No
			{
				value = t
			}
		}

	}

	FileAppend, %filename%`,%path%`,%value%`n
	itemCount+=1
}
ExitApp

^!a::
global aborted
aborted:=true
return