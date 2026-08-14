# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Response, type: :model do
  it 'has a valid factory' do
    expect(build(:response)).to be_valid
  end

  it 'has a valid multiple_choice factory' do
    expect(build(:response, :multiple_choice)).to be_valid
  end

  it 'allows a blank option for a multiple_choice question (Decision #13: a skipped answer scores 0, not an error)' do
    question = create(:question, :multiple_choice)
    response = build(:response, question: question, option: nil, answer_text: nil)

    expect(response).to be_valid
  end

  it 'allows a blank answer_text for a short_text question (Decision #13: a skipped answer scores 0, not an error)' do
    question = create(:question, answer_type: :short_text)
    response = build(:response, question: question, answer_text: nil)

    expect(response).to be_valid
  end

  it 'does not allow two responses to the same question in one attempt' do
    test_attempt = create(:test_attempt)
    question = create(:question)
    create(:response, test_attempt: test_attempt, question: question)

    duplicate = build(:response, test_attempt: test_attempt, question: question)
    expect(duplicate).not_to be_valid
  end

  it 'only has pending_review/llm_graded reintroduced with long_text (Decision #12)' do
    expect(Response.grading_statuses.keys).to contain_exactly('auto_graded', 'teacher_overridden')
  end
end
