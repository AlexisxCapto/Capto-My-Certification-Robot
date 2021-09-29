*** Settings ***
Documentation   This is a robot that will automate the ordering of new robots.
...             The website it will use is : https://robotsparebinindustries.com/#/robot-order
...             For the complete documentation, please follow the link: https://robocorp.com/docs/courses/build-a-robot
Library         RPA.Browser
Library         RPA.HTTP
Library         BuiltIn
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocorp.Vault.FileSecrets

*** Keywords ***
Get file location from user
    Add heading    Share your Order URL
    Add text input  message
    ...    label=Please provide the url of your order list:
    ...    placeholder=https://yourorderlisting.com/thanks.csv
    ${url}=    Run dialog
    [Return]    ${url.message}

*** Keywords ***
Show order
    [Arguments]     ${url}
    Add heading   Here is your URL
    Add text      ${url}   size=Small
    Run dialog

*** Keywords ***
Get Orders
    [Arguments]     ${url}
    Download    ${url}    overwrite=True
    ${orders}=      Read table from CSV    orders.csv
    FOR    ${row}    IN    @{orders}
    Log    ${row}
    END
    [Return]    ${orders}
    #https://robotsparebinindustries.com/orders.csv

# + active=""
#
# -

*** Keywords ***
Open the robot order website
    ${secret}=  Get secret         orderui
    Open Available Browser     ${secret}[url]
    #https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Close the annoying modal
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value     head    ${row}[Head]
    Input Text    address    ${row}[Address]
    Select Radio Button     body         ${row}[Body]
    Input Text     //input[@placeholder='Enter the part number for the legs']     ${row}[Legs]

*** Keywords ***
Preview the robot
    Click Button    preview


*** Keywords ***
Submit the order
    Click Button       order
    Wait Until Element Is Visible   id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${Order number}
    ${Receipt_in_html}=     Get Element Attribute   id:receipt      outerHTML
    ${pdf}=   Set Variable      ${CURDIR}${/}output${/}${Order number}.pdf
    Html To Pdf     ${Receipt_in_html}      ${pdf}
    [Return]   ${pdf}

***Keywords***
Take a screenshot of the robot
    [Arguments]     ${Order number}
    ${screenshot}=      Set Variable        ${CURDIR}${/}output${/}${Order number}.png
    Screenshot      id:robot-preview-image      ${screenshot}
    [Return]   ${screenshot}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    ${screenshot}
    Log    ${pdf}
    Open Pdf    ${pdf}
    ${screenshot}=    Create List    ${screenshot}
    Add Files To Pdf    ${screenshot}    ${pdf}    append=True
    Close Pdf    ${pdf}

*** Keywords ***
Go to order another robot
    Click Button       order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    myarmy.zip

*** Keywords ***
Log Out And Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=     Get file location from user
    #Show order       ${url}
    ${orders}=    Get Orders       ${url}
    Open the robot order website
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds     20x    1 sec     Submit the order
        ${pdf}=     Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=      Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file          ${screenshot}           ${pdf} 
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Log Out And Close The Browser
