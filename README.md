# Demo mySQL setup

## Starting the VMs

```
vagrant up
```

This will create two VMs. One called db-1 with the ip 192.168.1.10 and db-2 with the ip 192.168.1.11

We can connect to db-1 with

```
vagrant ssh db-1
```

And of course to db-2 with

```
vagrant ssh db-2
```

## Installing Percona mySQL

This procedure should be followed for both machines

Add the Percona repository

```
sudo add-apt-repository "deb http://repo.percona.com/apt trusty testing"
sudo add-apt-repository "deb-src http://repo.percona.com/apt trusty testing"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C4CBDCDCD2EFD2A
```

Install Percona mySQL

```
sudo apt-get update
sudo apt-get install percona-server-server-5.5
```

Check that Percona mySQL is running

```
sudo service mysql status
```

You can stop it with

```
sudo service mysql stop
```

and start it with

```
sudo service mysql start
```

You can take a look to the default config files at

```
/etc/mysql/my.cnf
```
