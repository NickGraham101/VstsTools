<#
.SYNOPSIS
Displays the results of the test runner

.DESCRIPTION
Displays a summary of results from the test runner and fails if a threshold is not met

.PARAMETER TestResultFile
[Optional] Path to the test results file. Will use the latest file called TEST-xxx.XML if not passed

.PARAMETER CodeCoverageFile
[Optional] Path to the test results file. Will use the latest file called CODECOVERAGE-xxx.XML if not passed

.PARAMETER CoveragePercent
[Optional] Minimum code coverage percentage to pass. Defaults to 80

.EXAMPLE
Out-TestResults.ps1

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [String] $TestResultFile,
    [Parameter(Mandatory = $false)]
    [String] $CodeCoverageFile,
    [Parameter(Mandatory = $false)]
    [int] $CoveragePercent = 80
)

if (-not $TestResultFile) {
    $FindRecentFile = Get-ChildItem -Path "$PSScriptRoot\TEST-*.xml" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    Write-Verbose "TestResultFile $($FindRecentFile.FullName)"
    $TestResultFile = $FindRecentFile.FullName
}
[xml] $TestResult = Get-Content -Path $TestResultFile


if (-not $CodeCoverageFile) {
    $FindRecentFile = Get-ChildItem -Path "$PSScriptRoot\CODECOVERAGE-*.xml" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    Write-Verbose "CodeCoverageFile $($FindRecentFile.FullName)"
    $CodeCoverageFile = $FindRecentFile.FullName
}
[xml] $CodeCoverage = Get-Content -Path $CodeCoverageFile


$Failures = Select-Xml "//test-results/test-suite[@success='False']" $TestResult
if ($Failures) {
    $NumFailures = 0
    $Failures | ForEach-Object {
        Select-Xml "//failure" $_.node.results | ForEach-Object {
            $NumFailures += 1
            Write-Output "Failure: $NumFailures"
            Write-Output $_.Node.Message
        }
    }
    Write-Error "Pester reported $NumFailures error(s)"
}


$TotalLines = 0
$CoveredLines = 0
Select-Xml  "//report/counter" $CodeCoverage | ForEach-Object {
    $TotalLines += [int] $_.Node.missed + [int] $_.Node.covered
    $CoveredLines += [int] $_.Node.covered
}

$CodeCovered = $CoveredLines / $TotalLines * 100
if ($CodeCovered -lt $CoveragePercent) {
    Write-Error "Code coverage $CodeCovered - below minimum threshold"
} else {
    Write-Output "Code coverage $CodeCovered"
}
