param(
	$String
	)
	
$String = $String -replace "5","a"
$String = $String -replace "6","b"
$String = $String -replace "7","c"
$String = $String -replace "8","d"
$String = $String -replace "9","e"

Write-Host "`n$String";