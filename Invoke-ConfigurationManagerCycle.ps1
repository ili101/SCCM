#requires -Version 2
# https://www.systemcenterdudes.com/configuration-manager-2012-client-command-list/
# https://blogs.msdn.microsoft.com/timid/2013/03/01/psh-v1-get-tail/
# http://mickitblog.blogspot.co.il/2016/05/initiating-sccm-actions-with.html
function Invoke-ConfigurationManagerCycle
{
    <#
            .SYNOPSIS
            Initiate Configuration Manager Client Scan
            .DESCRIPTION
            This will initiate an SCCM action
            .PARAMETER CycleName
            Name of Cycle
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Application Deployment Evaluation Cycle','Discovery Data Collection Cycle','File Collection Cycle','Hardware Inventory Cycle','Machine Policy Evaluation Cycle','Machine Policy Retrieval Cycle','Software Inventory Cycle','Software Metering Usage Report Cycle','Software Updates Assignments Evaluation Cycle','Software Update Scan Cycle','Windows Installers Source List Update Cycle')]
        [string]$CycleName
    )

    #Cycles database
    $Commands = @{}
    $Commands.Add('Application Deployment Evaluation Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000121'
                    'Log'    = "$env:windir\ccm\logs\DCMReporting.log"
                    'Patterns' = @{
                        '*FinalRelease*' = 'Completed'
                    }
    })))
    $Commands.Add('Discovery Data Collection Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000003'
                    'Log'    = "$env:windir\ccm\logs\InventoryAgent.log"
                    'Patterns' = @{
                        '*End of message processing*' = 'Completed'
                    }
    })))
    $Commands.Add('File Collection Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000010'
                    'Log'    = "$env:windir\ccm\logs\InventoryAgent.log"
                    'Patterns' = @{
                        '*Action completed*'             = 'Completed'
                        '*Exiting as no items to collect*' = 'Completed'
                    }
    })))
    $Commands.Add('Hardware Inventory Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000001'
                    'Log'    = "$env:windir\ccm\logs\InventoryAgent.log"
                    'Patterns' = @{
                        '*End of message processing*'        = 'Completed'
                        '*already in queue. Message ignored.*' = 'Ignored'
                    }
    })))
    $Commands.Add('Machine Policy Evaluation Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000022'
                    'Log'    = "$env:windir\ccm\logs\PolicyEvaluator.log"
                    'Patterns' = @{
                        '*instance of CCM_PolicyAgent_PolicyEvaluationComplete*' = 'Completed'
                    }
    })))
    $Commands.Add('Machine Policy Retrieval Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000021'
                    'Log'    = "$env:windir\ccm\logs\PolicyAgent.log"
                    'Patterns' = @{
                        '*instance of CCM_PolicyAgent_AssignmentsRequested*' = 'Completed'
                    }
    })))
    $Commands.Add('Software Inventory Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000002'
                    'Log'    = "$env:windir\ccm\logs\InventoryAgent.log"
                    'Patterns' = @{
                        '*Initialization completed in*' = 'Completed'
                    }
    })))
    $Commands.Add('Software Metering Usage Report Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000031'
                    'Log'    = "$env:windir\ccm\logs\SWMTRReportGen.log"
                    'Patterns' = @{
                        '*No usage data found to generate software metering report*' = 'Completed'
                        '*Successfully generated report header*'                   = 'Completed'
                        '*Message ID of sent message*'                             = 'Completed'
                    }
    })))
    $Commands.Add('Software Updates Assignments Evaluation Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000108'
                    'Log'    = "$env:windir\ccm\logs\ScanAgent.log"
                    'Patterns' = @{
                        '*Calling back to client on Scan request complete*' = 'Completed'
                    }
    })))
    $Commands.Add('Software Update Scan Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000113'
                    'Log'    = "$env:windir\ccm\logs\ScanAgent.log"
                    'Patterns' = @{
                        '*scan completion received*' = 'Completed'
                    }
    })))
    $Commands.Add('Windows Installers Source List Update Cycle', (New-Object -TypeName PSObject -Property (@{
                    'Code'   = '00000000-0000-0000-0000-000000000032'
                    'Log'    = "$env:windir\ccm\logs\SrcUpdateMgr.log"
                    'Patterns' = @{
                        '*MSI update source list task finished successfully*' = 'Completed'
                    }
    })))

    "Running $CycleName"
    $Command = [scriptblock]::Create('$null = Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList "{{{0}}}"' -f $Commands[$CycleName].Code)
    Wait-StringInFile -Path $Commands[$CycleName].Log -Patterns $Commands[$CycleName].Patterns -Script $Command
}

