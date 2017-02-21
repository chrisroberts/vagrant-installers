#!/bin/sh

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

gem install json_pure -v '~> 1.0' --no-ri --no-rdoc
gem install puppet -v '~> 3.0' --no-ri --no-rdoc
TRAVIS=1 su vagrant -l -c 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
mkdir -p /vagrant/substrate-assets

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_darwin_x86_64.zip master
