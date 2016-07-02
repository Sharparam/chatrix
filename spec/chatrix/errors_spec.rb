# encoding: utf-8
# frozen_string_literal: true

describe 'errors' do
  let(:response) { { 'errcode' => 'M_GENERIC', 'error' => 'Generic error' } }

  describe Chatrix::RequestError do
    let(:error) { Chatrix::RequestError.new response }

    it 'should set the correct error code' do
      expect(error.code).to eql response['errcode']
    end

    it 'should set the correct error message' do
      expect(error.api_message).to eql response['error']
    end
  end

  describe Chatrix::RateLimitError do
    context 'with provided delay' do
      let(:rate_response) do
        {
          'errcode' => 'M_FOO',
          'error' => 'slow down',
          'retry_after_ms' => 1234
        }
      end

      let(:error) { Chatrix::RateLimitError.new rate_response }

      it 'should set the correct delay' do
        expect(error.retry_delay).to eql rate_response['retry_after_ms']
      end

      it 'should have an error code' do
        expect(error.code).to eql rate_response['errcode']
      end

      it 'should have an error message' do
        expect(error.api_message).to eql rate_response['error']
      end
    end

    context 'without a delay' do
      let(:error) { Chatrix::RateLimitError.new response }

      it 'should not set a delay' do
        expect(error.retry_delay).to be nil
      end

      it 'should have an error code' do
        expect(error.code).to eql response['errcode']
      end

      it 'should have an error message' do
        expect(error.api_message).to eql response['error']
      end
    end
  end

  describe Chatrix::UserNotFoundError do
    let(:user) { '@user:host.tld' }
    let(:error) { Chatrix::UserNotFoundError.new user, response }

    it 'should have a username' do
      expect(error.username).to eql user
    end

    it 'should have an error code' do
      expect(error.code).to eql response['errcode']
    end

    it 'should have an error message' do
      expect(error.api_message).to eql response['error']
    end
  end

  describe Chatrix::AvatarNotFoundError do
    let(:user) { '@user:host.tld' }
    let(:error) { Chatrix::AvatarNotFoundError.new user, response }

    it 'should have a username' do
      expect(error.username).to eql user
    end

    it 'should have an error code' do
      expect(error.code).to eql response['errcode']
    end

    it 'should have an error message' do
      expect(error.api_message).to eql response['error']
    end
  end

  describe Chatrix::RoomNotFoundError do
    let(:room) { '#room:host.tld' }
    let(:error) { Chatrix::RoomNotFoundError.new room, response }

    it 'should have a room name' do
      expect(error.room).to eql room
    end

    it 'should have an error code' do
      expect(error.code).to eql response['errcode']
    end

    it 'should have an error message' do
      expect(error.api_message).to eql response['error']
    end
  end
end
