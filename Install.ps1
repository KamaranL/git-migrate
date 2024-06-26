[CmdletBinding()]
[OutputType([void])]
param ()

# .DESCRIPTION
# Installs Git config, hooks, and commands

function Env {
    [CmdletBinding()]
    param (
        # Variable name
        [Parameter(
            Mandatory,
            Position = 0)]
        [String]
        $Key,

        # Variable value
        [Parameter(
            Position = 1)]
        [String]
        $Value,

        # Variable scope
        [ValidateSet('User', 'Machine')]
        [String]
        $Scope
    )

    function Scope([string]$Scope) {
        try {
            $Result = [System.Environment]::GetEnvironmentVariable($Key, $Scope).TrimEnd($PS)

            if ($Result -match $PS) {
                $Result = $Result -split $PS
            }

            return $Result
        } catch { return }
    }

    try {
        if (!($Value)) {
            if (!($Scope)) {
                $User = Scope('User')
                $Machine = Scope('Machine')

                return $($User; $Machine)
            } else {
                return @(Scope($Scope))
            }
        } else {
            Write-Verbose `
                "Performing the operation `"Set environment variable`" on target `"Name: $Key Value: $Value`"."
            [System.Environment]::SetEnvironmentVariable($Key, $Value, 'User')
        }
    } catch { return }
}

#Set-StrictMode -Version Latest

if ($PSBoundParameters -and $PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
$DSC = [System.IO.Path]::DirectorySeparatorChar
$PS = [System.IO.Path]::PathSeparator

# check git version
$MinimumVersion = 2.32
$Version = (Get-Command 'git').Version
if (($Version.Major, $Version.Minor -join '.') -lt $MinimumVersion) {
    throw [System.NotSupportedException]::new("Minimum version of `"$MinimumVersion`" required")
}

# move current directory if not already moved
$TargetDir = $HOME, '.config', 'git' -join $DSC
$CurrentDir = (Get-Item $PWD).DirectoryName
Write-Verbose 'Checking gitconfig...'
if ($CurrentDir -ne $TargetDir) {
    $CopyItems = 'Copy-Item $CurrentDir\* $TargetDir -Recurse -Force'

    if (Test-Path $TargetDir -PathType Container) {
        $CopyItems += ' -Confirm'
    } else {
        Write-Verbose "Performing the operation `"Create Directory`" on target `"Destination: $TargetDir`""
        $null = New-Item $TargetDir -ItemType Directory -Force
    }

    if ($PSBoundParameters.Verbose) { $CopyItems += ' -Verbose' }

    Invoke-Command -ScriptBlock ([ScriptBlock]::Create($CopyItems))
}

# backup existing global config
$OldGlobalConfig = $HOME, '.gitconfig' -join $DSC
if (Test-Path $OldGlobalConfig -PathType Leaf) {
    Copy-Item $OldGlobalConfig "$OldGlobalConfig.bak" -Force -Confirm:$false
    if ($?) { Remove-Item $OldGlobalConfig -Force -Confirm:$false }
}

# new global config
$GlobalConfig = $TargetDir, 'conf', 'main.conf' -join $DSC

# set env vars
if ((Env 'GIT_CONFIG_NOSYSTEM') -notcontains 'true') { Env 'GIT_CONFIG_NOSYSTEM' 'true' }
if ((Env 'GIT_CONFIG_GLOBAL') -notcontains $GlobalConfig) { Env 'GIT_CONFIG_GLOBAL' $GlobalConfig }

# add commands to PATH
$CommandsDir = $TargetDir, 'commands' -join $DSC
if ((Env 'Path') -notcontains $CommandsDir) {
    $Path = "$CommandsDir$PS"
    $Path += (Env 'Path' -Scope User) -join $PS
    Env 'Path' $Path
}

'Done!'

Set-Location $TargetDir

exit 0
