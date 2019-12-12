#!/usr/bin/env bash

set -euo pipefail

supported_user_properties_list=(
    "sonar.cpd.exclusions"
    "sonar.exclusions"
    "sonar.inclusions"
    "sonar.sourceEncoding"
    "sonar.sources"
    "sonar.test.exclusions"
    "sonar.test.inclusions"
    "sonar.tests"
)

exclusions=(
    .cs
    .c .h .cc .cpp .cxx .c++ .hh .hpp .hxx .h++ .ipp .m
    .java .jav
    sql tab pkb
    .vb
)

declare -A config
declare -A supported_user_properties_map

for p in "${supported_user_properties_list[@]}"; do
    supported_user_properties_map[$p]=1
done

warn() {
    echo "[warn] $@" >&2
}

format_exclusions() {
    local work=($1)
    for v in "${exclusions[@]}"; do
        work+=("**/*$v")
    done
    local IFS=,
    echo "${work[*]}"
}

update_config_with_defaults() {
    config["sonar.sources"]=.
    config["sonar.sourceEncoding"]=UTF-8
}

update_config_from_config() {
    [[ -f .sonarcloud.properties ]] || return 0
    while read line; do
        [[ "$line" =~ ^sonar\..*= ]] || continue
        p=${line%%=*}
        p=${p% }
        v=${line##*=}
        v=${v# }
        if [[ "${supported_user_properties_map[$p]:-}" ]]; then
            config[$p]=$v
        else
            warn "unsupported config property: $p"
        fi
    done < .sonarcloud.properties
}

update_config_with_forced_values() {
    config["sonar.projectBaseDir"]=$PWD
    unset config["sonar.organization"]
    unset config["sonar.projectKey"]
    config["sonar.java.binaries"]=$PWD
    config["sonar.coverage.exclusions"]="**/*"
    config["sonar.exclusions"]=$(format_exclusions "${config["sonar.exclusions"]:-}")
    config["sonar.test.exclusions"]=$(format_exclusions "${config["sonar.test.exclusions"]:-}")
}

display_config() {
    for p in "${supported_user_properties_list[@]}"; do
        if [[ "${config[$p]:-}" ]]; then
            echo "$p = ${config[$p]}"
        fi
    done

    for p in "${!config[@]}"; do
        if ! [[ "${supported_user_properties_map[$p]:-}" ]]; then
            echo "$p = ${config[$p]}"
        fi
    done
}

update_config_with_defaults
update_config_from_config
update_config_with_forced_values
display_config | tee sonar-project.properties
