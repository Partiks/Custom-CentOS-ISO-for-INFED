read -p "Enter entitlement (Your institution website URL)(ex: inflibnet.ac.in): " entitlement
sed -i.bak 's/<dc:Value><\/dc:Value>/<dc:Value>$entitlement<\/dc:Value>/g' /opt/shibboleth-idp/conf/attribute-resolver.xml
read -p "Do you want to setup your organization's LDAP server (first time LDAP creation?\n(Make sure your institute does not have a LDAP server setup)" choice
( echo $choice | egrep -q '(YES|yes|y|1|Yes)' ) && flag=0 || flag=1
[ $flag -eq 1 ]    && echo "Not setting up LDAP server...." && exit 0;
mkdir /var/log/slapd
echo "local4.*                        /var/log/slapd/slapd.log" >> /etc/rsyslog.conf
yum --nogpgcheck localinstall *.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall apr.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall apr-util.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall libzip.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall mailcap.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall httpd.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall mod_ssl.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall httpd-tools.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall php-common.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall php-cli.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall php.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall php-ldap.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt

yum --nogpgcheck localinstall cyrus-sasl-devel.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall unixODBC.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall openldap-devel.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall openldap-servers.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall openldap-servers-sql.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall openldap-clients.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall migrationtools.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
yum --nogpgcheck localinstall nfs-utils.rpm -y --disablerepo=base,extras,updates >> /infedFiles/yumpackageLogs.txt
read -sp "Create a LDAP root password for administration purpose: " rootPW
echo $rootPW > /infedFiles/ldapcredentials.txt
slappasswd -T /infedFiles/ldapcredentials.txt | tee /infedFiles/encryptedldapcredentials.txt
touch /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif
dcstr=$(cat /root/scope.txt | tr -d " \t\n\r")
dcldapvar=""
temp="o: "
dc="init"
i=1
while [ "$dc" != "" ]
do
    dc=$(echo $dcstr | cut -d. -f$i)
    dcldapvar+="dc=$dc"
    temp+="$dc "
    echo "VAR=$dcldapvar"
    echo "TEMP=$temp"
    ((i+=1))
    dc=$(echo $dcstr | cut -d. -f$i)
    [ "$dc" == "" ] || dcldapvar+=","
done
echo "" >> /etc/bashrc
echo "export DCLDAPVAR=\"$dcldapvar\"" >> /etc/bashrc
source /etc/bashrc
export DCLDAPVAR="$dcldapvar"
sed -i.bak "s/dc=example,dc=ac,dc=in/$DCLDAPVAR/g" /opt/shibboleth-idp/conf/ldap.properties
sed -i.bak 's/dc=my-domain,dc=com/'"$DCLDAPVAR"'/g' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
sed -i.bak 's/dc=my-domain,dc=com/'"$DCLDAPVAR"'/g' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{1\}monitor.ldif
olcRootPW=$(cat /infedFiles/ldapcredentials.txt)
echo "olcRootPW: $olcRootPW" >> /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
echo "olcTLSCertificateFile: /etc/pki/tls/certs/domain.pem" >> /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
echo "olcTLSCertificateKeyFile: /etc/pki/tls/certs/domainkey.pem" >> /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
systemctl restart rsyslog
systemctl start slapd
systemctl enable slapd
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
openssl req -new -x509 -nodes -out /etc/pki/tls/certs/domain.pem -keyout /etc/pki/tls/certs/domainkey.pem -days 3650
maildomain=$(cat /root/scope.txt)
sed -i.bak "s/padl.com/$(echo $maildomain)/g" /usr/share/migrationtools/migrate_common.ph
sed -i.bak 's/dc=padl,dc=com/'"$DCLDAPVAR"'/g' /usr/share/migrationtools/migrate_common.ph
sed -i.bak 's/EXTENDED_SCHEMA = 0/EXTENDED_SCHEMA = 1/g' /usr/share/migrationtools/migrate_common.ph
((i-=1))
((n=i)) 
sed -i.bak 's/o:/'"$temp"'/g' /root/base.ldif
sed -i.bak 's/dc:/dc: '"$(echo $dcstr | cut -d. -f1)"'/g' /root/base.ldif
sed -i.bak 's/dc=inflibnet,dc=ac,dc=in/'"$DCLDAPVAR"'/g' /root/base.ldif
systemctl restart slapd
useradd ldapuser
echo "shibboleth" | passwd --stdin ldapuser
grep ":10[0-9][0-9]" /etc/passwd > /root/passwd
grep ":10[0-9][0-9]" /etc/group > /root/group
/usr/share/migrationtools/migrate_passwd.pl /root/passwd /root/users.ldif
/usr/share/migrationtools/migrate_group.pl /root/group /root/groups.ldif
ldapadd -x -W -D "cn=Manager,$DCLDAPVAR" -f /root/base.ldif
ldapadd -x -W -D "cn=Manager,$DCLDAPVAR" -f /root/users.ldif
ldapadd -x -W -D "cn=Manager,$DCLDAPVAR" -f /root/groups.ldif
systemctl stop firewalld
touch /etc/exports
echo "/home *(rw,sync)" >> /etc/exports
systemctl start rpcbind
systemctl start nfs
systemctl enable rpcbind
systemctl enable nfs
sed -i.bak 's/dc=inflibnet,dc=ac,dc=in/'"$DCLDAPVAR"'/g' /var/www/html/ldap/config/ldap.conf
sed -i.bak 's/Passwd:/Passwd: '"$(cat /infedFiles/ldapcredentials.txt)"'/g' /var/www/html/ldap/config/ldap.conf
footer="$(cat /infedFiles/idpfooter.txt)"
sed -i.bak 's/INFLIBNET Centre, Infocity, Gandhinagar, Gujarat, INDIA/'"$footer"'/g' /var/www/html/ldap/templates/login.php
sed -i.bak 's/idp.footer = Insert your footer text here./idp.footer = '"$footer"'/g' /opt/shibboleth-idp/system/messages/messages.properties
sed -i.bak 's/idp.url.password.reset = #/idp.url.password.reset = '"$(hostname)"'\/pw/g' /opt/shibboleth-idp/system/messages/messages.properties
sed -i.bak 's/dc=inflibnet,dc=ac,dc=in/'"$DCLDAPVAR"'/g' /var/www/html/pw/index.php
sed -i.bak 's/idp.inflibnet.ac.in/'"$(hostname)"'/g' /var/www/html/pw/index.php
sed -i.bak 's/www.inflibnet.ac.in/'"$dcstr"'/g' /var/www/html/pw/index.php
sed -i.bak 's/rootpwd = ""/rootpwd = '"$(cat /infedFiles/ldapcredentials.txt)"'/g' /var/www/html/pw/index.php
chown apache -R /var/www/html/ldap
/opt/shibboleth-idp/bin/build.sh
sleep 3
systemctl restart tomcat
systemctl restart httpd
systemctl restart httpd
read -p "Press ENTER to exit"
