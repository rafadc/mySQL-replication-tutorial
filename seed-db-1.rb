require 'pry'
require 'mysql2'
require 'faker'

db1 = Mysql2::Client.new(host: "127.0.0.1",
                         username: "root",
                         encoding: "utf8")

db1.query("CREATE database my_store;")
db1.query("USE my_store;")

db1.query("CREATE TABLE customers (id INT NOT NULL, name CHAR(50), address CHAR(200), PRIMARY KEY(id));")

1500.times do |i|
  db1.query "INSERT INTO customers(id, name, address) VALUES(#{i}, \"#{Faker::Name.name}\", \"#{Faker::Address.street_address}\")"
end
