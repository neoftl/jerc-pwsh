#
# Simple unit test framework
#

$global:PwshTest = @{
    'TestIdFilter' = $null;
    'HideSkipped'  = $false;
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

        function printResult($result, $resultColour, [bool]$clear = $false) {
            Write-Host "[" -NoNewline
            Write-Host $result -NoNewline -ForegroundColor:$resultColour
            Write-Host "] " -NoNewline
            (showTitle $clear)
            if ($clear) {
                Write-Host "$([string]::new(8, 7))" -NoNewline
            }
        }
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

        if ($Id -and $PwshTest.TestIdFilter -and -not ($Id -imatch $PwshTest.TestIdFilter)) {
            if (-not $PwshTest.HideSkipped) {
                (printResult 'SKIP' DarkGray)
                Write-Host
            }
            return
        }

        $PwshTest.TotalTestsRun += 1
        (printResult '    ' Black $true)

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

        if ($FailMessage -or $actual -ne $Expected) {
            (printResult 'FAIL' Red)
            $PwshTest.TestFailureCount += 1
        }
        else {
            (printResult 'PASS' Green)
        }
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