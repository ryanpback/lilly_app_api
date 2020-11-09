# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
user = User.create(first_name: 'Ryan', last_name: 'Back', email: 'ryanpback@gmail.com', username: 'ryanpback', password: 'password123')

user.create_bucket
