# encoding: utf-8
# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in ratrix.gemspec
gemspec

group :development do
  gem 'pry', '~> 0.10'
end

group :test do
  gem 'rake', '~> 11.0'
  gem 'rspec', '~> 3.0'
  gem 'codeclimate-test-reporter', '~> 0.5', require: false
end

group :development, :test do
  gem 'rubocop', '~> 0.41.0'
end

group :doc do
  gem 'yard', '~> 0.8'
  gem 'redcarpet', '~> 3.3'
end
