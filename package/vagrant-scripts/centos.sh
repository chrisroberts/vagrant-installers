#!/bin/sh

yum install -y nc curl zip unzip
yum groupinstall -yq "Development Tools"
gem install fpm -v '~> 0.4.0' --no-ri --no-rdoc

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"
mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/package/package.sh

/vagrant/package/package.sh /vagrant/substrate-assets/substrate_centos_$(uname -m).zip master
cp *.rpm /vagrant/pkg/
