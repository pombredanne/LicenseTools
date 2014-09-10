

inFileName = %1%

if !inFileName
{
	MsgBox, File needed!
	return
}

SplitPath, inFileName, , , ext, name

outFileName = %name%_evaluated.%ext%

Loop, read, %inFileName%, %outFileName%
{


	;MsgBox, %A_LoopReadLine%

	Fields=
	StringSplit, Fields, A_LoopReadLine, `,


	filename := Fields1
	path := Fields2
	value = 


	Loop, read, LicenseChanged_evaluated.csv
	{
		;MsgBox, %A_LoopReadLine%

		F=
		StringSplit, F, A_LoopReadLine, `,
		p := F2
		v := F3

		if (path = p)
		{
			value := v
			break
		}
	}
	FileAppend, %filename%`,%path%`,%value%`n
}