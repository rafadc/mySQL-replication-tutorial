require 'pry'
require 'mysql'

db1 = Mysql2::Client.new(:host => "localhost", :username => "root", :port => 3360)
