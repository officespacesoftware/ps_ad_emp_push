$batch_url     = ""
$import_url    = ""
$token         = ""
$protocol      = "https://"
$headers       = @{Authorization = "Token token="+$token}
$OUDN          = ""
$hostname      = ""
$filter        = "(objectClass=user)"
$source        = "ActiveDirectory"
$employee_batch_url  = $protocol + $hostname + $batch_url
$employee_batch_staging_url  = $protocol + $hostname + $import_url + "/" + $source
$employee_import_url  = $protocol + $hostname + $import_url

$batchSize = 1000

#parameters and settings which are saved after defining them in the script (do not modify this block)
$EmployeeId = "sAMAccountName"
$FirstName = "givenname"
$LastName = "sn"
$Title = "title"
$WorkPhone = "telephoneNumber"
$Extension = ""
$Photo = ""
$Department = "department"
$Bio = ""
$Email = "mail"
$Udf0 = ""
$Udf1 = ""
$Udf2 = ""
$Udf3 = ""
$Udf4 = ""
$Udf5 = ""
$Udf6 = ""
$Udf7 = ""
$Udf8 = ""
$Udf9 = ""
$Udf10 = ""
$Udf11 = ""
$Udf12 = ""
$Udf13 = ""
$Udf14 = ""

#importing module with all cmdlets
Import-Module ActiveDirectory

#get current script directory
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$domainDN = (Get-ADDomain).DistinguishedName
$domain = (Get-ADDomain).DNSRoot

$OUDNsSplit = $OUDN.Split(";")
$ADusersinOU = $OUDNsSplit[0..($OUDNsSplit.count-2)] | foreach {Get-ADUser -LDAPFilter $filter -SearchScope SubTree -SearchBase $_ -Properties *}

$batches = [math]::floor($ADusersinOU.count/$batchSize) + 1
$start = 0
$end = $batchSize - 1
$batch = 1


Write-Host "Staging records..."
Invoke-WebRequest -Uri $employee_batch_staging_url -ContentType application/json -Method Delete -Headers $headers | Out-Null

Write-Host "Sending records to $employee_batch_url"
do
{
$Array = new-object system.collections.arraylist
foreach ($ADuserinOU in $ADusersinOU[$start..$end])
    {
    $imageData = ""
    if (($ADuserinOU).$Photo.value) {
      $imageData = [System.Convert]::ToBase64String(($ADuserinOU).$Photo.value)
    }
    elseif (($ADuserinOU).$Photo) {
      $imageData = [System.Convert]::ToBase64String(($ADuserinOU).$Photo)
    }

$Array.Add([PSCustomObject]@{
    "EmployeeId"= "$(($ADuserinOU).$EmployeeId)"
    "Source"= $source
    "FirstName"= "$(($ADuserinOU).$FirstName)"
    "LastName"= "$(($ADuserinOU).$LastName)"
    "Title"= "$(($ADuserinOU).$Title)"
    "WorkPhone"= "$(($ADuserinOU).$WorkPhone)"
    "Extension"= "$(($ADuserinOU).$Extension)"
    "ImageData"= $imageData
    "Department"= "$(($ADuserinOU).$Department)"
    "Bio"= "$(($ADuserinOU).$Bio)"
    "Email"= "$(($ADuserinOU).$Email)"
    "Udf0"= "$(($ADuserinOU).$Udf0)"
    "Udf1"= "$(($ADuserinOU).$Udf1)"
    "Udf2"= "$(($ADuserinOU).$Udf2)"
    "Udf3"= "$(($ADuserinOU).$Udf3)"
    "Udf4"= "$(($ADuserinOU).$Udf4)"
    "Udf5"= "$(($ADuserinOU).$Udf5)"
    "Udf6"= "$(($ADuserinOU).$Udf6)"
    "Udf7"= "$(($ADuserinOU).$Udf7)"
    "Udf8"= "$(($ADuserinOU).$Udf8)"
    "Udf9"= "$(($ADuserinOU).$Udf9)"
    "Udf10"= "$(($ADuserinOU).$Udf10)"
    "Udf11"= "$(($ADuserinOU).$Udf11)"
    "Udf12"= "$(($ADuserinOU).$Udf12)"
    "Udf13"= "$(($ADuserinOU).$Udf13)"
    "Udf14"= "$(($ADuserinOU).$Udf14)"}) | Out-Null
    }

  $JSONArray = $array | ConvertTo-Json
  $JSONArrayUTF8 = [System.Text.Encoding]::UTF8.GetBytes($JSONArray)

  try {
      Invoke-WebRequest -Uri $employee_batch_url -ContentType 'application/json; charset=utf-8' -Method Post -Body $JSONArrayUTF8 -Headers $headers -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
      $startn = $start+1;$endn = $end+1; Write-Host "$startn-$endn " -NoNewline; Write-Host "Done" -ForegroundColor Green
      }
  catch
      {
      $startn = $start+1;$endn = $end+1; Write-Host "$startn-$endn " -NoNewline; Write-Host $_.Exception.Message -ForegroundColor Red
      }

  $start+=$batchSize
  $end+=$batchSize
  $batch++
}
while ($batch -le $batches)

Write-Host "Triggering migration"
$import_url_post_body = "Source=" + $source
Invoke-WebRequest -Uri $employee_import_url -Method Post -Body $import_url_post_body -Headers $headers | Out-Null
Write-Host "Completed"
