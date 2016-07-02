# encoding: utf-8
# frozen_string_literal: true

# It only makes sense to use CodeClimate reporter on Travis
if ENV['TRAVIS']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'chatrix'
