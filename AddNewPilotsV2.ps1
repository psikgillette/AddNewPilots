Import-Module ActiveDirectory

$ErrorActionPreference = "Stop"

$logfile = "C:\PowerShell\AddNewPilots.log"

$Password = "Password1"

$Users = Import-Csv -Path "C:\PowerShell\NewPilots.csv"

ForEach($User in $Users){
    try{
        $FullName = $User.Last + ", " + $User.First
        $SAM = $User.First.Substring(0,1) + $User.Last
        $UPN = $SAM + "@star.dcu"
        $TemplateUser = Get-ADUser -Identity $User.Template -Properties Manager, Department, Description, Title, Company
        $TemplateGroups = (Get-ADUser -Identity $User.Template -Properties MemberOf).MemberOf

        Add-Content $logfile "Adding $FullName $(Get-Date)" 

        New-ADUser -Name $FullName -Instance $TemplateUser `
            -Path "OU=Pilots,OU=Star Users,DC=star,DC=dcu" `
            -GivenName $User.First -Surname $User.Last -Initials $User.Initials `
            -StreetAddress $User.Address -City $User.City -State $User.State -PostalCode $User.Zip `
            -Country US -HomePhone $User.HomePhone -MobilePhone $User.CellPhone `
            -SamAccountName $SAM -UserPrincipalName $UPN -DisplayName $FullName `
            -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
            -ChangePasswordAtLogon $true -Enabled $true -ErrorAction Stop

        Start-Sleep -Milliseconds 550

        ForEach($Group in $TemplateGroups){
            Try {
                Add-ADGroupMember $Group -Members $SAM
            }
            Catch {
                Add-Content $logfile "Error for $FullName - $($_.Exception.Message)" -PassThru
            }
        }
    }
    catch [System.UnauthorizedAccessException]{
        Write-Output "You must be a domain administrator to run this script."
    }
    catch [System.ServiceModel.FaultException]{
        Write-Output "User $FullName already exists." | Add-Content $logfile -PassThru
    }
    catch {
        Add-Content $logfile "Error for $FullName - $($_.Exception.Message)" -PassThru
    }
}