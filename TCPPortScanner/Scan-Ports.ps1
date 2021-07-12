<#
.EXAMPLE
    Scan-Ports -Dest 10.10.10.100 -StartPort 1000 -EndPort 2000 -timeout 500 -parralel 25
.EXAMPLE
    Scan-Ports 10.10.10.100 1000 2000 500 25
#>

    [CmdletBinding()]
	Param(
        # Destination to scan - hostname ot IP. Default localhost.
		    [string]$Dest      = 'localhost',

        # Start Port. Default 1.
            [ValidateRange(1,65535)]
		    [int]$StartPort = 1,

        # Start Port. Default 65535.
            [ValidateRange(1,65535)]
            [ValidateScript({
                if($_ -lt $StartPort)
                {
                    throw "Invalid Port-Range!"
                }
                else 
                {
                    return $true
                }
            })]
		    [int]$EndPort   = 65535,

        # Timeout in miliseconds. Default 100.
            [ValidateRange(1,2000)]
    		[int]$timeout   = 100,

        # Parralel tests. Default 250.
		    [int]$parallel  = 250
	)

    If ($parallel -gt ($EndPort - $StartPort + 1) ) {$parallel = ($EndPort - $StartPort + 1)}
	
	Write-Host "`n Scanning port range $StartPort -> $EndPort on host $Dest `n"

	$Scriptblock = {
		param($port, [string]$ip , $timeout )
		$tcpclient = New-Object -TypeName system.Net.Sockets.TcpClient
		$iar = $tcpclient.BeginConnect($ip,$port,$null,$null)
		$wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
		if(!$wait){ 
			$tcpclient.Close()
            echo "closed" 
		}
		else{
            # mitigate false positive
            if($tcpclient.Client.Connected){
                echo "opened"
            } else {
                echo "closed"
            }

			$null = $tcpclient.EndConnect($iar)
            $tcpclient.Close()
             
		}
	}
	
	$ccs   = $StartPort
	$cce   = $StartPort + $parallel - 1
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $parallel)
	$RunspacePool.Open()
	$List = New-Object System.Collections.ArrayList
	$cnt = 0

	while($EndPort -ge $cce -And $cce -ge $ccs ){
		Write-Host "`r Scanning ports:  $ccs - $cce" –NoNewline
		$ccs..$cce | % {
			$PowerShell = [powershell]::Create()
			$PowerShell.RunspacePool = $RunspacePool 
			$PowerShell.AddScript($Scriptblock).AddArgument($_)
			$PowerShell.AddArgument($Dest).AddArgument($timeout)
			$List.Add(([pscustomobject]@{
				Id = $_
				PowerShell = $PowerShell
				Handle = $PowerShell.BeginInvoke()
			}))
		} | out-null

		0..($List.Count-1) | % {
			if( $List[$_].PowerShell.EndInvoke($List[$_].Handle) -eq 'opened' ) { 
				Write-Host "`r  $($List[$_].Id)                        " 
                Write-Host "`r Scanning ports:  $ccs - $cce" –NoNewline
				$cnt++
			}
            $List[$_].PowerShell = $null
            $List[$_].Handle = $null
		}

		$ccs += $parallel
		$cce += $parallel
		$List.Clear()
		if ($cce -gt $EndPort) {$cce = $EndPort}
	}
	Write-Host "`r                                         "
	Write-Host " Scanning done. $cnt open ports found. `n" 
	$RunspacePool.Close()
