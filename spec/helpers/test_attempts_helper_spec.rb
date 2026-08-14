# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestAttemptsHelper, type: :helper do
  describe '#questions_as_json' do
    it 'serializes a multiple_choice question with its options, excluding which one is correct' do
      question = create(:question, :multiple_choice, body: 'Pick one', points: 2)
      correct_option = question.options.find(&:correct?)
      wrong_option = question.options.find { |o| !o.correct? }

      json = I18n.with_locale(:en) { JSON.parse(helper.questions_as_json([question])) }

      expect(json).to eq([
                           {
                             'id' => question.id,
                             'body' => 'Pick one',
                             'answer_type' => 'multiple_choice',
                             'points_label' => '2 pts',
                             'options' => [
                               { 'id' => correct_option.id, 'body' => correct_option.body },
                               { 'id' => wrong_option.id, 'body' => wrong_option.body }
                             ]
                           }
                         ])
    end

    it 'strips the trailing .0 from whole-number points, but keeps real fractions' do
      whole = create(:question, points: 2)
      fraction = create(:question, points: 1.5)

      json = I18n.with_locale(:en) { JSON.parse(helper.questions_as_json([whole, fraction])) }

      expect(json[0]['points_label']).to eq('2 pts')
      expect(json[1]['points_label']).to eq('1.5 pts')
    end

    it 'uses the correct ru pluralization form per points count' do
      one = create(:question, points: 1)
      few = create(:question, points: 3)
      many = create(:question, points: 5)

      I18n.with_locale(:ru) do
        json = JSON.parse(helper.questions_as_json([one, few, many]))

        expect(json[0]['points_label']).to eq('1 балл')
        expect(json[1]['points_label']).to eq('3 балла')
        expect(json[2]['points_label']).to eq('5 баллов')
      end
    end

    it 'does not leak which option is correct, or the short_text correct_answer' do
      mc_question = create(:question, :multiple_choice)
      st_question = create(:question, answer_type: :short_text, correct_answer: 'Paris')

      json = helper.questions_as_json([mc_question, st_question])

      expect(json).not_to include('correct_answer')
      expect(json).not_to include('"correct"')
    end

    it 'serializes a short_text question with an empty options array' do
      question = create(:question, answer_type: :short_text, correct_answer: 'Paris')

      json = JSON.parse(helper.questions_as_json([question]))

      expect(json.first['options']).to eq([])
    end
  end

  describe '#translations_as_json' do
    it 'returns the test_attempts.show translations for the current locale' do
      I18n.with_locale(:en) do
        json = JSON.parse(helper.translations_as_json)

        expect(json['submit']).to eq('Submit')
        expect(json['question_progress']).to eq('Question %{current} of %{total}')
      end
    end
  end
end
