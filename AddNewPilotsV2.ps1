#Import the Active Directory module
Import-Module ActiveDirectory

#Set Error Action to stop
$ErrorActionPreference = "Stop"

#Location of log file
$logfile = "C:\PowerShell\AddNewPilots.log"

#Set variable for temporary password
$Password = "Password1"

#Set location for CSV file
$Users = Import-Csv -Path "C:\PowerShell\NewPilots.csv"

#Loop that creates each user in the CSV
ForEach($User in $Users){
    Try{
        $FullName = $User.Last + ", " + $User.First #User's full name
        $SAM = $User.First.Substring(0,1) + $User.Last #samAccount name
        $UPN = $SAM + "@star.dcu" #User profile name
        $TemplateUser = Get-ADUser -Identity $User.Template -Properties Manager, Department, Title, Company #Template account to use for new user
        $TemplateGroups = (Get-ADUser -Identity $User.Template -Properties MemberOf).MemberOf #Template groups to use for new user

        #Comment log file
        Add-Content $logfile "Adding $FullName $(Get-Date)" 

        Create a new user with the specified parameters
        New-ADUser -Name $FullName -Instance $TemplateUser `
            -Path "OU=Pilots,OU=Star Users,DC=star,DC=dcu" `
            -GivenName $User.First -Surname $User.Last -Initials $User.Initials `
            -StreetAddress $User.Address -City $User.City -State $User.State -PostalCode $User.Zip `
            -Country US -HomePhone $User.HomePhone -MobilePhone $User.CellPhone -Description "Pilot"`
            -SamAccountName $SAM -UserPrincipalName $UPN -DisplayName $FullName `
            -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
            -ChangePasswordAtLogon $true -Enabled $true -ErrorAction Stop

        #Confirms creation in log file
        Add-Content $logfile "$FullName added to Active Directory"

        #Pause to be sure user is created
        Start-Sleep -Milliseconds 550
        
        #Loop to add groups to user
        ForEach($Group in $TemplateGroups){
            Try {
                Add-ADGroupMember $Group -Members $SAM
            }
            Catch {
                Add-Content $logfile "Error for $FullName - $($_.Exception.Message)" -PassThru
            }
        
        #Confirms group addition in log file
        Add-Content $logfile "$FullName added to specified groups"    
        }
    }
    #Catch unauthorized error
    catch [System.UnauthorizedAccessException]{
        Write-Output "You must be a domain administrator to run this script."
        Break #Break to prevent looping with an error for each user
    }
    #Catch user already exists error and add to log file
    catch [System.ServiceModel.FaultException]{
        Write-Output "User $FullName already exists." | Add-Content $logfile -PassThru
    }
    #Catch all other errors and add to log file
    catch {
        Add-Content $logfile "Error for $FullName - $($_.Exception.Message)" -PassThru
    }
}