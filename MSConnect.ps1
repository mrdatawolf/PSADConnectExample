param (
    [string]$email,
    [string]$password,
    [string]$client
)
if (-not $scriptRoot) {
    $scriptRoot = $PSScriptRoot
}

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

$dateForFileName = Get-Date -Format "MM_dd_yyyy"
$modules = @("ExchangeOnlineManagement")
foreach ($module in $modules) {
    $result = Test-ModuleInstallation -ModuleName $module
    if (-not $result) {
        Write-Host "Please restart the script after installing the required modules." -ForegroundColor Red
        exit
    }
}
Write-Host "All required modules are installed and imported."

if ($email -and $password) {
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    Write-Host "Current admin email: $email"
    try {
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword
        Connect-AzureAD -Credential $credential 2>$null
        Connect-ExchangeOnline -Credential $credential -ShowBanner:$false
    }
    catch {
        Write-Host "Username/password login failed.  We will try again with a user prompted login" -ForegroundColor Yellow
        Connect-AzureAD
        Connect-ExchangeOnline
        Write-Host "Done"
    }
}
Disconnect-AzureAD
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Completed."
Pause