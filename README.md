# Demo mySQL setup

## Starting the VMs

If you already have a mySQL running in your computer, please, stop it since we will use our local 3306 and 3307 ports.

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
sudo apt-get install percona-xtrabackup
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

If you try to connect now from the host you will get a message saying that you are not allowed to connect from your host.

Let's connect from the VM.

```
mysql -u root
```

And show the users and privileges

```
select host, user from mysql.user;
```

We can grant to root all privileges from anywhere

```
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
```

Now you should be able to connect from the outside.


# Seeding the data

You can find included some ruby scripts to seed the database at db-1 with some sample data. We only need to seed db-1.

```
ruby seed-db-1.rb
```

This will create a database called my_store and some random customers into it.


# Backing up the master machine

The master will be db-1. We will do first a backup of the machine. We will use Percona xtrabackup.

First we will install it.

```
sudo apt-get install percona-xtrabackup
```

In the Vagrantfile we have set up a shared folder at /opt/shared. We will use that folder in both machines.

We can run a backup with

```
sudo innobackupex --user=root /opt/shared/
```

Then in /opt/shared we will have a folder with the current date as name. It will contain a backup of out db.


# Import the backup in the slave

First we need to stop mysql in db-2

```
sudo service mysql stop
```

We can check in /etc/mysql/my.cnf where mysql data is stored

```
datadir         = /var/lib/mysql
```

Then we copy all the backup files there.

```
sudo rm -rf /var/lib/mysql/*
sudo cp -r /opt/shared/2015-12-11_21-49-33/* /var/lib/mysql/
sudo chown -R mysql:mysql /var/lib/mysql/
```

We can start back mysql

```
sudo service mysql start
```
