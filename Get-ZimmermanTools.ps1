<#
.SYNOPSIS
    This script will discover and download all available programs from https://ericzimmerman.github.io and download them to $Dest. By default, ONLY .net 6 builds are downloaded.
.DESCRIPTION
    A file will also be created in $Dest that tracks the signature of each file, so rerunning the script will only download new versions. To redownload, remove lines from or delete the CSV file created under $Dest and rerun.
.PARAMETER Dest
    The path you want to save the programs to.
.PARAMETER NetVersion
    Which .net version to get. Default is ONLY net 6.0 builds as of 2023-05-18. Specify 4 or 6 to only get tools built against that version of .net, or 0 for both
.EXAMPLE
    C:\PS> Get-ZimmermanTools.ps1 -Dest c:\tools
    Downloads/extracts and saves details about programs to c:\tools directory.
.NOTES
    Author: Eric Zimmerman
    Date:   January 22, 2022    
#>

[CmdletBinding(DefaultParameterSetName = "NoProxy")]
Param
(
	[Parameter()]
	[string]$Dest = (Resolve-Path "."),
	#Where to save programs to
	[Parameter()]
	[int]$NetVersion = (6),
	#Which version of .net build to get
	#Specifies a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
	[Parameter(Mandatory = $true,
			   ParameterSetName = "ProxyAlone")]
	[Parameter(Mandatory = $true,
			   ParameterSetName = "ProxyWithCreds")]
	[Parameter(Mandatory = $true,
			   ParameterSetName = "ProxyDefaultCreds")]
	[string]$Proxy,
	#Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter.
	#Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
	#This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
	[Parameter(Mandatory = $true,
			   ParameterSetName = "ProxyWithCreds")]
	[pscredential]$ProxyCredential,
	#Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.
	#This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
	[Parameter(Mandatory = $true,
			   ParameterSetName = "ProxyDefaultCreds")]
	[switch]$ProxyUseDefaultCredentials
	
)


