require 'rails_helper'

RSpec.describe Option, type: :model do
  it "has a valid factory" do
    expect(build(:option)).to be_valid
  end

  it "requires a body" do
    expect(build(:option, body: nil)).not_to be_valid
  end
end
