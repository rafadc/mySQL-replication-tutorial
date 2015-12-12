require 'pry'
require 'mysql2'
require 'faker'

db1 = Mysql2::Client.new(host: "127.0.0.1",
                         username: "root",
                         encoding: "utf8",
                         database: "my_store"
                        )

180.times do |i|
  name = Faker::Name.name
  address = Faker::Address.street_address
  db1.query "INSERT INTO customers(name, address) VALUES(\"#{name}\", \"#{address}\")"
  puts "Inserted #{name} - #{address}"
  sleep 1
end
