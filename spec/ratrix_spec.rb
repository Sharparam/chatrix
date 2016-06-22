describe Ratrix do
  it 'has a version number' do
    expect(Ratrix::VERSION).not_to be nil
  end

  it 'has a correctly formatted version number' do
    # Version has to be X.Y.Z, optionally followed by additional
    # version metadata
    expect(Ratrix::VERSION).to match(/^\d+\.\d+\.\d+(\.\w+)*$/)
  end
end
