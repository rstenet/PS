### Really fast PowerShell function for scanning IPv4 TCP ports.

There are other PS scripts pretending to be fast and to some extend they are, compared to the simple one-liner.

```
1..1000 | % {echo ((new-object Net.Sockets.TcpClient).Connect("localhost",$_)) "Port $_ is open!"} 2>$null
```

If all the ports are open this will be fast, too. But normally the example above will run for more than half an hour, because of the 2 seconds default timeout of TcpClient.Connect.

To overcome this some like [securethelogs/PSpanner](https://github.com/securethelogs/PSpanner) are using timeouts. Others are like [BornToBeRoot/PowerShell_IPv4PortScanner](https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner) are using multithreading.

Here both techniques are combined.  
Additional to that the RunspacePool jobs are created and checked in chunks equal to the parallelism chosen. This minimizes the RAM used.

Speed and RAM comparison.  
Scanning all ports on localhost whit PowerShell_IPv4PortScanner takes 14 minutes and RAM usage goes up to 1.5 GB.  
Scanning all ports with this one takes less than 2 minutes and RAM usage peaks to 250 MB. The results are displayed after each chunk, not at the end.

#### Syntax
```
Scan-Ports [[-Dest] <String>] [[-StartPort] <Int32>] [[-EndPort] <Int32>] [[-timeout] <Int32>] [[-parallel] <Int32>] [<CommonParameters>]
```

#### Example
###### Get the function

```PowerShell
PS: > iex(New-Object Net.WebClient).DownloadString(‘https://raw.githubusercontent.com/rstenet/PS/main/IPv4_TCP_PortScanner/Scan-Ports.ps1’)
```

###### Run it

```PowerShell
PS: > Scan-Ports -Dest localhost -Endport 1000

 Scanning port range 1 -> 1000 on host localhost
 with 250 threads and 100 miliseconds timeout

  80
  135
  445
  623
  902
  912

 Scanning done. 6 open ports found.
 Scanned 1000 ports in 2.3920256 seconds
```

#### Speed comparison over 1000 ports

https://user-images.githubusercontent.com/6967134/125607491-184ea9cf-000f-4124-93ff-733642de53dd.mp4


