# TODO user defined location
$pwStore = Get-Item '~/.password-store/' -Force
# Populate password files for tab completion in Pass-Show and Pass-Edit.
class ValidFilesGenerator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
		$values = Get-ChildItem -Path $script:pwStore -Recurse -File -Filter '*.gpg' `
			| Foreach-Object {$_.FullName -replace "$([regex]::escape($script:pwStore))" -replace '\.gpg$'}
		return $values
    }
}

# Make Pass shorthand for Pass-Show.
Set-Alias Pass Pass-Show

# The function which prints decrypted password files out to the terminal and copies them to clipboard.
function Pass-Show {
	param(
		[Parameter(ParameterSetName = 'Show', Mandatory, Position = 0)]
		[ValidateSet( [ValidFilesGenerator] )]
		[string]
		$showArgs
	)
	
	Start-Process -FilePath 'gpg' -ArgumentList "--decrypt ${showArgs}.gpg" `
		-WorkingDirectory "$pwStore" -NoNewWindow -Wait
}

function Pass-Move {
	param(
		[Parameter(ParameterSetName = 'Move', Mandatory, Position = 0)]
		[ValidateSet( [ValidFilesGenerator] )]
		[string]
		$mvFromArgs,

		[Parameter(ParameterSetName = 'Move', Mandatory, Position = 1)]
		[string]
		$mvToArgs
	)
	
	Start-Process -FilePath 'git' -ArgumentList "mv ${mvFromArgs}.gpg ${mvToArgs}.gpg" `
		-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	_pass-git-commit "$mvToArgs" 'moved' "$mvFromArgs"
}

function Pass-Copy {
	param(
		[Parameter(ParameterSetName = 'Copy', Mandatory, Position = 0)]
		[ValidateSet( [ValidFilesGenerator] )]
		[string]
		$cpFromArgs,

		[Parameter(ParameterSetName = 'Copy', Mandatory, Position = 1)]
		[string]
		$cpToArgs
	)
	
	$cpFromPath = Join-Path -Path $pwStore -ChildPath $cpFromArgs
	$cpToPath = Join-Path -Path $pwStore -ChildPath $cpToArgs
	Copy-Item -Path "${cpFromPath}.gpg" -Destination "${cpToPath}.gpg"
	Start-Process -FilePath 'git' -ArgumentList "add ${cpToPath}.gpg" `
		-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	_pass-git-commit "$cpToArgs" 'copied' "$cpFromArgs"
}

function Pass-Remove {
	param(
		[Parameter(ParameterSetName = 'Remove', Mandatory, Position = 0)]
		[ValidateSet( [ValidFilesGenerator] )]
		[string]
		$rmArgs
	)
	
	Start-Process -FilePath 'git' -ArgumentList "rm ${rmArgs}.gpg" `
		-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	_pass-git-commit "$rmArgs" 'removed'
}

# Wrap some basic git functionality.
function Pass-Git {
	param(
		[Parameter(ParameterSetName = 'Git', Mandatory, Position = 0)]
		[ValidateSet('push','pull','status','log')]
		[string]
		$gitArgs
	)

	Start-Process -FilePath 'git' -ArgumentList "$gitArgs" -WorkingDirectory "$pwStore" `
		-NoNewWindow -Wait
}

# Search through filenames.
function Pass-Find {
	param(
		[Parameter(ParameterSetName = 'Find', Mandatory, Position = 0)]
		[string]
		$findArgs
	)

	# search all subdirectories for matches
	# expand directory matches- list all contents of matched directories
	# return gpg files, which can be piped to gpp -d
}

# Search through the contents of password files.
function Pass-Search {
	param(
		[Parameter(ParameterSetName = 'Search', Mandatory, Position = 0)]
		[string]
		$searchArgs
	)
}

# Edit passwords with your default .txt editor.
function Pass-Edit {
	param(
		[Parameter(ParameterSetName = 'Edit', Mandatory, Position = 0)]
		[ValidateSet( [ValidFilesGenerator] )]
		[string]
		$editArgs
	)

	# Define temporary output file.
	New-Item -Name 'Pass' -Path $ENV:TEMP -ItemType Directory -ErrorAction:Ignore | Out-Null
	$rndNum = Get-Random -Minimum 1000 -Maximum 10000
	$dePath = $editArgs -replace '[\\/]','.'
	$tmpFile = Join-Path "$env:TEMP" 'Pass' "${dePath}.${rndNum}.txt"
	#$tmpFile = New-TemporaryFile # If we use this, need to change edit method.
	# Get GPG ID.
	$gpgid = Get-Content -Path "$pwStore/.gpg-id"
	# Create decrypted copy of password file.
	Start-Process -FilePath 'gpg' `
	-ArgumentList "--decrypt --output $tmpFile --quiet --yes ${editArgs}.gpg" `
	-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	# Get hash of file to detect changes.
	$oldHash = Get-FileHash -Path $tmpFile
	# Open file in default editor, wait for editor to exit.
	Write-Host 'Opening default editor...'
	Start-Process -FilePath $tmpFile -Wait
	# Rehash the file.
	$newHash = Get-FileHash -Path $tmpFile
	# Detect if file has changed.
	if ($oldHash.Hash -notmatch $newHash.Hash) {
		# Encrypt updated text file, overwriting previous passfile entry.
		Start-Process -FilePath 'gpg' `
		-ArgumentList "--encrypt --output ${editArgs}.gpg --recipient ""$gpgid"" --quiet --yes $tmpFile" `
		-WorkingDirectory "$pwStore" -NoNewWindow -Wait
		# Commit to git.
		_pass-git-commit "$editArgs" 'edited'
	} Else {
		Write-Host 'No changes made.'
	}
	# TODO secure erase txt better.
	# Overwrite file.
	Set-Content -Value $rndNum -Path $tmpFile
	Remove-Item $tmpFile
}

function script:_pass-git-commit {
	param(
		[Parameter(ParameterSetName = 'gitcommit', Mandatory, Position = 0)]
		[string]
		$fileArgs,

		[Parameter(ParameterSetName = 'gitcommit', Mandatory, Position = 1)]
		[ValidateSet('edited','copied','moved','removed')]
		[string]
		$actionArgs,

		[Parameter(ParameterSetName = 'gitcommit', Position = 2)]
		[string]
		$supplimentalFileArgs
	)

	# Commit to git.
	# If moving or copying, include origin and destination. For moving, we need to commit the "deleted" file.
	# TODO don't commit the origin file if copying?
	if ($supplimentalFileArgs) {
		Start-Process -FilePath 'git' -ArgumentList "commit ${fileArgs}.gpg $supplimentalFileArgs.gpg -m ""$supplimentalFileArgs $actionArgs to $fileArgs""" `
			-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	} else {
		Start-Process -FilePath 'git' -ArgumentList "commit ${fileArgs}.gpg -m ""$actionArgs $fileArgs""" `
			-WorkingDirectory "$pwStore" -NoNewWindow -Wait
	}
}
