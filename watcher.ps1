
param (
    $configpath,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty
) # full path to json, email address


# main class handling the health check
class Watcher {

    [string] $configpath
    $Credential
    [Object] $config

    Watcher([string] $configpath, $Credential) {
        $this.configpath = $configpath # the path to the json config
        $this.Credential = $Credential # the secure input
        $this.config = Get-Content -Raw -Path $this.configpath | ConvertFrom-Json # the config as an object
    }

    start(){
        # infinite loop until system stops

        $this.get_portal_heath()
        while($true)
        {
            Write-Host "---- Running Check ----"
            $this.get_portal_heath()
            Start-Sleep $this.config.delay
        }
    }

    send_email() {
        # send a smtp email using secure credentials.
    
        $From = $this.config.smtp.from
        $To = $this.config.smtp.to
        $Subject = $this.config.smtp.subject
        $Body = $this.config.smtp.text
        $SMTPServer = $this.config.smtp.smtpserver
        $SMTPPort = $this.config.smtp.port
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $this.Credential
    }

    get_portal_heath(){
        # check the status of the portal and send an email if options are on.
        try {

            # run get request
            [string]$url = $this.config.enterpriseUrl + "/portaladmin/healthCheck?f=json"
            $response = Invoke-RestMethod -Uri $url -Method Get
            
            # check response for sucess or failure
            If ($response.status -notmatch "success"){
                Write-Host "Portal Check was a failure"
                if ($this.config.onFailure -match $true) {
                    $this.send_email()
                }
            } Else {
                
                Write-Host "Portal Check was a " $response.status
                if ($this.config.onSuccess -match $true) {
                    $this.send_email()
                }
            }
        }
        catch {
            Write-Host "Failed"
            $ErrorMessage = $_.Exception.Message
            Write-Host $ErrorMessage
        }

    }
   
}


### MAIN ###
$watcher = [Watcher]::new($configpath, $Credential)
$watcher.start()

