*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Collections
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}    Get orders    ${OUTPUT_DIR}${/}orders.csv
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the from    ${order}
        ${pdf}    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another Robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${save_path}
    Download    url=https://robotsparebinindustries.com/orders.csv    target_file=${save_path}    overwrite=True
    ${orders}    Read table from CSV    ${save_path}
    RETURN    ${orders}

Close the annoying modal
    Wait And Click Button    //button[normalize-space()='OK']

Fill the from
    [Arguments]    ${order}
    Select From List By Index    //select[@id='head']    ${order}[Head]
    Click Element    //label[@for='id-body-${order}[Body]']
    Press Keys    //input[@id='address']    SHIFT+TAB
    Press Keys    None    ${order}[Legs]
    Input Text    //input[@id='address']    ${order}[Address]
    Click Button    //button[@id='preview']
    Wait Until Keyword Succeeds    5 x    2 sec    Submit the form

Submit the form
    Log    "Submitting the form..."
    Click Button    //button[@id='order']
    Wait Until Element Is Visible    //h3[normalize-space()='Receipt']    timeout=2 sec

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    //div[@id='receipt']
    ${order_html}    Get Element Attribute    //div[@id='receipt']    outerHTML
    ${pdf_path}    Set Variable    ${OUTPUT_DIR}${/}order_${order_number}.pdf
    Html To Pdf    ${order_html}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    //div[@id='receipt']
    ${screenshot}    Set Variable    ${OUTPUT_DIR}${/}order_${order_number}_robot_screenshot.png
    Screenshot    //div[@id='robot-preview-image']    ${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}    Create List    ${pdf}    ${screenshot}:align=center
    Add Files To Pdf    files=${files}    target_document=${pdf}

Order another Robot
    Click Button    //button[@id='order-another']

Archive output PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}    archive_name=${OUTPUT_DIR}${/}order_receipts.zip    include=*.pdf

Close RobotSpareBin Browser
    Close Browser
