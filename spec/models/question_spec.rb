require 'rails_helper'

RSpec.describe Question, type: :model do
  it "has a valid factory" do
    expect(build(:question)).to be_valid
  end

  it "only supports multiple_choice and short_text — long_text is deferred (Decision #12)" do
    expect(Question.answer_types.keys).to contain_exactly("multiple_choice", "short_text")
  end

  it "requires correct_answer for short_text" do
    question = build(:question, answer_type: :short_text, correct_answer: nil)
    expect(question).not_to be_valid
    expect(question.errors[:correct_answer]).to be_present
  end

  it "does not require correct_answer for multiple_choice" do
    question = build(:question, answer_type: :multiple_choice, correct_answer: nil)
    expect(question).to be_valid
  end

  describe "points" do
    it "must be at least 0.5" do
      expect(build(:question, points: 0.5)).to be_valid
      expect(build(:question, points: 0.4)).not_to be_valid
    end

    it "must be in increments of 0.5 (Decision #13)" do
      expect(build(:question, points: 1.5)).to be_valid
      expect(build(:question, points: 2)).to be_valid
      expect(build(:question, points: 1.7)).not_to be_valid
    end
  end

  describe "#grade" do
    context "short_text" do
      let(:question) { create(:question, answer_type: :short_text, correct_answer: "Paris", points: 2) }

      it "awards full points on an exact match" do
        expect(question.grade(answer_text: "Paris")).to eq(2)
      end

      it "normalizes case, whitespace and punctuation before comparing" do
        expect(question.grade(answer_text: "  paris!! ")).to eq(2)
      end

      it "awards zero on a mismatch" do
        expect(question.grade(answer_text: "London")).to eq(0)
      end

      it "awards zero on a blank answer" do
        expect(question.grade(answer_text: nil)).to eq(0)
      end
    end

    context "multiple_choice" do
      let(:question) { create(:question, :multiple_choice, points: 1) }
      let(:correct_option) { question.options.find(&:correct?) }
      let(:wrong_option) { question.options.find { |o| !o.correct? } }

      it "awards full points for the correct option" do
        expect(question.grade(option_id: correct_option.id)).to eq(1)
      end

      it "awards zero for an incorrect option" do
        expect(question.grade(option_id: wrong_option.id)).to eq(0)
      end

      it "awards zero when no option was picked" do
        expect(question.grade(option_id: nil)).to eq(0)
      end
    end
  end
end
