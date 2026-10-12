# ==============================================================================
# AWS Infrastructure Automation - Verification Script (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   AWS Infrastructure Automation - Verification    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$TerraformDir = Join-Path $PSScriptRoot "..\terraform"

if (-not (Test-Path $TerraformDir)) {
    Write-Host "[ERROR] terraform directory not found at $TerraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $TerraformDir

try {
    Write-Host "`n[1/4] Reading Terraform outputs..." -ForegroundColor Yellow

    $OutputsJson = terraform output -json 2>$null
    if (-not $OutputsJson) {
        Write-Host "[ERROR] No Terraform state found or 'terraform output' failed." -ForegroundColor Red
        Write-Host "Run 'terraform apply' first inside the terraform/ directory."
        exit 1
    }

    $Outputs = $OutputsJson | ConvertFrom-Json

    $VpcId = $Outputs.vpc_id.value
    $SubnetId = $Outputs.public_subnet_id.value
    $InstanceId = $Outputs.instance_id.value
    $InstanceIp = $Outputs.instance_public_ip.value
    $VerifyUrl = $Outputs.verification_url.value
    $SshCmd = $Outputs.ssh_command.value

    Write-Host "  VPC ID:        $VpcId" -ForegroundColor Green
    Write-Host "  Subnet ID:     $SubnetId" -ForegroundColor Green
    Write-Host "  Instance ID:   $InstanceId" -ForegroundColor Green
    Write-Host "  Public IP:     $InstanceIp" -ForegroundColor Green
    Write-Host "  URL:           $VerifyUrl" -ForegroundColor Green

    Write-Host "`n[2/4] Testing HTTP Connectivity..." -ForegroundColor Yellow
    Write-Host "Sending HTTP GET request to: $VerifyUrl"

    $maxRetries = 6
    $retryDelay = 5
    $success = $false

    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Host "Attempt $i of $maxRetries..."
        try {
            $resp = Invoke-WebRequest -Uri $VerifyUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            if ($resp.Content -match "AWS Infrastructure Automation") {
                $success = $true
                break
            }
        }
        catch {
            # Retry after delay
        }

        if ($i -lt $maxRetries) {
            Write-Host "EC2 user-data script may still be initializing. Retrying in ${retryDelay}s..."
            Start-Sleep -Seconds $retryDelay
        }
    }

    if ($success) {
        Write-Host "[SUCCESS] HTTP verification check passed! The EC2 web server responded." -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] Could not reach HTTP endpoint or response was unexpected." -ForegroundColor Yellow
        Write-Host "The instance might still be booting or security group rules may restrict access."
    }

    Write-Host "`n[3/4] Checking AWS CLI State (optional)..." -ForegroundColor Yellow
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        aws ec2 describe-instances --instance-ids $InstanceId --query "Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]" --output table
    }
    else {
        Write-Host "AWS CLI not detected in PATH. Skipping API query."
    }

    Write-Host "`n[4/4] Remote SSH Access Information:" -ForegroundColor Yellow
    Write-Host "  Command: $SshCmd" -ForegroundColor Green

    Write-Host "`n====================================================" -ForegroundColor Cyan
    Write-Host "   Verification Complete!                           " -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
}
finally {
    Pop-Location
}
