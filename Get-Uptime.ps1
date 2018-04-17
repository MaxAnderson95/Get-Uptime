<#

    .SYNOPSIS
    Outputs the uptime of a given machine

    .DESCRIPTION
    Outputs the uptime of a given machine using CIM. If no computer name is specified it will output the uptime of the machine running the script.

    .EXAMPLE
    PS> .\Get-Uptime.ps1
    ComputerName Days Hours Minutes
    ------------ ---- ----- -------
    PC01           27     6      26

    .EXAMPLE
    PS> .\Get-Uptime.ps1 -ComputerName "SERVER01","SERVER02"
    ComputerName Days Hours Minutes
    ------------ ---- ----- -------
    SERVER01       7     16       5
    SERVER02       3     10       33

    .EXAMPLE
    PS> "SERVER01","SERVER02" | .\Get-Uptime.ps1
    ComputerName Days Hours Minutes
    ------------ ---- ----- -------
    SERVER01       7     16       5
    SERVER02       3     10       33

#>

[Cmdletbinding()]
Param (

    [Parameter(ValueFromPipeline=$True)]
    [String[]]$ComputerName = $env:COMPUTERNAME,

    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential

)

Begin {

    #Creates an empty arary that will be filled as each machine is looped through.
    Write-Debug "Created empty array."
    $Array = @()

}

Process {

    #Loop through each computer
    ForEach ($Computer in $ComputerName) {

        Write-Debug "Started processing $Computer."

        #Null the variables used in the ForEach Loop
        $LastBoot = $Null
        $Uptime = $Null
        
        Try {
        
            #Attempt to connect to the computer via CIM and pull the LastBootUpTime property from the Win32_OperatingSystem class
            Write-Debug "Attempting to connect to $Computer using CIM"

            If ($Credential) {

                $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential
                $LastBoot = (Get-CimInstance -CimSession $CimSession -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
                Remove-CimSession -CimSession $CimSession

            }

            Else {

                $LastBoot = (Get-CimInstance -ComputerName $Computer -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime

            }
        
        }
        
        #If there is an exception with CIM
        Catch [Microsoft.Management.Infrastructure.CimException] {

            #Write a warning and go to the next computer in the ForEach
            Write-Debug "There was an error connecting to $Computer using CIM"
            Write-Warning "Unable to connect to $Computer via CIM."
            Continue

        }
        #If there are any other exceptions
        Catch {

            #Write a generic warning, and output it to the screen for ease of troubleshooting
            Write-Debug "There was an unhandeled exception."
            Write-Warning "An unknown error occured pulling information from $Computer."
            Write-Error $_
            Continue

        }

        #Take todays date and time and subtract the date and time of last boot
        Write-Debug "Determining uptime of $Computer"
        $Uptime = (Get-Date) - $LastBoot

        #Create a custom object with the name of the computer, as well as the days, hours and minutes of uptime.
        Write-Debug "Creating custom object for $Computer"
        $Object = [PSCustomObject] @{

            "ComputerName" = $Computer
            "Days"         = $Uptime.Days
            "Hours"        = $Uptime.Hours
            "Minutes"      = $Uptime.Minutes

        }

        #Add the custom object to the array
        Write-Debug "Adding custom object for $Computer to the array."
        $Array += $Object
        
        Write-Debug "Finished processing $Computer."
    }

}

End {

    #Output the array
    Write-Debug "Outputing the array."
    Write-Output $Array

}