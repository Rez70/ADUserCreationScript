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
    https://link-to-related-docs-or-repo
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

    if (Get-ADUser -Filter "SamAccountName -eq '$($User.username)'") {
        Write-Warning "A account with the name $($User.username) already exists in Active Directory."
    }
    else {
        $ouExists = Get-ADOrganizationalUnit -identity $User.ou -ErrorAction SilentlyContinue
        
        $parentPath = $User.ou

        if (-not $ouExists) {
            $ouSplits = ($User.ou -split "," | Where-Object {$_ -notmatch "DC="}) -replace "OU=", "" | ForEach-Object {$_.Trim()}
            
            $parentPath = "DC=abhiraj,DC=local"

            foreach ($ou in $ouSplits) {
                $newOU = New-ADOrganizationalUnit -Name $ou -Path $parentPath -PassThru

                $parentPath = $newOU.DistinguishedName
            }
        }

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

    $groups = $User.groups -split ',' | ForEach-Object {$_.Trim()}

    foreach ($group in $groups) {
        $groupExists = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue

        if (-not $groupExists) {
            New-ADGroup "$group" -GroupScope Global -Path "DC=abhiraj,DC=local" -Verbose
        }

        if (Get-ADGroupMember -identity $group | Where-Object {$_.SamAccountName -eq $User.username}) {
                Write-Host "$($User.username) is already a member of $group"
        }
        else {
            Add-ADGroupMember -identity $group -Members $User.username -Verbose     
        }         
    }  
}


#Execution Code

Import-Module ActiveDirectory

if (-not(Test-Path $CSVFilePath)) { 
    Write-Error "CSV file not found in path: $CSVFilePath"
    exit
}

$ADUsers = Import-Csv $CSVFilePath

foreach($User in $ADUsers) {
    Add-NewADUser -User $User
    Add-ADUserToGroups -user $User

}