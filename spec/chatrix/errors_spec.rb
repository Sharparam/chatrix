describe Chatrix::RequestError do
  let(:response) { { 'errcode' => 666, 'error' => 'my error' } }
  let(:error) { Chatrix::RequestError.new response }

  it 'should set the correct error code' do
    expect(error.code).to eql response['errcode']
  end

  it 'should set the correct error message' do
    expect(error.api_message).to eql response['error']
  end
end

describe Chatrix::UserNotFoundError do
  let(:user) { '@user:host.tld' }
  let(:error) { Chatrix::UserNotFoundError.new user }

  it 'should have a username' do
    expect(error.username).to eql user
  end
end

describe Chatrix::AvatarNotFoundError do
  let(:user) { '@user:host.tld' }
  let(:error) { Chatrix::AvatarNotFoundError.new user }

  it 'should have a username' do
    expect(error.username).to eql user
  end
end

describe Chatrix::RoomNotFoundError do
  let(:room) { '#room:host.tld' }
  let(:error) { Chatrix::RoomNotFoundError.new room }

  it 'should have a room name' do
    expect(error.room).to eql room
  end
end
