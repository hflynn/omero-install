#!/bin/bash

set -e -u -x

OMEROVER=omero
#OMEROVER=omerodev

source settings.env

#install httpd 2.4
yum -y install httpd24u

#Create virtual env.
virtualenv /tmp/omeroenv
set +u
source /tmp/omeroenv/bin/activate
set -u

# install omero dependencies
/tmp/omeroenv/bin/pip2.7 install pillow numpy matplotlib

# Django
/tmp/omeroenv/bin/pip2.7 install "Django<1.9"

echo source \~omero/omero-centos6py27ius.env >> ~omero/.bashrc
cp settings.env omero-centos6py27ius.env step04_centos6_py27_ius_${OMEROVER}.sh ~omero

if [ $OMEROVER = omerodev ]; then
	/tmp/omeroenv/bin/pip2.7 install omego
fi

su - omero -c "bash -eux step04_centos6_py27_ius_${OMEROVER}.sh"

cp settings.env ~omero

cp setup_omero_apache24.sh ~omero
su - omero -c "bash -eux setup_omero_apache24.sh"

# cannot use python27-mod_wsgi from ius since httpd2.2 is a dependency
# install via pip.
/tmp/omeroenv/bin/pip2.7 install mod_wsgi-httpd
/tmp/omeroenv/bin/pip2.7 install mod_wsgi

# See setup_omero_apache.sh for the apache config file creation
cp ~omero/OMERO.server/apache.conf.tmp /etc/httpd/conf.d/omero-web.conf

# create wsgi.conf file
cat << EOF > /etc/httpd/conf.d/wsgi.conf
LoadModule wsgi_module /tmp/omeroenv/lib64/python2.7/site-packages/mod_wsgi/server/mod_wsgi-py27.so
EOF

chkconfig httpd on
service httpd start
bash -eux step07_all_perms.sh