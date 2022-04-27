function sayBye {
    Echo "Goodbye! Closing in..."
        for ($i=3; $i -gt 0; $i--) {
            Echo $i
            Start-Sleep -Seconds 1
        }
        Exit(0)
}
 
function YesOrNo {
    param ($Prompt)

    $reply = Read-Host -Prompt $Prompt

    while("Y","N" -notcontains $reply.toUpper()){
	    $reply = Read-Host -Prompt $Prompt
    }

    return $reply
}

Write-Warning "This program could destroy your computer."
Start-Sleep -Seconds 1
$continue = YesOrNo -Prompt "Do you wish to continue? (Y/N) "


if($continue.ToUpper() -eq "Y") {
    $name = Read-Host -Prompt "Search for all programs with a name including"
    $Apps = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "*$name*"}

    if ($apps) {
        Write-Output $Apps

        $uninst = YesOrNo -Prompt "Uninstall these apps? (Y/N) "
        if ($uninst.toUpper() -eq "Y") {
            $Apps.Uninstall()
        } elseif ($uninst.toUpper() -eq "N") {
            sayBye
        }
    } else {
        Echo "No programs with a name containing `"$name`" were found."
        sayBye
    }
} elseif ($continue.ToUpper() -eq "N") {
    sayBye
}



