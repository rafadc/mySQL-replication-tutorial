# Replication mySQL setup

We will be setting a replication system between two virtual machines. We will be using Percona's mySQL distribution. Anyway the process should be really similar in mySQL community edition.

The replication schema in mySQL works like this

![Redundancy schema](images/redundancy.png)

The replication is used to achieve redundancy of data so we can get our system online fast in case of disaster.

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

Since we want to be able to be connected from all the network interfaces we can set the bind_address to 0.0.0.0

```
bind-address            = 0.0.0.0
```

After changing this you will need to restart mysql as we did before.

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

To be able to replicate data we need to enable binlogs in mySQL. You can do it adding the following lines to my.cnf

```
log-bin                        = /var/lib/mysql/mysql-bin
expire-logs-days               = 14
sync-binlog                    = 1
```

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
sudo innobackupex --user=root --apply-log /opt/shared/<backup folder>/
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

Then we copy all the backup files to that location.

```
sudo rm -rf /var/lib/mysql
sudo cp -r /opt/shared/<your backup> /var/lib/mysql
sudo chown -R mysql:mysql /var/lib/mysql
```

Since we are using a debian based distro for the VMs (Ubuntu) we need to update one more file. Take the password for the debian-sys-maint user from /etc/mysql/debian.cnf in db-1 and copy it to /etc/mysql/debian.cnf in db-2

We can start back mySQL

```
sudo service mysql start
```

*TODO*: At this moment I had to remove both ib_logfile in the slave machine since mySQL is complaining about their size to start. Is there a cleanest solution that doesn't involve to manually change slave's config?

## Configure the replication

### On master

We need to set the server-id in my.cnf. Uncomment the following line in the config file.

```
server-id               = 1
```

To apply the changes you will need to restart mySQL.

```
sudo service mysql restart
```

Check that you can connect to the slave

```
mysql -h 192.168.1.11 -u root
```

If everything is correct exit that console and connect to the local DB.

```
mysql -u root
```

Just run the following SQL

```
GRANT REPLICATION SLAVE ON *.*  TO 'root'@'192.168.1.11';
```

### On slave

In the slave (db-2) just change the following in my.cnf

```
server-id=2
```

Restart the db.

Check the binlog position in the slave

```
sudo cat /var/lib/mysql/xtrabackup_binlog_info
```

It should be something like

```
mysql-bin.000001        389124
```

Connect to db-2's mySQL console and configure db-1 as master

```
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='root',
  MASTER_LOG_FILE='<binlog file>',
  MASTER_LOG_POS=<binlog position>;
```

The binlog file and the binlog position are the ones obtained by reading xtrabackup_binlog_info so, for the example before the values should be:

```
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='root',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=389124;
```

And finally start the slave from mySQL console.

```
START SLAVE;
```

We can check the status of the slave with

```
SHOW SLAVE STATUS \G
```

And the replication should be configured!

We can run the following statement in db-1

```
SHOW SLAVE HOSTS;
```

And we should get something like

```
+-----------+------+------+-----------+
| Server_id | Host | Port | Master_id |
+-----------+------+------+-----------+
|         2 |      | 3306 |         1 |
+-----------+------+------+-----------+
1 row in set (0.00 sec)
```

# Replicating some data

Let's count the number of customers in db-1 and db-2 with some SQL

```
use my_store;
select count(*) from customers;
```

We should have 1500 in both databases.

In the project folder we have an **insert-data-in-db1.rb** script that inserts 180 customers in the database waiting one second between insertions. Run it and keep counting the number of records in db-2 to check that everything is being replicated.

When we save data to one of the databases we need to be really careful to run our INSERT statements on the master database. It is possible to write data in the slave machines but this will not be replicated to any other database leaving the databases out of sync forever. Also that could cause the replication to break due to conflicts in the data. This is something we don't want to do in 99.99% of the scenarios.

# Promoting an slave to master

First we need to make sure that all work pending is processed in all slave. Since we only have one we only need to run in db-2:

```
show processlist;
```

We should see one of the system processes show a message like this

```
Slave has read all relay log; waiting for the slave I/O thread to update it
```

If not, probably there is still data being processed.

Once it is finished we can promote db-2 to master.

```
STOP SLAVE;
RESET MASTER;
```

And the in the old master we need to do:

```
CHANGE MASTER TO
  MASTER_HOST='192.168.1.11',
  MASTER_USER='root';
START SLAVE;
```

If we had more slave we should do this process in each of them. But since we only have 2 machines this is not a problem for us.

If we want to make sure that our configuration is correct we can run in both machines

```
SHOW SLAVE STATUS\G
```

And in the master (now, db-2) we should see

```
Slave_IO_State:
[...]
Slave_IO_Running: No
Slave_SQL_Running: No
```

whereas in the slave (now db-1) we will see

```
Slave_IO_State: Waiting for master to send event
[...]
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

Also not that

```
SHOW SLAVE HOSTS;
```

In the old master (db-1) will still return old data until it is restarted.

Now we need to switch our application to connect to the new master.

# Exercise

If we run **insert-data-in-db1.rb** right now the data won't be replicated. Why?

Update **insert-data-in-db1.rb** to make the data it inserts to replicate again.

# Resources

- [Official mySQL page for replication](http://dev.mysql.com/doc/refman/5.0/en/replication-solutions-switch.html)
