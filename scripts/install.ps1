# install.ps1
# Created by Joseph Yennaco (9/1/2016)

# Set the Error action preference when an exception is caught
$ErrorActionPreference = "Stop"

# Start a stopwatch to record asset run time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Determine this script's parent directory
# For Powershell v2 use the following (default):
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# For Powershell > v3 you can use one of the following:
#     $scriptPath = Split-Path -LiteralPath $(if ($PSVersionTable.PSVersion.Major -ge 3) { $PSCommandPath } else { & { $MyInvocation.ScriptName } })
#     $scriptPath = $PSScriptRoot

# Load the PATH environment variable
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")

########################### VARIABLES ###############################

# Get the CONS3RT environment variables
$global:ASSET_DIR = $null
$global:DEPLOYMENT_HOME = $null
$global:DEPLOYMENT_PROPERTIES = $null

# exit code
$exitCode = 0

# Configure the log file
$LOGTAG = "install-sample"
$TIMESTAMP = Get-Date -f yyyy-MM-dd-HHmm
$LOGFILE = "C:\log\cons3rt-install-$LOGTAG-$TIMESTAMP.log"

######################### END VARIABLES #############################

######################## HELPER FUNCTIONS ############################

# Set up logging functions
function logger($level, $logstring) {
   $stamp = get-date -f yyyyMMdd-HHmmss
   $logmsg = "$stamp - $LOGTAG - [$level] - $logstring"
   write-output $logmsg
}
function logErr($logstring) { logger "ERROR" $logstring }
function logWarn($logstring) { logger "WARNING" $logstring }
function logInfo($logstring) { logger "INFO" $logstring }

function get_asset_dir() {
    if ($env:ASSET_DIR) {
        $global:ASSET_DIR = $env:ASSET_DIR
        return
    }
    else {
        logWarn "ASSET_DIR environment variable not set, attempting to determine..."
        if (!$PSScriptRoot) {
            logInfo "Determining script directory using the pre-Powershell v3 method..."
            $scriptDir = split-path -parent $MyInvocation.MyCommand.Definition
        }
        else {
            logInfo "Determining the script directory using the PSScriptRoot variable..."
            $scriptDir = $PSScriptRoot
        }
        if (!$scriptDir) {
            $msg =  "Unable to determine the script directory to get ASSET_DIR"
            logErr $msg
            throw $msg
        }
        else {
            $global:ASSET_DIR = "$scriptDir\.."
            logInfo "Determined ASSET_DIR to be: $global:ASSET_DIR"
        }
    }
}

function get_deployment_home() {
    # Ensure DEPLOYMENT_HOME is set
    if ($env:DEPLOYMENT_HOME) {
        $global:DEPLOYMENT_HOME = $env:DEPLOYMENT_HOME
        logInfo "Found DEPLOYMENT_HOME set to $global:DEPLOYMENT_HOME"
    }
    else {
        logWarn "DEPLOYMENT_HOME is not set, attempting to determine..."
        # CONS3RT Agent Run directory location
        $cons3rtAgentRunDir = "C:\cons3rt-agent\run"
        $deploymentDirName = get-childitem $cons3rtAgentRunDir -name -dir | select-string "Deployment"
        $deploymentDir = "$cons3rtAgentRunDir\$deploymentDirName"
        if (test-path $deploymentDir) {
            $global:DEPLOYMENT_HOME = $deploymentDir
        }
        else {
            $msg = "Unable to determine DEPLOYMENT_HOME from: $deploymentDir"
            logErr $msg
            throw $msg
        }
    }
    logInfo "Using DEPLOYMENT_HOME: $global:DEPLOYMENT_HOME"
}

function get_deployment_properties() {
    $deploymentPropertiesFile = "$global:DEPLOYMENT_HOME\deployment-properties.ps1"
    if ( !(test-path $deploymentPropertiesFile) ) {
        $msg = "Deployment properties not found: $deploymentPropertiesFile"
        logErr $msg
        throw $msg
    }
    else {
        $global:DEPLOYMENT_PROPERTIES = $deploymentPropertiesFile
        logInfo "Found deployment properties file: $global:DEPLOYMENT_PROPERTIES"
    }
    import-module $global:DEPLOYMENT_PROPERTIES -force -global
}

###################### END HELPER FUNCTIONS ##########################

######################## SCRIPT EXECUTION ############################

new-item $logfile -itemType file -force
start-transcript -append -path $logfile
logInfo "Running $LOGTAG..."

try {
    logInfo "Installing at: $TIMESTAMP"
    
    # Set asset dir
    logInfo "Setting ASSET_DIR..."
    get_asset_dir

    # Load the deployment properties as variables
    logInfo "Loading deployment properties..."
    get_deployment_home
    get_deployment_properties

	logInfo "ASSET_DIR: $global:ASSET_DIR"
	$mediaDir="$ASSET_DIR\media"

	# Exit if the media directory is not found
	if ( !(test-path $mediaDir) ) {
		$errMsg = "media directory not found: $mediaDir"
		logErr $errMsg
		throw $errMsg
	}
	else {
	    logInfo "Found the media directory: $mediaDir"
	}

	# Set an environment variable
	logInfo "Setting an environment variable ..."
	[Environment]::SetEnvironmentVariable("MY_VARIABLE", "C:\my_env_variable", "Machine")
		
	# Get an environment variable
	$PATH=[Environment]::GetEnvironmentVariable("PATH", "Machine")
	logInfo "PATH: $PATH"

    # Ensure your variable was loaded
    if ( !$cons3rt_user ) {
        $errMsg = "Required deployment property not found: cons3rt_user"
        logErr $errMsg
        throw $errMsg
    }
    else {
        logInfo "Found deployment property cons3rt_user: $cons3rt_user"
    }
}
catch {
    logErr "Caught exception after $($stopwatch.Elapsed): $_"
    $exitCode = 1
}
finally {
    logInfo "$LOGTAG complete in $($stopwatch.Elapsed)"
}

###################### END SCRIPT EXECUTION ##########################

logInfo "Exiting with code: $exitCode"
stop-transcript
get-content -Path $logfile
exit $exitCode

