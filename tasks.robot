*** Settings ***
Documentation       Robot for downloading artifacts from the latest Control Room Process
Library    RPA.Robocorp.Vault
Library    RPA.Robocorp.Process
Library    RPA.HTTP

*** Variables ***
${workspace_id}    %{workspace_id}
${process_id}      %{process_id}

*** Tasks ***
Download Artifacts from the Latest Process Run
    ${secrets}=  Get Secret   ProcessAPI
    Set Apikey    ${secrets}[apikey]
    Set Workspace Id    ${secrets}[workspace_id]
    &{headers}=    Create Dictionary    Authorization    RC-WSKEY ${secrets}[apikey]
    ${result}=     RPA.HTTP.GET
    ...    url=https://api.eu1.robocorp.com/search-v1/workspaces/${workspace_id}/processes/${process_id}/runs?sortBy=createTs&sortOrder=desc&search=&from=0&size=1&processState=COMPL
    ...    headers=${headers}
    ${result_json}=    Evaluate    $result.json()
    ${run_id}=    Set Variable    ${result_json}[data][0][id]
    ${step_runs}=    List Process Run Work Items
    ...    process_run_id=${run_id}
    ...    process_id=${process_id}
    ...    include_data=True
    FOR    ${step_run}    IN    @{step_runs}
        ${artifacts}=    List Run Artifacts
        ...    ${step_run}[processRunId]
        ...    ${step_run}[activityRunId]
        ...    ${step_run}[processId]
        FOR    ${artifact}    IN    @{artifacts}
            ${download_url}=    Get Robot Run Artifact
            ...    ${step_run}[processRunId]
            ...    ${step_run}[activityRunId]
            ...    ${artifact}[id]
            ...    ${artifact}[fileName]
            ...    ${step_run}[processId]
            RPA.HTTP.Download
            ...    ${download_url}
            ...    target_file=${CURDIR}${/}output${/}downloaded_${artifact}[fileName]
            ...    stream=True
        END
    END