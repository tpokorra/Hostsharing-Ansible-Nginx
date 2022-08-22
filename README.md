Hostsharing-Ansible-Nginx
=========================
This Ansible playbook will install a Nginx on a server from www.hostsharing.net, as a replacement for the Apache Web server.
It requires an additional daemon, and an assigned port number.
You will have to ask the Administrators to give you the port numbers for the http and https ports. They will redirect to traffic to port 80 and port 443 to those nginx ports.

To use these modules we have to create a file named ".hsadmin.properties" in the home directory of the package admins. In it we have to insert the packagename and password of the package admin. 

Example:

    xyz00@h99:~$ cat .hsadmin.properties 
    xyz00.passWord=insertpkgadminpasswordhere

This file should be protected, else it would be world readable:

    xyz00@h99:~$ chmod 600 .hsadmin.properties

We clone this git-repo to our machine:

    $ git clone https://github.com/tpokorra/Hostsharing-Ansible-Nginx.git

Then we change the working directory:

    $ cd Hostsharing-Ansible-Nginx

All needed parameters can be set in the inventory file now. Change xyz00 to the name of your package admin. Set the name of a domain, a new user and a password. We can edit the inventory file with:

    $ cp inventory-sample.yml inventory.yml
    $ vim inventory.yml
    
The option -i can be used to read this inventory file instead of the /etc/ansible/hosts file. We want to login with an SSH-Key. We run:

    $ ansible-playbook -i inventory.yml playbook-install.yml

If your DNS for demo.example.org points to the IP address of the Hostsharing package, then you can run as the user:

    $ $HOME/bin/addwebsite.sh demo.example.org

This will create a site configuration in $HOME/etc/nginx.conf.d/ pointing to $HOME/doms/demo.example.org/htdocs, and it will use letsencrypt with HTTP challenge to install a free SSL certificate.

Now we can reach our site via:

    https://demo.example.org

--- Open Source Hosting ---
 https://www.hostsharing.net
