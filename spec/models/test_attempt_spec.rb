# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestAttempt, type: :model do
  it 'has a valid factory' do
    expect(build(:test_attempt)).to be_valid
  end

  it 'requires started_at' do
    expect(build(:test_attempt, started_at: nil)).not_to be_valid
  end

  it 'does not allow a second in_progress attempt for the same student+test (Decision #2)' do
    student = create(:student)
    test = create(:test)
    create(:test_attempt, student: student, test: test, status: :in_progress)

    duplicate = build(:test_attempt, student: student, test: test, status: :in_progress)
    expect(duplicate).not_to be_valid
  end

  it 'allows a new attempt once the previous one is completed' do
    student = create(:student)
    test = create(:test)
    create(:test_attempt, :completed, student: student, test: test)

    second = build(:test_attempt, student: student, test: test, status: :in_progress)
    expect(second).to be_valid
  end

  describe '#recompute_score!' do
    it 'sums points_awarded into score, and rounds score up into grade (Decision #13)' do
      test_attempt = create(:test_attempt)
      create(:response, test_attempt: test_attempt, points_awarded: 3.5)
      create(:response, test_attempt: test_attempt, question: create(:question), points_awarded: 5)

      test_attempt.recompute_score!

      expect(test_attempt.score).to eq(8.5)
      expect(test_attempt.grade).to eq(9)
    end
  end
end
