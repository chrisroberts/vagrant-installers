#!/usr/bin/env bash

function cleanup {
    vagrant destroy --force > /dev/null 2>&1
    for logfile in `ls .output-*`
    do
        guest="${logfile##output-}"
        (>&2 echo "Failed to provision: ${guest}")
        sed -i -E '/^[[:space:]]+from \//d' "${logfile}"
        output=$(tail -n 5 "${logfile}")
        (>&2 echo "${output}")
    done
}

function keepalive {
    slept=0
    while true
    do
        let slept++
        if [ $slept -gt 540 ]; then
            echo "."
            slept=0
        fi
        sleep 1
    done
}

trap cleanup EXIT

GEM_PATH=$(ls vagrant-*.gem)

set -e

if [ -f "${GEM_PATH}" ]
then
    mv "${GEM_PATH}" package/vagrant.gem
fi

vagrant box update
vagrant box prune

guests=$(vagrant status | grep vmware | awk '{print $1}')

vagrant up --no-provision

declare -A upids

if [ "${PACKET_EXEC}" == "1" ]; then
    # macos uploads
    if [ -f "MacOS_PkgSigning.cert" ]; then
        vagrant upload MacOS_PkgSigning.cert "~/" osx-10.9
        vagrant upload MacOS_PkgSigning.key "~/" osx-10.9
        export VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGN_CERT_PATH="~/MacOS_PkgSigning.cert"
        export VAGRANT_INSTALLER_VAGRANT_PACKAGE_SIGN_KEY_PATH="~/MacOS_PkgSigning.key"
    fi
    # win uploads
    if [ -f "Win_CodeSigning.p12" ]; then
        vagrant upload Win_CodeSigning.p12 "~/" win-7
        export VAGRANT_INSTALLER_SignKeyPath="C:\\Users\\vagrant\\Win_CodeSigning.p12"
    fi
fi

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} 2>&1 > .output-${guest} &
    pids[$guest]=$!
    tail --quiet --pid ${pids[$guest]} -f .output-${guest} &
    sleep 10
done

result=0

# keepalive &
# kp=$!

for guest in ${guests}
do
    wait ${pids[$guest]}
    result=$?
    if [ $result -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
    else
        echo "Provision complete for: ${guest}"
        rm .output-${guest}
    fi
done

# pkill -P $kp
# kill $kp
mkdir -p assets

if [ $result -eq 0 ]; then
    if [ "${VAGRANT_BUILD_TYPE}" = "package" ]
    then
        mv -f pkg/* assets/
    else
        mv -f substrate-assets/* assets/
    fi
fi

exit $result
