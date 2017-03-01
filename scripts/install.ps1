# install.ps1
# Created by Joseph Yennaco (9/1/2016)

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -LiteralPath $(if ($PSVersionTable.PSVersion.Major -ge 3) { $PSCommandPath } else { & { $MyInvocation.ScriptName } })
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Load the PATH environment variable
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")

########################### VARIABLES ###############################

$ASSET_DIR = "$env:ASSET_DIR"
$TIMESTAMP = Get-Date -f yyyy-MM-dd-HHmm

# exit code
$exitCode = 0

# Log files
$LOGTAG = "install-sample"
$LOGFILE = "C:\log\cons3rt-install-$LOGTAG-$TIMESTAMP.log"

######################### END VARIABLES #############################

######################## HELPER FUNCTIONS ############################

# Set up logging functions
function logger($level, $logstring) {
   $stamp=get-date -f yyyyMMdd-HHmmss
   $logmsg="$stamp - $LOGTAG - [$level] - $logstring"
   add-content $Logfile -value $logmsg
}
function logErr($logstring) { logger "ERROR" $logstring }
function logWarn($logstring) { logger "WARNING" $logstring }
function logInfo($logstring) { logger "INFO" $logstring }

###################### END HELPER FUNCTIONS ##########################

######################## SCRIPT EXECUTION ############################

new-item $LOGFILE -itemType file -force

logInfo "Running $LOGTAG..."

try {
	logInfo "Installing at: $TIMESTAMP"
	logInfo "ASSET_DIR: $ASSET_DIR"
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

    # Ensure DEPLOYMENT_HOME is set
    if ( !$env:DEPLOYMENT_HOME ) {
        logInfo "DEPLOYMENT_HOME is not set, attempting to determine..."
        $deploymentDirName = get-childitem $cons3rtAgentRunDir -name -dir | select-string "Deployment"
        $deploymentDir = "$cons3rtAgentRunDir\$deploymentDirName"
        if (test-path $deploymentDir) {
            $deploymentHome = $deploymentDir
        }
        else {
            $errMsg = "Unable to determine DEPLOYMENT_HOME from: $deploymentDir"
            logErr $errMsg
            throw $errMsg
        }
    }
    else {
        logInfo "Found DEPLOYMENT_HOME set to $env:DEPLOYMENT_HOME"
        $deploymentHome = $env:DEPLOYMENT_HOME
    }
    logInfo "Using DEPLOYMENT_HOME: $deploymentHome"

	# Load Deployment properties
    $deploymentPropertiesFile = "$deploymentHome\deployment-properties.ps1"
    if ( !(test-path $deploymentPropertiesFile) ) {
        $errMsg = "Deployment properties not found: $deploymentPropertiesFile"
        logErr $errMsg
        throw $errMsg
    }
    else {
        logInfo "Found deployment properties file: $deploymentPropertiesFile"
    }

    # Load deployment properties as a variable, in this case cons3rt_user
    logInfo "Loading deployment properties..."
    import-module $deploymentPropertiesFile -force -global

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
    logErr "Caught exception: $_"
    $exitCode = 1
}
finally {
    logInfo "$LOGTAG complete in $($stopwatch.Elapsed)"
}

###################### END SCRIPT EXECUTION ##########################

exit $exitCode
