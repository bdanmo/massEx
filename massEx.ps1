#####################
#FUNCTION DEFINITIONS
#####################

function sayBye {

    param ($Code)

    Write-Output "Goodbye! Closing in..."
        for ($i=3; $i -gt 0; $i--) {
            Write-Output $i
            Start-Sleep -Seconds 1
        }

        Exit($Code)
}
 
function YesOrNo {
    param ($Prompt)

    $reply = Read-Host -Prompt $Prompt

    while("Y","N" -notcontains $reply.toUpper()){
	    $reply = Read-Host -Prompt $Prompt
    }

    if ($reply.ToUpper() -eq "Y") {
        return $true
    } elseif ($reply.ToUpper() -eq "N") {
        return $false
    }
}

function uninstallAll {
    param ($List)

    function uninstallThis {
        param ($App)

        $uninstall = 
            if( $App.Uninstallstring -match '^msiexec' ){
                "$( $App.UninstallString -replace '/I', '/X' ) /qn /norestart"
            } else {
                $App.UninstallString
            }

        Write-Verbose $uninstall
        $proc = Start-Process -Filepath cmd -ArgumentList '/c', $uninstall -NoNewWindow -PassThru -Wait
        return $proc
    }

    foreach ($app in $List) {
        Write-Output "Attempting uninstall of $($app.DisplayName)..."
        $proc = uninstallThis $app
        
        if ($proc.ExitCode -eq 0) {
            #goodtimes
            Write-Output "Uninstall of $($app.DisplayName) was successful, I guess. Why don't you check?"
        } elseif ($proc.ExitCode -eq 1603) {
            #process running, attempt kill and recurse
            Write-Error "$($app.DisplayName) couldn't be uninstalled because it is running."
        } else {
            #awshucks
            Write-Error "$($app.DisplayName) could not be uninstalled. Error code: $($proc.ReturnValue). Try closing the process or running the exe as admin."
        }          
    }

    return $LASTEXITCODE
}

function searchAgain? {
    $searchAgain = YesOrNo "Search for another? (Y/N) "
    if ($searchAgain) {searchAndDestroy}
    elseif (!$searchAgain) {sayBye 0}
}

function searchAndDestroy {
    $name = Read-Host -Prompt "Search for all programs where name includes "
    $RegKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
    )
    $apps = $RegKeys |
            Get-ChildItem |
            Get-ItemProperty | 
            Where-Object{$_.DisplayName -like "*$name*" -and $_.UninstallString}
    

    if ($apps) {

        $appList = $apps | Select-Object -Property DisplayName, Publisher
       
        Write-Output $appList | Out-Host

        $uninst = YesOrNo -Prompt "Uninstall these apps? (Y/N) "

        if ($uninst) {
            try {
                uninstallAll $apps
            } catch {
                Write-Error "Error while attempting uninstall : $Error"
            }
            searchAgain?
        } elseif (!$uninst) {
            searchAgain?
        }
    } else {
        Write-Output "No programs with a name containing `"$name`" were found."
        searchAgain?
    }
}

################
#START EXECUTION
################

Write-Warning "This program could destroy your computer."
Start-Sleep -Seconds 1
$continue = YesOrNo -Prompt "Do you wish to continue? (Y/N) "

if($continue) {
    searchAndDestroy
} elseif (!$continue) {
    sayBye 0
}



