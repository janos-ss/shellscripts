#!/usr/bin/env bash
#
# Utility functions for SonarQube Web API
#
# This file is not executable. Source it and call functions.
#

require() {
    :
}

call() {
    echo "$@" >&2
    "$@"
}

curl_debug() {
    require url
    call curl -s "$url" || curl -s "$url" "$@" >&2
}

jq_debug() {
    content=$(cat)
    if ! call jq "$@" <<< "$content"; then
        jq . <<< "$content" || echo "$content"
        return 1
    fi
}

curl_and_jq() {
    if ! curl_debug | call jq "$@"; then
        curl_debug | jq . || curl_debug
        return 1
    fi
}

set_url() {
    require baseurl
    url=$baseurl/api$1
}

measures_component() {
    require baseurl || return 1
    require projectKey || return 1
    q="/measures/component?additionalFields=metrics%2Cperiods&component=$projectKey&metricKeys=alert_status%2Cquality_gate_details%2Cbugs%2Cnew_bugs%2Creliability_rating%2Cnew_reliability_rating%2Cvulnerabilities%2Cnew_vulnerabilities%2Csecurity_rating%2Cnew_security_rating%2Ccode_smells%2Cnew_code_smells%2Csqale_rating%2Cnew_maintainability_rating%2Csqale_index%2Cnew_technical_debt%2Ccoverage%2Cnew_coverage%2Cnew_lines_to_cover%2Ctests%2Cduplicated_lines_density%2Cnew_duplicated_lines_density%2Cduplicated_blocks%2Cncloc%2Cncloc_language_distribution%2Cprojects%2Cnew_lines"
    [ "${pullRequest+x}" ] && q=$q"&pullRequest=$pullRequest"
    [ "${branch+x}" ] && q=$q"&branch=$branch"
    set_url "$q"
    curl_debug
}

measures_component_new_ratings() {
    measures_component | jq_debug '.component.measures[] | select(.metric | startswith("new_")) | select(.metric | endswith("_rating"))'
}

qg_details() {
    measures_component | jq_debug '.component.measures[] | select(.metric == "quality_gate_details").value' -r | jq .
}

qg_project_status() {
    require baseurl || return 1
    require projectKey || return 1
    q="/qualitygates/project_status?projectKey=$projectKey"
    [ "${pullRequest+x}" ] && q=$q"&pullRequest=$pullRequest"
    [ "${branch+x}" ] && q=$q"&branch=$branch"
    set_url "$q"
    curl_debug | jq .
}

baseurl=http://localhost:9000
projectKey=org.sonarsource.scanner.cli:sonar-scanner-cli
