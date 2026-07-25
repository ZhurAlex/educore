require 'rails_helper'

RSpec.describe Option, type: :model do
  it "has a valid factory" do
    expect(build(:option)).to be_valid
  end

  it "requires a body" do
    expect(build(:option, body: nil)).not_to be_valid
  end

  it "does not allow two correct options on the same question" do
    question = create(:question, answer_type: :multiple_choice, correct_answer: nil)
    create(:option, question: question, correct: true)

    second = build(:option, question: question, correct: true)
    expect(second).not_to be_valid
    expect(second.errors[:correct]).to be_present
  end

  it "allows multiple incorrect options on the same question" do
    question = create(:question, answer_type: :multiple_choice, correct_answer: nil)
    create(:option, question: question, correct: false)

    second = build(:option, question: question, correct: false)
    expect(second).to be_valid
  end
end
