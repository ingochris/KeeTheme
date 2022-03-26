﻿# powershell v2 compatibility
$psVer = $PSVersionTable.PSVersion.Major
if ($psver -ge 3) {
	function Get-ChildItemDir {Get-ChildItem -Directory $args}
} else {
	function Get-ChildItemDir {Get-ChildItem $args}
}

$packageName = 'keepass-plugin-keetheme'
$fileName = 'KeeTheme.plgx'
$packageSearch = 'KeePass Password Safe'
$url = 'https://github.com/xatupal/KeeTheme/releases/download/v0.9.9/KeeTheme.plgx'
$checksum = 'DA77B9C2C9BF548B4E8BADFD8C7A147BBC132184EBE66CBAD4882B1B029177F0'
$checksumType = 'sha256'

function Get-KeePassPluginsPath {
	Write-Verbose "Searching registry for installed KeePass..."
	$regPath = Get-ItemProperty -Path `
		@('HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 
		  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
		  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') `
		-ErrorAction:SilentlyContinue `
		| Where-Object { `
			$_.DisplayName -like "$packageSearch*" `
			-and $_.DisplayVersion -ge 2.0 `
			-and $_.DisplayVersion -lt 3.0 `
		} `
		| ForEach-Object {$_.InstallLocation}
			 
	$installPath = $regPath

	if (! $installPath) {
		Write-Verbose "Searching $env:ChocolateyBinRoot for portable install..."
		$binRoot = Get-BinRoot
		$portPath = Join-Path $binRoot "keepass"
		$installPath = Get-ChildItemDir $portPath* -ErrorAction SilentlyContinue
	}

	if (! $installPath) {
		Write-Verbose "Searching $env:Path for unregistered install..."
		$installFullName = (Get-Command keepass -ErrorAction SilentlyContinue).Path
		if ($installFullName) {
		$installPath = [io.path]::GetDirectoryName($installFullName)
		}
	}

	if (! $installPath) {
		Write-Warning "$($packageSearch) not found."
		throw
	}

	Write-Verbose "`t...found."

	Write-Verbose "Searching for plugin directory..."
	$pluginPath = (Get-ChildItemDir $installPath\Plugin*).FullName
	if ($pluginPath.Count -eq 0) {
		$pluginPath = Join-Path $installPath "Plugins"
		[System.IO.Directory]::CreateDirectory($pluginPath)
	}
	return $pluginPath
}
