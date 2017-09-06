$token         = ""
$hostname      = "demo.officespacesoftware.com"
$protocol      = "https://"
$headers       = @{Authorization = "Token token="+$token}

$OUDN          = "OU=Ash,DC=fs,DC=officespacesoftware,DC=com"
$filter        = "(objectClass=user)"

$ad_attributes = "SAMAccountName","email", "jpegPhoto", "thumbnailPhoto"

#importing module with all cmdlets
Import-Module ActiveDirectory

Write-Host "Getting records from OfficeSpace"

Write-Host "Getting records from AD"

$OUDNsSplit = $OUDN.Split(";")
$ADusersinOU = $OUDNsSplit[0..($OUDNsSplit.count-2)] | foreach {Get-ADUser -LDAPFilter $filter -SearchScope SubTree -SearchBase $_ -Properties $ad_attributes}

Write-Host "Updating OfficeSpace"
# for each record from AD
#  compare AD.md5 with OSS.md5
#  if they are different then update OSS
Write-Host "Process completed."


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
    "StartDate"= "$(($ADuserinOU).$StartDate)"
    "EndDate"= "$(($ADuserinOU).$EndDate)"
    "ShowInVd"= "$(($ADuserinOU).$ShowInVd)"
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
    "Udf14"= "$(($ADuserinOU).$Udf14)"
    "Udf15"= "$(($ADuserinOU).$Udf15)"
    "Udf16"= "$(($ADuserinOU).$Udf16)"
    "Udf17"= "$(($ADuserinOU).$Udf17)"
    "Udf18"= "$(($ADuserinOU).$Udf18)"
    "Udf19"= "$(($ADuserinOU).$Udf19)"
    "Udf20"= "$(($ADuserinOU).$Udf20)"
    "Udf21"= "$(($ADuserinOU).$Udf21)"
    "Udf22"= "$(($ADuserinOU).$Udf22)"
    "Udf23"= "$(($ADuserinOU).$Udf23)"
    "Udf24"= "$(($ADuserinOU).$Udf24)"}) | Out-Null
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