function Write-Color
{
    <#
	.SYNOPSIS
        Write-Color is a wrapper around Write-Host.
        It provides:
        - Easy manipulation of colors,
        - Logging output to file (log)
        - Nice formatting options out of the box.
	.DESCRIPTION
        Author: przemyslaw.klys at evotec.pl
        Project website: https://evotec.xyz/hub/scripts/write-color-ps1/
        Project support: https://github.com/EvotecIT/PSWriteColor
        Original idea: Josh (https://stackoverflow.com/users/81769/josh)
	.EXAMPLE
    Write-Color -Text "Red ", "Green ", "Yellow " -Color Red,Green,Yellow
    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
					"Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan
    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
                    "Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan -StartTab 3 -LinesBefore 1 -LinesAfter 1
    .EXAMPLE
	Write-Color "1. ", "Option 1" -Color Yellow, Green
	Write-Color "2. ", "Option 2" -Color Yellow, Green
	Write-Color "3. ", "Option 3" -Color Yellow, Green
	Write-Color "4. ", "Option 4" -Color Yellow, Green
	Write-Color "9. ", "Press 9 to exit" -Color Yellow, Gray -LinesBefore 1
    .EXAMPLE
	Write-Color -LinesBefore 2 -Text "This little ","message is ", "written to log ", "file as well." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt" -TimeFormat "yyyy-MM-dd HH:mm:ss"
	Write-Color -Text "This can get ","handy if ", "want to display things, and log actions to file ", "at the same time." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt"
    .EXAMPLE
    # Added in 0.5
    Write-Color -T "My text", " is ", "all colorful" -C Yellow, Red, Green -B Green, Green, Yellow
    wc -t "my text" -c yellow -b green
    wc -text "my text" -c red
    .NOTES
        Additional Notes:
        - TimeFormat https://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
    #>
	[alias('Write-Colour')]
	[CmdletBinding()]
	param (
		[alias ('T')]
		[String[]]$Text,
		[alias ('C', 'ForegroundColor', 'FGC')]
		[ConsoleColor[]]$Color = [ConsoleColor]::White,
		[alias ('B', 'BGC')]
		[ConsoleColor[]]$BackGroundColor = $null,
		[alias ('Indent')]
		[int]$StartTab = 0,
		[int]$LinesBefore = 0,
		[int]$LinesAfter = 0,
		[int]$StartSpaces = 0,
		[alias ('L')]
		[string]$LogFile = '',
		[Alias('DateFormat', 'TimeFormat')]
		[string]$DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
		[alias ('LogTimeStamp')]
		[bool]$LogTime = $true,
		[int]$LogRetry = 2,
		[ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')]
		[string]$Encoding = 'Unicode',
		[switch]$ShowTime,
		[switch]$NoNewLine
	)
	$DefaultColor = $Color[0]
	if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count)
	{
		Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
		return
	}
	#if ($Text.Count -eq 0) { return }
	if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host -Object "`n" -NoNewline } } # Add empty line before
	if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host -Object "`t" -NoNewline } } # Add TABS before text
	if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host -Object ' ' -NoNewline } } # Add SPACES before text
	if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
	if ($Text.Count -ne 0)
	{
		if ($Color.Count -ge $Text.Count)
		{
			# the real deal coloring
			if ($null -eq $BackGroundColor)
			{
				for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
			}
			else
			{
				for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
			}
		}
		else
		{
			if ($null -eq $BackGroundColor)
			{
				for ($i = 0; $i -lt $Color.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
				for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
			}
			else
			{
				for ($i = 0; $i -lt $Color.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
				for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
			}
		}
	}
	if ($NoNewLine -eq $true) { Write-Host -NoNewline }
	else { Write-Host } # Support for no new line
	if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } } # Add empty line after
	if ($Text.Count -and $LogFile)
	{
		# Save to file
		$TextToFile = ""
		for ($i = 0; $i -lt $Text.Length; $i++)
		{
			$TextToFile += $Text[$i]
		}
		$Saved = $false
		$Retry = 0
		Do
		{
			$Retry++
			try
			{
				if ($LogTime)
				{
					"[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
				}
				else
				{
					"$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
				}
				$Saved = $true
			}
			catch
			{
				if ($Saved -eq $false -and $Retry -eq $LogRetry)
				{
					$PSCmdlet.WriteError($_)
				}
				else
				{
					Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
				}
			}
		}
		Until ($Saved -eq $true -or $Retry -ge $LogRetry)
	}
}

#Setup proxy information for Invoke-WebRequest
[hashtable]$IWRProxyConfig = @{ }

if ($Proxy)
{
	$IWRProxyConfig.Add("Proxy", $Proxy)
}
if ($ProxyCredential)
{
	$IWRProxyConfig.Add("ProxyCredential", $ProxyCredential)
}
if ($ProxyUseDefaultCredentials)
{
	$IWRProxyConfig.Add("ProxyUseDefaultCredentials", $true)
}


Write-Color -LinesBefore 1 "This script will discover and download all available programs" -BackgroundColor Blue
Write-Color "from https://ericzimmerman.github.io and download them to $Dest" -BackgroundColor Blue -LinesAfter 1
Write-Color "A file will also be created in $Dest that tracks the signature of each file,"
Write-Color "so rerunning the script will only download new versions."
Write-Color -LinesBefore 1 -Text "To redownload, remove lines from or delete the CSV file created under $Dest and rerun. Enjoy!"

Write-Color -LinesBefore 1 -Text "Use -NetVersion to control which version of the software you get (4 or 6). Default is 6. Use 0 to get both" -LinesAfter 1 -BackgroundColor Green

$TestColor = (Get-Host).ui.rawui.ForegroundColor
if ($TestColor -eq -1 -or $null -eq $TestColor)
{
	$defaultColor = [ConsoleColor]::Gray
}
else
{
	$defaultColor = $TestColor
}

