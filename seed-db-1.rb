require 'pry'
require 'mysql2'
require 'faker'

db1 = Mysql2::Client.new(host: "127.0.0.1",
                         username: "root",
                         encoding: "utf8")

db1.query("CREATE database my_store;")
db1.query("USE my_store;")

db1.query("CREATE TABLE customers (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, name CHAR(50), address CHAR(200));")

1500.times do
  db1.query "INSERT INTO customers(name, address) VALUES(\"#{Faker::Name.name}\", \"#{Faker::Address.street_address}\")"
end
