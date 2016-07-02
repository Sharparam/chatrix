# encoding: utf-8
# frozen_string_literal: true

describe Chatrix do
  it 'has a version number' do
    expect(Chatrix::VERSION).not_to be nil
  end

  it 'has a correctly formatted version number' do
    # Version has to be X.Y.Z, optionally followed by additional
    # version metadata
    expect(Chatrix::VERSION).to match(/^\d+\.\d+\.\d+(\.\w+)*$/)
  end
end
