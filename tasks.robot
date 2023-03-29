*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot order website
    ${ORDERS_TABLE}  Load orders.csv
    FOR  ${ORDER}  IN  @{ORDERS_TABLE}
        Accept popup
        Fill order  ${ORDER}
        Order and create receipt pdf with preview image  ${ORDER}
        Order another robot
    END
    ZIP receipts
    [Teardown]  Close All Browsers

*** Keywords ***
Open robot order website
    Open Available Browser  url=https://robotsparebinindustries.com/#/robot-order

Accept popup
    Click Element  //button[contains(text(), 'OK')]

Download orders.csv
    Download  https://robotsparebinindustries.com/orders.csv  downloads/orders.csv  overwrite=True

Load orders.csv
    Download orders.csv
    ${ORDERS_TABLE}  Read table from CSV  downloads/orders.csv  header=True
    RETURN  ${ORDERS_TABLE}

Fill order
    [Arguments]    ${ORDER}
    Select From List By Value  //select[@name='head']  ${ORDER}[Head]
    Click Element  //input[@name='body' and @value='${ORDER}[Body]']
    Input Text  //input[contains(@placeholder, 'legs')]  ${ORDER}[Legs]
    Input Text  //input[@name='address']  ${ORDER}[Address]

Download preview image
    [Arguments]  ${file_name}
    Click Element  //button[@id='preview']
    Screenshot  //div[@id='robot-preview-image']  downloads/${file_name}.png

Order robot
    Click Element  //button[@id='order']
    ${RECEIPT_PRESENT}  Get Element Count  //div[@id='receipt']
    IF  ${RECEIPT_PRESENT} != 1
        fail  Order failed.
    END

Wait for order to succeed
    Wait Until Keyword Succeeds  10x  200ms  Order robot

Create pdf receipt
    [Arguments]    ${file_name}
    ${receipt_HTML}  Get Element Attribute  //div[@id='receipt']  outerHTML
    Html To Pdf  ${receipt_HTML}  downloads/${file_name}.pdf
    ${image_list}  Create List  downloads/${file_name}.png
    Add Files To Pdf  ${image_list}  downloads/${file_name}.pdf  append=True

Order and create receipt pdf with preview image
    [Arguments]  ${ORDER}
    Download preview image  ${ORDER}[Order number]
    Wait for order to succeed
    Create pdf receipt  ${ORDER}[Order number]

Order another robot
    Click Element  //button[@id='order-another']

ZIP receipts
    Archive Folder With Zip  folder=downloads  archive_name=${OUTPUT_DIR}/receipts.zip  include=*.pdf