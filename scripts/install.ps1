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
