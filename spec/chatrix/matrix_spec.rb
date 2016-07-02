# encoding: utf-8
# frozen_string_literal: true

describe Chatrix::Matrix do
  context 'when created with no args' do
    it 'has a default homeserver' do
      expect(subject.homeserver).to be_a String
    end

    it 'does not set an access token' do
      expect(subject.access_token).to be nil
    end
  end

  context 'when created with args' do
    let(:api) { Chatrix::Matrix.new 'my_token', 'my_server' }

    it 'sets a custom homeserver' do
      expect(api.homeserver).to eql 'my_server'
    end

    it 'sets a custom token' do
      expect(api.access_token).to eql 'my_token'
    end
  end
end
