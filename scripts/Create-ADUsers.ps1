$DomainDN    = "DC=TKP,DC=local"
$CsvPath     = "$PSScriptRoot\Users.csv"
$OUNames     = @("TKP", "Lavin", "Amins", "Employees", "Group")
$GroupOUName = "Group"
$GroupName   = "Group"

Import-Module ActiveDirectory -ErrorAction Stop

foreach ($ouName in $OUNames) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $DomainDN -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ouName -Path $DomainDN -ProtectedFromAccidentalDeletion $false
    }
}

$groupOuPath = "OU=$GroupOUName,$DomainDN"
if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -SearchBase $groupOuPath -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $GroupName -SamAccountName $GroupName -GroupCategory Security -GroupScope Global -Path $groupOuPath
}

$users = Import-Csv -Path $CsvPath

foreach ($u in $users) {
    $ouPath = "OU=$($u.OU),$DomainDN"
    $displayName = "$($u.FirstName) $($u.LastName)"
    $securePwd = ConvertTo-SecureString $u.Password -AsPlainText -Force

    if (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue) { continue }

    New-ADUser `
        -Name $u.SamAccountName `
        -GivenName $u.FirstName `
        -Surname $u.LastName `
        -SamAccountName $u.SamAccountName `
        -UserPrincipalName $u.UserPrincipalName `
        -DisplayName $displayName `
        -Department $u.Department `
        -Title $u.Title `
        -Company $u.Company `
        -Office $u.Office `
        -Description $u.Description `
        -Path $ouPath `
        -AccountPassword $securePwd `
        -Enabled $true `
        -ChangePasswordAtLogon $false `
        -PasswordNeverExpires $true

    if ($u.OU -eq $GroupOUName) {
        Add-ADGroupMember -Identity $GroupName -Members $u.SamAccountName
    }
}