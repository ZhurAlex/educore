require 'rails_helper'

RSpec.describe Student, type: :model do
  it "has a valid factory" do
    expect(build(:student)).to be_valid
  end

  it "requires first_name, last_name and birth_date" do
    student = build(:student, first_name: nil, last_name: nil, birth_date: nil)
    expect(student).not_to be_valid
    expect(student.errors[:first_name]).to be_present
    expect(student.errors[:last_name]).to be_present
    expect(student.errors[:birth_date]).to be_present
  end

  describe "#passcode" do
    it "is the DDMM of birth_date" do
      student = build(:student, birth_date: Date.new(2015, 3, 7))
      expect(student.passcode).to eq("0703")
    end
  end

  describe "#passcode_matches?" do
    let(:student) { build(:student, birth_date: Date.new(2015, 3, 7)) }

    it "matches the correct DDMM" do
      expect(student.passcode_matches?("0703")).to be true
    end

    it "does not match an incorrect DDMM" do
      expect(student.passcode_matches?("0101")).to be false
    end
  end
end
