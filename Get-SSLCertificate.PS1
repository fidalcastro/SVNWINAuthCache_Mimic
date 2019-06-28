Param(
    [Parameter(Mandatory=$true)] [String] $ServerName = $(throw "-serverName is required."),
    [Parameter(Mandatory=$true)] [String] $Realm = $(throw "-svn realm string is required.")
)

function Error-Exit {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $errorMsg
    )
    Write-Host "ERROR: " + $errorMsg
    exit(2)
}

function MD5 {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $realm
    )

    $md5  = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($realm))) 
    $hash.replace("-","").ToLower()
}

function Get-SSLCertificate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [int]
        $Port = 443
    )

    $Certificate = $null
    $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
    try {

        $TcpClient.Connect($ComputerName, $Port)
        $TcpStream = $TcpClient.GetStream()

        $Callback = { param($sender, $cert, $chain, $errors) return $true }

        $SslStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList @($TcpStream, $true, $Callback)
        try {

            $SslStream.AuthenticateAsClient('')
            $Certificate = $SslStream.RemoteCertificate

        } finally {
            $SslStream.Dispose()
        }

    } finally {
        $TcpClient.Dispose()
    }

    if ($Certificate) {
        if ($Certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
            $Certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $Certificate
        }
        return $Certificate
    }
    return $null
}

function Create-Template {
    Param(
        [Parameter(Mandatory=$true, Position=0)] $realmStr,
        [Parameter(Mandatory=$true, Position=0)] $base64Str
     )
    $dict  = [ordered]@{
        'ascii_cert' = $base64Str; 
		'failures' = "1";
        'svn:realmstring' = $realmStr
    }
    $chunk = ""
    $dict.Keys | ForEach-Object {
        $chunk += "K "+ $_.length + "`n"
        $chunk += $_ + "`n"
        $chunk += "V " + $dict[$_].length + "`n"
        $chunk += $dict[$_] + "`n"
    }
    $chunk += "END`n"
    $filename = MD5($dict['svn:realmstring'])
    $dest_dir  = $env:APPDATA + '\Subversion\auth\svn.simple'
    $dest_file = $dest_dir + '\' + $filename
    
    New-Item -Path $dest_dir -Force -ItemType "directory" > $null
    New-Item -Path $dest_file -ItemType "file" -Force >$null
    $chunk | Out-File -Encoding ASCII -filepath $dest_file
    
    Write-Host "Successfully Imprinted the SSL cert in hash file $dest_file"
}

$sslCert = Get-SSLCertificate -ComputerName $ServerName
if(!$sslCert) { Error-Exit -errorMsg "Unable to get SSL certificate from host $computerName on Port 443 " }
$base64Str = [Convert]::ToBase64String($sslCert.GetRawCertData())

Create-Template -realmStr $realm -base64Str  $base64Str
