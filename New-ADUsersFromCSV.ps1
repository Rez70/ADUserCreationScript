<#
.SYNOPSIS
    Creates one or more Active Directory users using values from a CSV file.

.DESCRIPTION
    Takes input from a CSV file containing user information.
    Creates an account for the user(s) in Active Directory if it doesn't already exist. 
    Adds user(s) to the specified groups and OUs.
    Creates the specified groups and OUs if they don't already exist.

    The CSV File must include the following columns:
    - firstname 
    - lastname 
    - username 
    - password 
    - ou
    - department
    - groups

.PARAMETER CSVFilePath
    Specifies the full path to the CSV file containing user information.
    This parameter is mandatory.

.EXAMPLE
    PS> .\New-ADUsersFromCSV.ps1 -CSVFilePath "C:\Users\Administrator\newusers.csv"

.NOTES
    Author: Abhiraj Singh
    Created: 2026-02-04
    Version: 1.4
    Last Modified: 2026-02-13
    Change Log:
        1.0 - Initial release.
        1.1 - Implemented functionality that verifies if the specified users, groups, and OUs exist.
        1.2 - Added support for OU and group creation if they don't already exist.
        1.3 - Integrated nested OU creation.
        1.4 - Added confirmation messages


.LINK
    https://github.com/Rez70/ADUserCreationScript.git 
#>

#Parameters
param(
    [Parameter(Mandatory=$true, HelpMessage='Enter the path to the CSV file.')]
    [String]$CSVFilePath
)

#Functions

function Add-NewADUser {

    param([Parameter(Mandatory=$true)]
    [PSCustomObject]$User
    )

    # Checks if an account with the specified SamAccountName already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$($User.username)'") {
        Write-Warning "A account with the name $($User.username) already exists in Active Directory."
    }
    else {
        try {
            # Attempts to retrieve the OU by distinguished name
            $ouExists = Get-ADOrganizationalUnit -identity $User.ou -ErrorAction SilentlyContinue 
        }
        catch {
            $ouExists = $null
        }
        # Assign the specified path to a variable
        $parentPath = $User.ou
        
        # If the OU does not exist, create the OU hierarchy
        if (-not $ouExists) {
            # Splits the path, trims extra spaces, and removes the domain components and "OU=" prefix
            $ouSplits = ($User.ou -split "," | Where-Object {$_ -notmatch "DC="}) -replace "OU=", "" | ForEach-Object {$_.Trim()}
            # Reverse the order of the array
            [array]::Reverse($ouSplits)
            # Assign the domain componets of the path to a variable
            $parentPath = "DC=abhiraj,DC=local"

            
            # Iterates through each OU in $ouSplits
            foreach ($ou in $ouSplits) {
                try {
                    # Creates the missing OUs
                    $newOU = New-ADOrganizationalUnit -Name $ou -Path $parentPath -PassThru

                    # Updates the path with the new OU
                    $parentPath = $newOU.DistinguishedName
                }
                catch {
                    # If OU already exists, manually rebuild the DN and continue
                    $parentPath = "OU=$ou,$parentPath"
                }
                
            }
        }
        # Creates the new Active Directory user account
        New-ADUser `
        -Name "$($User.firstname) $($User.lastname)" `
        -SamAccountName $User.username `
        -UserPrincipalName "$($User.username)@abhiraj.local" `
        -GivenName $User.firstname `
        -surname $User.lastname `
        -DisplayName "$($User.lastname), $($User.firstname)" `
        -Path $parentPath `
        -Department $User.department `
        -AccountPassword (ConvertTo-SecureString $User.password -AsPlainText -Force) `
        -ChangePasswordAtLogon $true `
        -Enabled $true `
        -Verbose
    }
}

function Add-ADUserToGroups {

    param([Parameter(Mandatory=$true)]
    [PSCustomObject]$User
    )

    # splits the groups provided in the CSV file and trims the whitespaces
    $groups = $User.groups -split ',' | ForEach-Object {$_.Trim()}

    # Iterates through the collection of group names
    foreach ($group in $groups) {
        # Checks if the groups exists using their name
        $groupExists = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue

        # Creates the group if it doesn't exist
        if (-not $groupExists) {
            New-ADGroup "$group" -GroupScope Global -Path "DC=abhiraj,DC=local" -Verbose
        }

        # Checks if the user account is already a member of the group
        if (Get-ADGroupMember -identity $group | Where-Object {$_.SamAccountName -eq $User.username}) {
                Write-Host "$($User.username) is already a member of $group"
        }
        # Adds the user account to the group if not already a member
        else {
            Add-ADGroupMember -identity $group -Members $User.username -Verbose     
        }         
    }  
}


#Execution Code

Import-Module ActiveDirectory

# Throws an error if the CSV file path is incorrect
if (-not(Test-Path $CSVFilePath)) { 
    Write-Error "CSV file not found in path: $CSVFilePath"
    exit
}

# Assigns the CSV file path to a variable
$ADUsers = Import-Csv $CSVFilePath

# Creates an account for each user in the CSV file and assigns them to their specified groups
foreach($User in $ADUsers) {
    Add-NewADUser -User $User
    Add-ADUserToGroups -User $User

}