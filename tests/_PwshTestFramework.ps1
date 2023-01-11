#
# Simple unit test framework
#

$global:PwshTest = @{
    'ThrowExceptions' = $false;
    'TotalTestsRun'    = 0;
    'TestFailureCount' = 0;
    'CurrentSuite'     = $null;
    'RunSuite'            = {
        param ([string]$Title, $Tests)
        $PwshTest.CurrentSuite = $Title
        (&$Tests)
        $PwshTest.CurrentSuite = $null
    };
    'Run'              = {
        param ([string]$Id, [string]$Title, $Expected, $TestLogic, [string]$FailMessage = $null)

        function showTitle([bool]$clear = $false) {
            $len = 0
            if ($PwshTest.CurrentSuite) {
                $len += $PwshTest.CurrentSuite.Length
                Write-Host $PwshTest.CurrentSuite -NoNewline -ForegroundColor White
                if ($Id) {
                    $len += $Id.Length + 1
                    Write-Host " $Id" -NoNewline
                }
                $len += 2
                Write-Host ': ' -NoNewline
            }
            $len += $Title.Length
            Write-Host $Title -NoNewline
            if ($clear) {
                Write-Host "$([string]::new(8, $len))" -NoNewline
            }
        }

        $PwshTest.TotalTestsRun += 1
        Write-Host "[    ] " -NoNewline
        (showTitle $true)
        Write-Host "$([string]::new(8, 7))" -NoNewline

        try {
            $actual = (&$TestLogic)
        }
        catch {
            if ($PwshTest.ThrowExceptions) {
                Write-Host
                throw
            }
            $FailMessage = $Error[0]
        }

        Write-Host "[" -NoNewline
        if ($FailMessage -or $actual -ne $Expected) {
            Write-Host "FAIL" -NoNewline -ForegroundColor Red
            $PwshTest.TestFailureCount += 1
        }
        else {
            Write-Host "PASS" -NoNewline -ForegroundColor Green
        }
        Write-Host "] " -NoNewline
        (showTitle)
        if ($FailMessage) {
            Write-Host ": " -NoNewline
            Write-Host $FailMessage -ForegroundColor Red
        }
        elseif ($actual -ne $Expected) {
            Write-Host
            Write-Host "  - Expected: $Expected" -ForegroundColor DarkYellow
            Write-Host "  -   Actual: $actual" -ForegroundColor DarkYellow
        }
        else {
            Write-Host " $actual" -ForegroundColor DarkGray
        }
    };
    'ShowSummary'      = {
        Write-Host "`r`nTest run summary:"
        Write-Host "    Number of test run: $($PwshTest.TotalTestsRun)"
        if ($PwshTest.TestFailureCount -gt 0) {
            Write-Host "    Number of test failures: $($PwshTest.TestFailureCount)" -ForegroundColor Red
        } else {
            Write-Host "    Number of test failures: 0"
            Write-Host "All tests passed." -ForegroundColor Green
        }
    };
}