param (
    [string]$rgName = "contoso-rg",  # Can be a full name or a prefix
    [string]$location = "westus2",
    [string]$sqlAdminPw = $null # Optional, if not provided, a secure one will be generated
)

$bicepFile = "SqlDatabase.bicep"

# Function to generate a secure random password (12 characters, no spaces)
function Get-SecurePassword {
    $lowercase = Get-Random -InputObject "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $uppercase = Get-Random -InputObject "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    $numbers = Get-Random -InputObject "0123456789".ToCharArray()
    $specialChars = Get-Random -InputObject "$!@#%^&*".ToCharArray()
    $randomChars = Get-Random -InputObject "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789$!@#%^&*()-_=+{}[];:,.<>?".ToCharArray() -Count 8

    # Initialize an empty string
    $secureSuffix = ""

    # Loop through each selection and append only character position [0]
    foreach ($char in ($lowercase, $uppercase, $numbers,  $specialChars) + $randomChars) {
        if ($char -ne " ") {
            $secureSuffix += $char
        }
    }

    # Shuffle the characters to remove any patterns
    $secureSuffix = -join ($secureSuffix.ToCharArray() | Sort-Object {Get-Random})

    return $secureSuffix

}

# Function to validate the provided password (only if provided)
function Test-Password {
    param (
        [string]$testPw
    )

    #Write-Host "Evaluating password == $testPw" -ForegroundColor Yellow

    if ($testPw.Length -lt 12) {
        Write-Host "Error: Password must be at least 12 characters long" -ForegroundColor Red
        exit 1
    }
    if ($testPw -cnotmatch "[a-z]") {
        Write-Host "Error: Password must contain at least one lowercase letter." -ForegroundColor Red
        exit 1
    }
    if ($testPw -cnotmatch "[A-Z]") {
        Write-Host "Error: Password must contain at least one uppercase letter." -ForegroundColor Red
        exit 1
    }
    if ($testPw -notmatch "[0-9]") {
        Write-Host "Error: Password must contain at least one number." -ForegroundColor Red
        exit 1
    }
    if ($testPw -notmatch "[\$!@#%^&*()\-_=+{}\[\];:,.<>?]") {
        Write-Host "Error: Password must contain at least one special character ($!@#%^&*()-_=+{}[];:,.<>?)." -ForegroundColor Red
        exit 1
    }

}

# Function to get the public IP
function Get-PublicIP {
    try {
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org"
        return $ip
    } catch {
        Write-Host "Failed to retrieve public IP."
        exit 1
    }
}

# Function to get existing resource groups
function Get-ExistingResourceGroups {
    try {
        Write-Host "Retrieving existing resource groups..."
        $rgList = az group list --query "[].{Name:name, Location:location}" --output table
        if ($rgList) {
            Write-Host "Here are the available resource groups in your subscription:"
            Write-Host $rgList
            exit 1
        } else {
            Write-Host "No resource groups found in this subscription."
            exit 1
        }
    } catch {
        Write-Host "Error retrieving resource groups."
        exit 1
    }
}

# Secure Unique Suffix Generator (12 Characters, No Spaces)
function Get-SecureUniqueSuffix {
    $randomNumber = Get-Random -Minimum 10000000 -Maximum 99999999
    $uniqueSuffix = "$randomNumber"

    return $uniqueSuffix
}


# If a password was provided, validate it; otherwise, generate a new one
if ($sqlAdminPw) {
    Test-Password -testPw $sqlAdminPw
} else {
    $sqlAdminPw = Get-SecurePassword
    Write-Host "Generated Secure Password: $sqlAdminPw"
}

# Get current public IP
$publicIp = Get-PublicIP
Write-Host "Your current public IP is: $publicIp"

# Check if a Resource Group with the prefix exists
$matchingRg = az group list --query "[?starts_with(name, '$rgName')].name" --output tsv

if ($matchingRg) {
    Write-Host "A resource group prefixed with '$rgName' already exists. Using resource group '$matchingRg'."
    $rgName = $matchingRg
} else {
    # Step C: Try to create the resource group
    Write-Host "No existing resource group prefixed with '$rgName'. Attempting to create '$rgName'..."
    try {
        az group create --name $rgName --location $location --output none
        Write-Host "Resource Group '$rgName' created successfully."
    } catch {
        # Step D: If creation fails, list existing resource groups and exit
        Write-Host "Error: Unable to create resource group '$rgName'. Checking for existing resource groups..."
        Get-ExistingResourceGroups
    }
}

# Generate a unique string for resource names
$uniqueSuffix = Get-SecureUniqueSuffix
Write-Host "Generated unique suffix: $uniqueSuffix"

# Deploy the Bicep file and capture output values
$deploymentOutput = az deployment group create `
    --resource-group $rgName `
    --template-file "./$bicepFile" `
    --parameters sqlAdminPw="$sqlAdminPw" `
                 adminIpAddress="$publicIp" `
                 uniqueSuffix="$uniqueSuffix" `
    --query "properties.outputs" --output json | ConvertFrom-Json

Write-Host "Deployment completed!"

# Return SQL Server details
Write-Host "`n==================== Deployment Results ===================="
Write-Host "Resource Group Name: $rgName"
Write-Host "SQL Server Name: $($deploymentOutput.sqlServerName.value).database.windows.net"
Write-Host "SQL Database Name: $($deploymentOutput.sqlDatabaseName.value)"
Write-Host "SQL Admin Username: $($deploymentOutput.sqlAdminUsername.value)"
Write-Host "Password: $sqlAdminPw"
Write-Host "============================================================"