$newInstall = $false

if (!(Test-Path -Path $Dest))
{
	Write-Color -Text "* ", "$Dest does not exist. Creating..." -Color Green, $defaultColor
	New-Item -ItemType directory -Path $Dest > $null
	
	$newInstall = $true
}

$URL = "https://raw.githubusercontent.com/EricZimmerman/ericzimmerman.github.io/master/index.md"

$WebKeyCollection = @()

$localDetailsFile = Join-Path $Dest -ChildPath "!!!RemoteFileDetails.csv"

if (Test-Path -Path $localDetailsFile)
{
	Write-Color -Text "* ", "Loading local details from '$Dest'..." -Color Green, $defaultColor
	$LocalKeyCollection = Import-Csv -Path $localDetailsFile
}

$toDownload = @()

#Get zips
$progressPreference = 'silentlyContinue'
$PageContent = (Invoke-WebRequest @IWRProxyConfig -Uri $URL -UseBasicParsing).Content
$progressPreference = 'Continue'

$regex = [regex] '(?i)\b(https)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%=~_|$].(zip|txt)'
$matchdetails = $regex.Match($PageContent)


$uniqueUrlhash = @{ }


Write-Color -Text "* ", "Getting available programs..." -Color Green, $defaultColor
$progressPreference = 'silentlyContinue'
while ($matchdetails.Success)
{
	$newUrl = $matchdetails.Value.Replace('https://f001.backblazeb2.com/file/EricZimmermanTools/', 'https://download.mikestammer.com/')

	
	if ($newUrl.EndsWith('All.zip'))
	{
		$matchdetails = $matchdetails.NextMatch()
		continue
	}
	
	if ($newUrl.EndsWith('All_6.zip'))
	{
		$matchdetails = $matchdetails.NextMatch()
		continue
	}
	
	
	if ($uniqueUrlhash.Contains($newUrl))
	{
		$matchdetails = $matchdetails.NextMatch()
		continue
	}
	
	#Write-Host $newUrl
	
	$uniqueUrlhash.Add($newUrl, $newUrl)
	
	$isnet6 = $false
	
	if ($NetVersion -eq 4)
	{
		if (!$newUrl.EndsWith("Get-ZimmermanTools.zip") -and $newUrl.Contains('/net6/'))
		{
			$matchdetails = $matchdetails.NextMatch()
			continue
		}
	}
	
	if ($NetVersion -eq 6)
	{
		if (!$newUrl.EndsWith("Get-ZimmermanTools.zip") -and !$newUrl.Contains('/net6/'))
		{
			$matchdetails = $matchdetails.NextMatch()
			continue
		}
	}
	
	$isnet6 = $newUrl.Contains('/net6/')
	
	#Write-Host $newUrl
	
	$headers = (Invoke-WebRequest @IWRProxyConfig -Uri $newUrl -UseBasicParsing -Method Head).Headers

	#Write-Host $headers
	
	#Check if net version is set and act accordingly
	#https://f001.backblazeb2.com/file/EricZimmermanTools/AmcacheParser.zip
	#https://f001.backblazeb2.com/file/EricZimmermanTools/net6/AmcacheParser_6.zip
	
	#$newUrl = $matchdetails.Value.Replace('https://f001.backblazeb2.com/file/EricZimmermanTools', 'https://download.mikestammer.com/')

	#Write-Host 'THIS IS ' + $newUrl

	$getUrl = $newUrl
	#$sha = $headers["x-bz-content-sha1"]
	$sha = $headers["ETag"]
	#$name = $headers["x-bz-file-name"]
	$name = ([uri]$getUrl).Segments[-1]

	
	if ($isnet6)
	{
		$name = Split-Path $name -leaf
	}
	
	$size = $headers["Content-Length"]
	
	$details = @{
		Name = [string]$name
		SHA1 = [string]$sha
		URL  = [string]$getUrl
		Size = [string]$size
		IsNet6 = [bool]$isnet6
	}
	
	$webKeyCollection += New-Object PSObject -Property $details
	
	$matchdetails = $matchdetails.NextMatch()
}
$progressPreference = 'Continue'

