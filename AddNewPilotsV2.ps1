#Import the Active Directory module
Import-Module ActiveDirectory

#Set Error Action to stop
$errorActionPreference = "Stop"

#Location of log file
$logFile = "C:\PowerShell\AddNewPilots\AddNewPilots.log"

#Set variable for temporary password
$password = "Password1"

#Set location for CSV file
$users = Import-Csv -Path "C:\PowerShell\AddNewPilots\NewPilots.csv"

#region User Creation

#Loop that creates each user in the CSV
ForEach($user in $users){
    Try{
        #region User Variables
        $fullName = $user.Last + ", " + $user.First #user's full name
        $templateUser = Get-ADUser -Identity $user.Template -Properties Manager, Department, Title, Company #Template account to use for new user
        $templateGroups = (Get-ADUser -Identity $user.Template -Properties MemberOf).MemberOf #Template groups to use for new user
        $SAM = $user.First.Substring(0,1) + $user.Last #samAccount name
        #endregion

        #Comment log file
        Add-Content $logFile "Adding $fullName $(Get-Date)" 

        #region Test for samAccount Name
        if (Get-ADUser -Filter "SamAccountName -eq '$SAM'") {
            #Use middle initial
            $SAM = $user.First.Substring(0,1) + $user.Initials.Substring(1,1) + $user.Last
            if (Get-ADUser -Filter "SamAccountName -eq '$SAM'") {
                #Create requires manual intervention
                Add-Content $logFile  "Manually create user $($user.First) $($user.Last)" -PassThru
            }
            else {
                Add-Content $logFile "Using middle inital for user $($user.First) $($user.Last)" -PassThru
            }
        }
        else {
            #Use first inital last name
            Add-Content $logFile "Username OK"
        }
        #endregion

        #User profile name set after SAM
        $UPN = $SAM + "@star.dcu" #user profile name
        

        #region New-ADUser Parameters
        $newUserParams = @{
            Name = $fullName
            Instance = $templateUser
            Path = "OU=Pilots,OU=Star users,DC=star,DC=dcu"
            GivenName = $user.First
            Surname = $user.Last
            Initials = $user.Initials
            StreetAddress = $user.Address
            City = $user.City
            State = $user.State
            PostalCode = $user.Zip
            Country = "US"
            HomePhone = $user.HomePhone
            MobilePhone = $user.CellPhone
            Description = "Pilot"
            SamAccountName = $SAM
            userPrincipalName = $UPN
            DisplayName = $fullName
            AccountPassword = (ConvertTo-SecureString $Password -AsPlainText -Force)
            ChangePasswordAtLogon = $true
            Enabled = $true
            ErrorAction = "Stop"
        }
        #endregion

        #Create a new user with the specified parameters
        New-ADUser @newUserParams

        #Confirms creation in log file
        Add-Content $logFile "$fullName added to Active Directory"

        #Pause to be sure user is created
        Start-Sleep -Milliseconds 550
        
        #region Add Group Membership
        ForEach($group in $templateGroups){
            Try {
                Add-ADGroupMember $group -Members $SAM
            }
            Catch {
                Add-Content $logFile "Error for $fullName - $($_.Exception.Message)" -PassThru
            }    
        }
        #Confirms group addition in log file
        Add-Content $logFile "$fullName added to specified groups"
        #endregion
    }
    #region Error Catching

    #Catch unauthorized error
    Catch [System.UnauthorizedAccessException]{
        Write-Output "You must be a domain administrator to run this script."
        Break #Break to prevent looping with an error for each user
    }

    #Catch user already exists error and add to log file
    Catch [System.ServiceModel.FaultException]{
        Write-Output "User $fullName already exists." | Add-Content $logFile -PassThru
    }

    #Catch all other errors and add to log file
    Catch {
        Add-Content $logFile "Error for $fullName - $($_.Exception.Message)" -PassThru
    }
    #endregion
}
#endregion 