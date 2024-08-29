# Define the log file path
$logFilePath = "C:\inetpub\wwwroot\permission_script.log"

# Start logging (plain text, no colors)
Start-Transcript -Path $logFilePath -Append

# Define the base path and excluded folder
$basePath = "C:\inetpub\wwwroot"
$excludeFolder = "aspnet_client"

# Define the required permissions
$requiredPermissions = @("Modify", "ReadAndExecute", "ListDirectory", "Read", "Write")


# Function to display simplified ACL entries for the Users group
function Show-UsersPermissions {
    param (
        [string]$Path
    )
    try {
        $acl = Get-Acl -Path $Path
    }
    catch {
        Write-Host "Error retrieving ACL for $($Path): $_" -ForegroundColor Red
        return
    }

    $usersAccess = $acl.Access | Where-Object {
        $_.IdentityReference -eq "BUILTIN\Users" -or $_.IdentityReference -eq "Users"
    }

    if ($usersAccess) {
        $rights = @()
        foreach ($access in $usersAccess) {
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ReadAndExecute) {
                $rights += "Read & execute"
            }
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ListDirectory) {
                $rights += "List folder contents"
            }
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Read) {
                $rights += "Read"
            }
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) {
                $rights += "Write"
            }
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify) {
                $rights += "Modify"
            }
            if ($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) {
                $rights += "Full control"
            }
        }
        $uniqueRights = $rights | Sort-Object -Unique
        Write-Host "Permissions for Users group: $($uniqueRights -join ', ')" -ForegroundColor Cyan
    }
    else {
        Write-Host "No explicit permissions for Users group." -ForegroundColor Yellow
    }
}

# Function to validate permissions
function Validate-Permissions {
    param (
        [string]$Path,
        [string[]]$RequiredPerms
    )

    try {
        $currentAcl = Get-Acl -Path $Path
    }
    catch {
        Write-Host "Error retrieving ACL for validation: $($Path): $_" -ForegroundColor Red
        return $false
    }

    $usersPermissions = $currentAcl.Access | Where-Object {
        $_.IdentityReference -eq "BUILTIN\Users" -or $_.IdentityReference -eq "Users"
    }

    # Aggregate all permissions for Users group
    $aggregateRights = [System.Security.AccessControl.FileSystemRights]::None
    foreach ($perm in $usersPermissions.FileSystemRights) {
        $aggregateRights = $aggregateRights -bor $perm
    }

    # Check if all required permissions are present
    foreach ($perm in $RequiredPerms) {
        $enumPerm = [System.Security.AccessControl.FileSystemRights]::$perm
        if (-not ($aggregateRights -band $enumPerm)) {
            return $false
        }
    }

    return $true
}

# Function to apply permissions with inheritance replacement
function Apply-Permissions {
    param (
        [string]$folderPath
    )

    # Get current ACL
    $acl = Get-Acl -Path $folderPath

    # Remove existing "Users" permissions to avoid conflicts
    $acl.Access | Where-Object {
        $_.IdentityReference -eq "BUILTIN\Users" -or $_.IdentityReference -eq "Users"
    } | ForEach-Object { $acl.RemoveAccessRule($_) }

    # Create the new access rule
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Users",
        $requiredPermissions,
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    # Add the new access rule to the ACL
    $acl.AddAccessRule($accessRule)

    # Apply the updated ACL to the folder
    try {
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "DONE! Permissions set on: $($folderPath)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting ACL for $($folderPath): $_" -ForegroundColor Red
        continue
    }

    # Optionally force inheritance to replace child object permissions
    try {
        $acl.SetAccessRuleProtection($false, $true)
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "Inheritance applied: Child object permissions replaced." -ForegroundColor Green
    }
    catch {
        Write-Host "Error applying inheritance to $($folderPath): $_" -ForegroundColor Red
    }
}

function Main {
	# Display script header
	Write-Host "=======================" -ForegroundColor Cyan
	Write-Host "Permission Setter Script" -ForegroundColor Cyan
	Write-Host "Base Path: $($basePath)" -ForegroundColor Cyan
	Write-Host "Excluded Folder: $($excludeFolder)" -ForegroundColor Cyan
	Write-Host "=======================" -ForegroundColor Cyan

	# Retrieve all directories except the excluded one
	$folders = Get-ChildItem -Path $basePath -Directory | Where-Object { $_.Name -ne $excludeFolder }

	# Display folders being processed
	Write-Host "Folders to be processed:" -ForegroundColor Yellow
	$folders | ForEach-Object { Write-Host ("- " + $_.FullName) -ForegroundColor Green }

	# Iterate through each folder
	foreach ($folder in $folders) {
			$folderPath = $folder.FullName

			# Display processing information
			Write-Host "===============================" -ForegroundColor Cyan
			Write-Host ("Processing Folder: $($folderPath)") -ForegroundColor Magenta
			Write-Host "===============================" -ForegroundColor Cyan

			# Echo current permissions
			Write-Host "Current Permissions for Users group:" -ForegroundColor Yellow
			Show-UsersPermissions -Path $folderPath

			# Apply Permissions
			Apply-Permissions -folderPath $folderPath

			# Echo updated permissions
			Write-Host "Updated Permissions for Users group:" -ForegroundColor Yellow
			Show-UsersPermissions -Path $folderPath

			# Validate the permissions
			$isValid = Validate-Permissions -Path $folderPath -RequiredPerms $requiredPermissions
			$null = $isValid  # Suppress the output of $isValid

			if ($isValid) {
				Write-Host "Validation PASSED for: $($folderPath)" -ForegroundColor Green
			} else {
				Write-Host "Validation NOT PASSED for: $($folderPath). Retrying..." -ForegroundColor Red

				# Retry the permissions application
				Apply-Permissions -folderPath $folderPath

				# Validate again after retrying
				$isValidAfterRetry = Validate-Permissions -Path $folderPath -RequiredPerms $requiredPermissions
				$null = $isValidAfterRetry  # Suppress the output of $isValidAfterRetry

				if ($isValidAfterRetry) {
					Write-Host "Validation PASSED after retry for: $($folderPath)" -ForegroundColor Green
				} else {
					Write-Host "Validation FAILED after retry for: $($folderPath). Please check manually." -ForegroundColor Red
				}
			}

			Write-Host ""  # Add spacing between iterations
		}

		# Completion message
		Write-Host "===============================" -ForegroundColor Cyan
		Write-Host "All specified folders have been processed and validated." -ForegroundColor Cyan
		Write-Host "===============================" -ForegroundColor Cyan

	
}

Main

# Stop logging
Stop-Transcript