Foreach ($webKey in $webKeyCollection)
{
	if ($newInstall)
	{
		$toDownload += $webKey
		continue
	}
	
	$localFile = $LocalKeyCollection | Where-Object { $_.URL -eq $webKey.URL }
	
	if ($null -eq $localFile -or $localFile.SHA1 -ne $webKey.SHA1)
	{
		#Needs to be downloaded since SHA is different or it doesnt exist
		$toDownload += $webKey
	}
}

if ($toDownload.Count -eq 0)
{
	Write-Color -LinesBefore 1 -Text "* ", "All files current. Exiting." -Color Green, Blue -LinesAfter 1
	return
}

$downloadedOK = @()

$destFile = ""
$name = ""

$i = 0
$dlCount = $toDownload.Count
Write-Color -Text "* ", "Files to download: $dlCount" -Color Green, $defaultColor
foreach ($td in $toDownload)
{
	$p = [math]::round(($i/$toDownload.Count) * 100, 2)
	
	#Write-Host ($td | Format-Table | Out-String)
	
	$tempDest = $Dest
	
	try
	{
		$dUrl = $td.URL
		$size = $td.Size -as [long]
		$name = $td.Name
		$is6 = $td.IsNet6
		
		if ($is6)
		{
			$tempDest = Join-Path $tempDest "net6"
			if (!(Test-Path -Path $tempDest))
			{
				Write-Color -Text "* ", "$tempDest does not exist. Creating..." -Color Green, $defaultColor
				New-Item -ItemType directory -Path $tempDest > $null
			}
		}
		
		Write-Progress -Activity "Updating programs...." -Status "$p% Complete" -PercentComplete $p -CurrentOperation "Downloading $name"
		$destFile = [IO.Path]::Combine($tempDest, $name)
		
		$progressPreference = 'silentlyContinue'
		Invoke-WebRequest @IWRProxyConfig -Uri $dUrl -OutFile $destFile -ErrorAction:Stop -UseBasicParsing
		
		$extraInfo = ""
		if ($is6)
		{
			$extraInfo = " (net 6)"
		}
		
		$sizeNice = '{0:N0}' -f $size
		
		Write-Color -Text "* ", "Downloaded $name (Size: $sizeNice)", $extraInfo -Color Green, Blue, Red
		
		if ($name.endswith("zip"))
		{
			
			Microsoft.PowerShell.Archive\Expand-Archive -Path $destFile -DestinationPath $tempDest -Force
		}
		
		$downloadedOK += $td
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Color -Text "* ", "Error downloading $name ($ErrorMessage). Wait for the run to finish and try again by repeating the command" -Color Green, Red
	}
	finally
	{
		$progressPreference = 'Continue'
		if ($name.endswith("zip"))
		{
			remove-item -Path $destFile
		}
		
	}
	$i += 1
}

#Write-Host ($webKeyCollection | Format-Table | Out-String)

#Downloaded ok contains new stuff, but we need to account for existing stuff too
foreach ($webItems in $webKeyCollection)
{
	#Check what we have locally to see if it also contains what is in the web collection
	$localFile = $LocalKeyCollection | Where-Object { $_.SHA1 -eq $webItems.SHA1 }
	
	#if its not null, we have a local file match against what is on the website, so its ok
	
	if ($null -ne $localFile)
	{
		#consider it downloaded since SHAs match
		$downloadedOK += $webItems
	}
}


Write-Color -LinesBefore 1 -Text "* ", "Saving downloaded version information to $localDetailsFile" -Color Green, $defaultColor -LinesAfter 1

$downloadedOK | export-csv -Path $localDetailsFile
