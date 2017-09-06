$token         = ""
$hostname      = "demo.officespacesoftware.com"
$protocol      = "https://"
$headers       = @{Authorization = "Token token="+$token}

$OUDN          = "OU=Ash,DC=fs,DC=officespacesoftware,DC=com"
$filter        = "(objectClass=user)"

$ad_Photo_Attribute = "thumbnailPhoto";
$ad_Id_Attribute = "email";

$ad_attributes = "sAMAccountName",$ad_Id_Attribute,$ad_Photo_Attribute

$apiGetEmployees = "/api/1/employees"
$apiPutEmployees = "/api/1/employees/"

#importing module for get_adusers
Import-Module ActiveDirectory

#prepare a MD5 calculator
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider;

Write-Host "Getting records from OfficeSpace"
#Get all the active employees from OfficeSpace
$employees = (Invoke-RestMethod -Uri $baseURL$apiGetEmployees -Method get -Headers $headers).response;
$employeesMap = @{};
ForEach($employee in $employees) {
    $employeesMap.add($employee.email, $employee);
}
Write-Output "Found $($employees.Count) EMPLOYEES"

Write-Host "Getting records from AD"

$OUDNsSplit = $OUDN.Split(";")
$ADusersinOU = $OUDNsSplit[0..($OUDNsSplit.count-2)] | foreach {Get-ADUser -LDAPFilter $filter -SearchScope SubTree -SearchBase $_ -Properties $ad_attributes}

Write-Host "Found $($ADusersinOU.Count) RECORDS"

Write-Host "Updating OfficeSpace"
# for each record from AD
#  compare AD.md5 with OSS.md5 image_source_fingerprint
#  if they are different then update OSS 
foreach ($ADuser in $ADusersinOU) {
    #if this employee is in OfficeSpace
    if ($employeeMap.get_item(($ADuser).$ad_Id_Attribute))
    {
        #get the OfficeSpace employee object from the map
        $employee = $employeeMap.get_item(($ADuser).$ad_Id_Attribute);
        $empId = ($employee).id;

        #get the image data from AD
        $imageDataRaw = "";
        if (($ADuser).$ad_Photo_Attribute.value) {
            $imageDataRaw = ($ADuser).$ad_Photo_Attribute.value;
        }
        elseif (($ADuser).$empPhotoAttribute) {
            $imageDataRaw = ($ADuser).$empPhotoAttribute;
        }

        #if we found image data
        if ($imageDataRaw -ne ""){

            #calculate md5 of photo in AD
            $md5hash = [System.BitConverter]::ToString($md5.ComputeHash($imageDataRaw))
            $md5hash = $md5hash -replace '-',''

            #if md5 of photo in AD does not match md5 stored in OfficeSpace
            if ($md5hash -ine $employee.image_source_fingerprint){
                $imageData = [System.Convert]::ToBase64String($imageDataRaw);

                $request = @{
                    record = @{
                        imageData = $imageData
                        }
                    }

                $JSONrequest = $request | ConvertTo-Json

                Write-Host "Updating photo for user: " $employee.client_employee_id;
                Invoke-WebRequest -Uri $baseURL$apiPutEmployees$empId -ContentType 'application/json; charset=utf-8' -Method PUT -Body $JSONrequest -Headers $headers -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null

            } #end of if the md5 hashes did not match

        } #end of if we found image data
}

Write-Host "Process completed."
