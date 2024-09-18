param (
    [string]$email,
    [string]$password
)

if (-not $scriptRoot) {
    $scriptRoot = $PSScriptRoot
}

# Function to test and install modules if not present
function Test-ModuleInstallation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )

    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "The $ModuleName module is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Force
        return $false
    } else {
        Write-Host "Importing $ModuleName..." -ForegroundColor Green
        Import-Module $ModuleName
    }

    return $true
}

# Function to check and install required modules
function Test-Modules {
    $modules = @("ExchangeOnlineManagement", "AzureAD")
    foreach ($module in $modules) {
        $result = Test-ModuleInstallation -ModuleName $module
        if (-not $result) {
            Write-Host "Please restart the script after installing the required modules." -ForegroundColor Red
            exit
        }
    }
    Write-Host "All required modules are installed and imported."
}

# Function to connect to AzureAD and ExchangeOnline
function Connect-Services {
    param (
        [string]$email,
        [string]$password
    )

    if ($email -and $password) {
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        Write-Host "Current admin email: $email"
        try {
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $email, $securePassword
            Connect-AzureAD -Credential $credential 2>$null
            Connect-ExchangeOnline -Credential $credential -ShowBanner:$false
        }
        catch {
            Write-Host "Username/password login failed. We will try again with a user prompted login" -ForegroundColor Yellow
            Connect-AzureAD
            Connect-ExchangeOnline
            Write-Host "Done"
        }
    }
}

# Function to disconnect from AzureAD and ExchangeOnline
function Disconnect-Services {
    Disconnect-AzureAD
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Completed."
}

# Main script execution
Test-Modules
Connect-Services -email $email -password $password

# Test Exchange connection
Get-Mailbox

# Disconnect services
Disconnect-Services

Pause