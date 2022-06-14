#####################
#FUNCTION DEFINITIONS
#####################

$VerbosePreference = "continue"

function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

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
    param ($List, $name)

    $status = [PSCustomObject]@{
        error = $false
        message = ""
        successCount = 0
        failCount = 0
        total = 0
    }

    function uninstallThis {
        param ($App)

        $uninstall = 
            if( $App.UninstallString -match "^msiexec" ){
               "$( $App.UninstallString -replace '/I', '/X' ) /qn /norestart"   
            } else {
                "$($App.UninstallString)"
            }
        
        Write-Output "Uninstall Path: $uninstall"
        $proc = Start-Process -Filepath cmd -ArgumentList "/C", $uninstall -NoNewWindow -PassThru -Wait

        if ($proc.ExitCode -eq 0) {
            #goodtimes
            Write-Output "Uninstall of $($app.DisplayName) was successful."
            $status.successCount += 1
        } elseif ($proc.ExitCode -eq 1603) {
            #process running
            Write-Error "$($app.DisplayName) couldn't be uninstalled because it is running. Try closing the process."
            $status.failCount += 1
            $status.error = $true
        } else {
            #awshucks
            Write-Error "$($app.DisplayName) could not be uninstalled. Error code: $($proc.ExitCode)."
            $status.failCount += 1
            $status.error = $true
        } 
        
        return $proc
    }

    foreach ($app in $List) {
        Write-Output "Attempting uninstall of $($app.DisplayName)..."
        $status.total += 1
        $proc = uninstallThis $app
        
              
    }

    if ($status.error) {
        $status.message = "Batch uninstall completed with errors. Failed to uninstall $($status.failCount) of $($status.total) apps."
        return $status
    } else {
        $status.message = "Batch uninstall complete! $($status.successCount) of $($status.total) programs successfully removed."
        return $status  
    }
    
}

function searchAndDestroy {

    function searchAgain {
        param ($code)
        $searchAgain = YesOrNo "Search for another? (Y/N) "
        if ($searchAgain) {searchAndDestroy}
        elseif (!$searchAgain) {sayBye $code}
    }

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
            $proc = uninstallAll $apps $name
            if ($proc.error) {
                Write-Warning $proc.message
                searchAgain 1
            } else {
                Write-Output $proc.message | Green
                searchAgain 0
            }
            
        } elseif (!$uninst) {
            SearchAgain 0
        }
    } else {
        Write-Output "No programs with a name containing `"$name`" were found." | Red
        SearchAgain 0
    }
}

################
#START EXECUTION
################

Write-Warning "This program has the ability to sequentially uninstall multiple applications. Tread carefully! Press ctrl+C to abort a batch uninstall that is underway."
Start-Sleep -Milliseconds 500
$continue = YesOrNo -Prompt "Do you wish to continue to search? (Y/N) "

if($continue) {
    searchAndDestroy
} elseif (!$continue) {
    sayBye 0
}