function Wait-StringInFile
{
    <#
            .SYNOPSIS
            Waits for a string to show in log file
            .DESCRIPTION
            Similar to 'Get-Content -Path "$env:windir\ccm\logs\PolicyEvaluator.log" -Tail 0 -Wait | % {}' but suppoet Powershell 2.0
            .PARAMETER Path
            Path to log file
            .PARAMETER Patterns
            Patterns to find in log file (-like format), hash table of 'Pattern' = 'return code'
            .PARAMETER TimeOut
            Default is 5 minutes
            .PARAMETER Script
            Script to run after starting to monitor to the log file
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [Hashtable]$Patterns,

        [Parameter(Mandatory = $false, Position = 2)]
        [TimeSpan]$TimeOut = (New-TimeSpan -Minutes 5),

        [Parameter(Mandatory = $false, Position = 3)]
        [ScriptBlock]$Script
    )
    $StartTime = Get-Date
    $RotateTime = $StartTime
    $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList (New-Object -TypeName IO.FileStream -ArgumentList ($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([IO.FileShare]::Delete,([IO.FileShare]::ReadWrite)) ))
    #get end the file
    $LastMaxOffset = $Reader.BaseStream.Length
    #get encoding
    $null = $Reader.Readline()
    $Reader.DiscardBufferedData()
    #seek to the last max offset
    $null = $Reader.BaseStream.Seek($LastMaxOffset, [System.IO.SeekOrigin]::Begin)

    if ($Script)
    {
        & $Script
    }

    :ReaderLoop while ($true)
    {
        Start-Sleep -Milliseconds 100

        if ((Get-Date) - $StartTime -ge $TimeOut)
        {
            'TimeOut'
            break
        }

        #detect file rotate
        if ($PathR = Get-ChildItem -Path ($Path -replace '\.', '-*.') -ErrorAction SilentlyContinue | Where-Object -FilterScript {
                $_.CreationTime -gt $RotateTime
        })
        {
            Write-Verbose -Message "file $PathR rotated in $($PathR.CreationTime) at $LastMaxOffset"

            #read the rotated file from LastMaxOffset
            $ReaderR = New-Object -TypeName System.IO.StreamReader -ArgumentList (New-Object -TypeName IO.FileStream -ArgumentList ($PathR.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([IO.FileShare]::Delete,([IO.FileShare]::ReadWrite)) )), $Reader.CurrentEncoding
            $null = $ReaderR.BaseStream.Seek($LastMaxOffset, [System.IO.SeekOrigin]::Begin)
            #read out of the file until the EOF
            while (($Line = $ReaderR.ReadLine()) -ne $null)
            {
                Write-Verbose -Message $Line
                foreach ($Pattern in $Patterns.Keys)
                {
                    if ($Line -like $Pattern)
                    {
                        $Patterns[$Pattern]
                        break ReaderLoop
                    }
                }
            }

            $RotateTime = $PathR.CreationTime
            Write-Verbose -Message 'file rotated end'
            #go back to the start of the file
            $LastMaxOffset = 0
            #seek to the Beginning
            $null = $Reader.BaseStream.Seek($LastMaxOffset, [System.IO.SeekOrigin]::Begin)
        }

        #if the file size has not changed, idle
        if ($Reader.BaseStream.Length -eq $LastMaxOffset)
        {
            continue
        }
    
        #read out of the file until the EOF
        while (($Line = $Reader.ReadLine()) -ne $null)
        {
            Write-Verbose -Message $Line
            foreach ($Pattern in $Patterns.Keys)
            {
                if ($Line -like $Pattern)
                {
                    $Patterns[$Pattern]
                    break ReaderLoop
                }
            }
        }
        #update the last max offset
        $LastMaxOffset = $Reader.BaseStream.Position
    }
}

<#
        Invoke-ConfigurationManagerCycle -CycleName 'Machine Policy Retrieval Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Machine Policy Evaluation Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Software Update Scan Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Software Updates Assignments Evaluation Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Application Deployment Evaluation Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Discovery Data Collection Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'File Collection Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Hardware Inventory Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Software Inventory Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Software Metering Usage Report Cycle'
        Invoke-ConfigurationManagerCycle -CycleName 'Windows Installers Source List Update Cycle'
#>