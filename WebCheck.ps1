##

param(
	[string]$sites=$( `
	Throw "Parameter missing: -sites <List of Sites>"),
	$url
	)

$script:ErrorActionPreference = "SilentlyContinue";

function Get-MD5([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]')) {
  $stream = $null;
  $cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider];
  $hashAlgorithm = new-object $cryptoServiceProvider
  $stream = $file.OpenRead();
  $hashByteArray = $hashAlgorithm.ComputeHash($stream);
  $stream.Close();
  ## We have to be sure that we close the file stream if any exceptions are thrown.
  trap {
    if ($stream -ne $null) {
      $stream.Close();
    }
    break;
  }
  foreach ($byte in $hashByteArray) { $result += “{0:X2}” -f $byte}
  return $result;
}

#/trap{
#/	"Failed. Details: $($_.Exception)"
#/	$emailFrom = "my.email@address.com"
#/	# Use commas for multiple addresses
#/	$emailTo = "my.email@address.com,another.admin@address.com"
#/	$subject = "PowerGUI.org down"
#/	$body = "PowerGUI web site is down. Details: $($_.Exception)"
#/	$smtpServer = "smtp.server.to.use.for.relay"
#/	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
#/	$smtp.Send($emailFrom, $emailTo, $subject, $body)
#/	exit 1
#/}

$timestamp = (Get-Date).ToString("yyyyMMddhhmmss");
$webclient = new-object System.Net.WebClient
if ($url -eq $null) {
	Import-Csv($sites) | ForEach-Object {
		$link = $_.url
		$md5 = $_.md5
		$stamp = $_.stamp
		$file = "$env:temp\$timestamp.tmp";
		$webclient.DownloadFile($link,$file)
		$hash = Get-MD5($file);
		if ($hash -ne $md5) {
			Write-Host "CHANGED `t $link `t Old Hash: $md5 `t New Hash: $hash";
			#$temp = "$env:temp\temp1.tmp";
			$temp = "websites-new.txt";
			Get-Content $sites | foreach-object {$_ -replace "$link,$md5,$stamp", "$link,$hash,$timestamp"} | Set-Content $temp
		} else {
			Write-Host "NO-CHANGE `t $link";
		}
		Remove-Item $file;
	}
} else {
		$file = "$env:temp\$timestamp.tmp";
		$webclient.DownloadFile($url,$file)
		$hash = Get-MD5($file);
		Add-Content $sites "$url,$hash,$timestamp";
		Remove-Item $file;
}

#/if ($url -eq $null) {
#/	#$path = [string]$sites;
#/	#Write-Host $path;
#/	#Remove-Item $sites;
#/	[diagnostics.process]::start("powershell", "Remove-Item $sites;").WaitForExit(3000)
#/	[diagnostics.process]::start("powershell", "Move-Item `"$env:temp\temp1.tmp`", $sites -force").WaitForExit(3000)
#/}