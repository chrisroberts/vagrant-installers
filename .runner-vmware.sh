#!/usr/bin/env bash

function cleanup {
    vagrant destroy --force > /dev/null 2>&1
}

trap cleanup EXIT

GEM_PATH=$(ls vagrant-*.gem)

set -ex

if [ -f "${GEM_PATH}" ]
then
    mv "${GEM_PATH}" package/vagrant.gem
fi

vagrant box update
vagrant box prune

guests=$(vagrant status | grep vmware | awk '{print $1}')

vagrant up --no-provision

set +e
declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} 2>&1 | tee .output-${guest} &
    pids[$guest]=$!
    sleep 10
done

result=0


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
