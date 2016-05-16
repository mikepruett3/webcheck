##
## System.Data.SQLite - http://sqlite.phxsoftware.com/

param(
#/	[string]$sites=$( `
#/	Throw "Parameter missing: -sites <List of Sites>"),
	$url
)

#$script:ErrorActionPreference = "SilentlyContinue";

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
[void][System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\SQLite.NET\bin\x64\System.Data.SQLite.dll")
$cn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$cn.ConnectionString = "Data Source=C:\Users\mpruett\workspace\webcheck\websites.sqlite"
$cn.Open()

$count = 0;
$ChangeID = @();
$ChangeMD5 = @();
$ChangeStamp = @();

if ($url -eq $null) {
	$cm = New-Object -TypeName System.Data.SQLite.SQLiteCommand
	$sql = "SELECT * FROM sites"
	$cm.Connection = $cn
	$cm.CommandText = $sql
	$dr = $cm.ExecuteReader()
	while ($dr.Read() -ne "") {
		$link = $dr['url']
		$md5 = $dr['md5']
		$stamp = $dr['stamp']
		$id = $dr['id']
		$file = "$env:temp\$timestamp.tmp";
		$webclient.DownloadFile($link,$file)
		$hash = Get-MD5($file);
		if ($hash -ne $md5) {
			Write-Host "CHANGED `t $link `t Old Hash: $md5 `t New Hash: $hash";
			#/Get-Content $sites | foreach-object {$_ -replace "$link,$md5,$stamp", "$link,$hash,$timestamp"} | Set-Content $temp
			if ($ChangeID.Length -eq "0") {
				$ChangeID += @($id);
				$ChangeMD5 += @($hash);
				$ChangeStamp += @($timestamp);
			} else {
				$ChangeID[$count] = $id;
				$ChangeMD5[$count] = $hash;
				$ChangeStamp[$count] = $timestamp;
			}
			$count = $count + 1;
		} else {
			Write-Host "NO-CHANGE `t $link";
		}
		Remove-Item $file;
	}
	$dr.Close();
} else {
		$file = "$env:temp\$timestamp.tmp";
		$webclient.DownloadFile($url,$file)
		$hash = Get-MD5($file);
		Add-Content $sites "$url,$hash,$timestamp";
		Remove-Item $file;
}

Write-Host $ChangeID[0];
Write-Host $ChangeID[1];
Write-Host $ChangeMD5[0];
Write-Host $ChangeMD5[1];
Write-Host $ChangeStamp[0];
Write-Host $ChangeStamp[1];

$icount = 0;
while ($icount -ne $count) {
	$sql = "UPDATE sites SET md5 = $ChangeMD5[$icount] WHERE id = $ChangeID[$icount]"
	Write-Host $sql;
	$com = New-Object -TypeName System.Data.SQLite.SQLiteCommand
	$com.Connection = $cn
	$com.CommandText = $sql
	$dr = $cm.ExecuteReader()
	$icount = $icount + 1;
}

#/$icount = 0;
#/while ($icount -ne $count) {
#/	$sql = "UPDATE sites SET stamp = $ChangeStamp[$icount] WHERE id = $ChangeID[$icount]"
#/	$cm.CommandText = $sql
#/	$dr = $cm.ExecuteReader()
#/	$icount++
#/}

$cn.Close();

#/if ($url -eq $null) {
#/	#$path = [string]$sites;
#/	#Write-Host $path;
#/	#Remove-Item $sites;
#/	[diagnostics.process]::start("powershell", "Remove-Item $sites;").WaitForExit(3000)
#/	[diagnostics.process]::start("powershell", "Move-Item `"$env:temp\temp1.tmp`", $sites -force").WaitForExit(3000)
#/}