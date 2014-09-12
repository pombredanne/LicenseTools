

fileName = %1%

if !fileName
{
	MsgBox, File needed!
	return
}

itemCount=1
fCount =0
tCount =0
Loop, read, %fileName%
{

	;MsgBox, %A_LoopReadLine%

	Fields=
	StringSplit, Fields, A_LoopReadLine, `,

	if (Fields0 >= 3)
		value := Fields3
	else
		value =
		
	;MsgBox, %value%
	
	if (value = "f")
	{
		fCount+=1
	}
	else if(value = "t")
	{
		tCount +=1
	}

	itemCount+=1
}

rate := fCount/(tCount+fCount)

FileAppend, 
(
[%fileName%] - T: %tCount%, F: %fCount%, False Rate: %rate%`n
), log.txt
;FileAppend, aaa, log.txt

MsgBox, T: %tCount%, F: %fCount%, Rate: %rate%

