<#
.SYNOPSIS
    Takes a food order and validates user input.

.DESCRIPTION
    Provides user with a list of food and drink items to choose from.
    Asks for the choice of food, drink, quantity, and the date of order.
    Validates user input based on a predefined set of values, pattern, or condition.
    Returns a table of the confirmed order.

.PARAMETER FoodChoice
    The food to order. Possible options: Sandwich, Chicken ,Fries, Burger, Pizza.

.PARAMETER Quantity
    Quantity of the food item from #1 to #9.

.PARAMETER Drink
    Weather the customer wants to order a drink. Possible options: yes, no.

.PARAMETER DrinkChoice
    The drink to order. Possible options: Coke, Pepsi, Water, Sprite.

.PARAMETER TimeOfOrder
    The date of when the order was placed. Must match the current date.

.EXAMPLE
    PS> .\ParameterValidation.ps1 

.NOTES
    Author: Abhiraj Singh
    Created: 2026-03-14
    Version: 1.0
    Last Modified: 2026-03-16
    Change Log:
        1.0 - Initial release
        

.LINK
    https://link-to-related-docs-or-repo
#>

#Functions

Function Validate-Input {

    [CmdletBinding()]
    Param (
    [ValidateSet('Sandwich','Chicken','Fries','Burger','Pizza',ErrorMessage = "{0} is not one of the available food options. Please choose from one of the following items: {1}")]
    [String]$FoodChoice,

    [ValidatePattern('^#[1-9]$',ErrorMessage = "{0} is not a valid numeric value preceded by '#'. Please pick a single digit number from 1-9, that matches the following pattern: {1}")]
    [String]$Quantity,

    [ValidateSet('Yes','No',ErrorMessage = "{0} is not a valid answer. Please respond with either of the following options: {1}")]
    [String]$Drink,

    [ValidateSet('Coke','Pepsi','Water','Sprite','None',ErrorMessage = "{0} is not one of the available options for drink. Please choose from one of the following items: {1}")]
    [String]$DrinkChoice,

    [ValidateScript({$_ -eq (Get-Date).Date},ErrorMessage = "The date of order, {0}, does not match the current date per the following script: {1}")]
    [DateTime]$TimeOfOrder)
    
    Process {
        if($FoodChoice -and $Quantity -and $DrinkChoice -and $TimeOfOrder) {
            [PSCustomObject]@{
            "Food" = $FoodChoice
            "Quantity" = $Quantity
            "Drink" = $DrinkChoice
        
            "Time of Order" = $TimeOfOrder
            }
        }
    }
}   

Function Get-Order {
    try {
        $FoodChoice = Read-Host "Please select a food item: `n1. Sandwich `n2. Pizza `n3. Chicken `n4. Fries `n5. Burger `n`n"
        Validate-Input -FoodChoice $FoodChoice

        $Quantity = Read-Host "`nEnter a quantity from 1-9 (e.g., #2)"
        Validate-Input -Quantity $Quantity

        $Drink = Read-Host "Would you like a Drink?"
        Validate-Input -Drink $Drink

        if ($Drink -eq "yes") {
            $DrinkChoice = Read-Host "Please select a drink: `n1. Coke `n2. Sprite `n3. Water `n4. Pepsi `n`n"
            Validate-Input -DrinkChoice $DrinkChoice
        
        }
        else {
            $DrinkChoice = "None"
            Validate-Input -DrinkChoice $DrinkChoice
        
        }

        $TimeOfOrder = Read-Host "`nEnter the date of order"
        Validate-Input -TimeOfOrder $TimeOfOrder

        Write-Output "`nThank you for your order."
        Validate-Input -FoodChoice $FoodChoice -Quantity $Quantity -DrinkChoice $DrinkChoice -TimeOfOrder $TimeOfOrder
    }
    Catch{
        $_
        exit
    }
}

#Execution Code

Get-Order