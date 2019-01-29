read -p "Enter Certificate Key file path (ex: /home/usr/idp.yourdomain.org.key): " keyPath
read -p "Enter Certificate file path (ex: /home/usr/idp.yourdomain.org.crt): " crtPath
read -p "Enter Certificate Chain file path (ex: /home/usr/idp.yourdomain.org.pem): " pemPath
read -p "Enter Logo image file path: " logoPath
read -p "Enter Footer text of your institution: " footer
read -p "Enter Servername (hostname of this machine): " servername
touch /infedFiles/idpfooter.txt
echo "$footer" >> /infedFiles/idpfooter.txt
mkdir -p /etc/pki/tls/private/
mkdir -p /etc/pki/tls/certs/
mkdir -p /var/www/html/ldap/graphics
cp $logoPath /var/www/html/ldap/graphics/logo.png
cp $logoPath /var/www/html/pw/images/logo.png
cp -rR $keyPath /etc/pki/tls/private/domain.key
cp -rR $crtPath /etc/pki/tls/certs/domain.crt
cp -rR $pemPath /etc/pki/tls/certs/domain.pem
sed -i.bak 's/ServerNameidp.yourdomain.org/ServerName '"$servername"'/g' /etc/httpd/conf.d/modssl.conf
chmod +x /usr/local/files/shibboleth-identity-provider-3.3.2/bin/install.sh
/usr/local/files/shibboleth-identity-provider-3.3.2/bin/install.sh
[ $? -eq 0 ] && echo "SUCCESS" || read -p "ERROR 0_0"
cp /usr/local/files/certs/infed.xml /opt/shibboleth-idp/metadata/
cp /usr/local/files/certs/interfederation_sp.xml /opt/shibboleth-idp/metadata/
cp /usr/local/files/certs/infed.crt /opt/shibboleth-idp/credentials/
cp /usr/local/files/certs/interfed.cert.pem /opt/shibboleth-idp/credentials/
cp /usr/local/files/ldap.properties /opt/shibboleth-idp/conf/ldap.properties
cp /usr/local/files/attribute-resolver.xml /opt/shibboleth-idp/conf/attribute-resolver.xml
cp /usr/local/files/attribute-filter.xml /opt/shibboleth-idp/conf/attribute-filter.xml
cp /usr/local/files/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml
cp $logoPath /opt/shibboleth-idp/edit-webapp/images/logo.png
systemctl restart httpd
touch /home/INFED.txt
chmod 777 /home/INFED.txt
read -p "Press enter to exit"
