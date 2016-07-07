# SCCM
system center configuration manager PowerShell stuff

## Invoke-ConfigurationManagerCycle
Initiate Configuration Manager Client Scan and wait for it to finish
```PowerShell
Invoke-ConfigurationManagerCycle -CycleName 'Software Update Scan Cycle'
Running Software Update Scan Cycle
Completed
```
Thanks to: <BR/>
http://mickitblog.blogspot.co.il/2016/05/initiating-sccm-actions-with.html<BR/>
https://blogs.msdn.microsoft.com/timid/2013/03/01/psh-v1-get-tail/<BR/>
https://www.systemcenterdudes.com/configuration-manager-2012-client-command-list/<BR/>

## Contributing
Just fork and send pull requests, Thank you!

## Examples
![](https://raw.githubusercontent.com/ili101/SCCM/master/Examples/Example1.png)
