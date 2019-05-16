#!/usr/bin/env bash

function cleanup {
    vagrant destroy --force > /dev/null 2>&1
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
    for guest in ${guests}
    do
        vagrant upload ${guest} . /vagrant | tee .output-${guest} &
        upids[$guest]=$!
    done

    for guest in ${guests}
    do
        wait ${upids[$guest]}
        if [ $? -ne 0 ]; then
            echo "Upload failed to guest: ${guest}"
            cat .output-${guest}
            exit 1
        else
            echo "Upload to guest ${guest} complete"
        fi
    done
fi

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} 2>&1 | tee .output-${guest} &
    pids[$guest]=$!
    sleep 10
done

result=0

keepalive &
kp=$!

for guest in ${guests}
do
    wait ${pids[$guest]}
    if [ $? -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
        result=1
    else
        echo "Provision complete for: ${guest}"
        rm .output-${guest}
    fi
done

pkill -P $kp
kill $kp

if [ $result -eq 0 ]; then
    mkdir -p assets

    if [ "${VAGRANT_BUILD_TYPE}" = "package" ]
    then
        mv -f pkg/* assets/
    else
        mv -f substrate-assets/* assets/
    fi
else
    for logfile in `ls .output-*`
    do
        guest=$(echo "${logfile}" | sed 's/.output-//')
        (>&2 echo "Failed to provision: ${guest}")
        output=$(cat "${logfile}" | sed -E '/^[[:space:]]+from \//d' | tail -n 5)
        (>&2 echo "${output}")
    done
fi

exit $result
