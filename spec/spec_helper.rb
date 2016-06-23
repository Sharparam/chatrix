$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'chatrix'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
