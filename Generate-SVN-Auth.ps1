Param(
    [Parameter(Mandatory=$true)] [String] $username = $(throw "-username is required."),
    [Parameter(Mandatory=$true)] [String] $password = $(throw "-password is required."),
    [Parameter(Mandatory=$true)] [String] $realm = $(throw "-svn realm string is required."),
    [String] $exec = 'D:\tools\svn-auto\SVNWinAuthMimic.exe'
)

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

function Error-Exit {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [String] $errorMsg
    )
    Write-Host "ERROR: " + $errorMsg
    exit(2)
}

function Create-Template {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        $base64Str
     )
    $dict  = [ordered]@{
        'ascii_cert' = $base64Str; 
		'failures' = "1";
        'svn:realmstring' = 'https://' $; 
        'username' = $username;
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
    $dest_dir  = $env:APPDATA + '/Subversion/auth/svn.simple'
    $dest_file = $dest_dir + '/' + $filename
    
    New-Item -Path $dest_dir -Force -ItemType "directory" > $null
    New-Item -Path $dest_file -ItemType "file" -Force >$null
    $chunk | Out-File -Encoding ASCII -filepath $dest_file
}

# Testing the existence of SVNWinAuthMimic
if(!(Test-Path -Path $exec)) { Error-Exit "Executable $exec is not found" }

$crypted = & $exec "encrypt" $password 2>&1
if(!$?) { Write-Host $crypted; Error-Exit "Failure while execution of $exec." }

Create-Template($crypted)
