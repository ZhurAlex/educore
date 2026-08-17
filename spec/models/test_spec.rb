# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Test, type: :model do
  it 'has a valid factory' do
    expect(build(:test)).to be_valid
  end

  it 'requires a title' do
    expect(build(:test, title: nil)).not_to be_valid
  end

  it 'requires locale to be one of the MVP locales (see docs/SPEC.md Decision #5)' do
    expect(build(:test, locale: 'uk')).to be_valid
    expect(build(:test, locale: 'ru')).to be_valid
    expect(build(:test, locale: 'en')).to be_valid
    expect(build(:test, locale: 'de')).not_to be_valid
    expect(build(:test, locale: nil)).not_to be_valid
  end

  it 'can be assigned to multiple school classes via TestAssignment' do
    test = create(:test)
    class_a = create(:school_class)
    class_b = create(:school_class)
    create(:test_assignment, test: test, school_class: class_a)
    create(:test_assignment, test: test, school_class: class_b)

    expect(test.school_classes).to contain_exactly(class_a, class_b)
  end

  it 'destroys its questions when destroyed' do
    test = create(:test)
    question = create(:question, test: test)

    expect { test.destroy }.to change(Question, :count).by(-1)
    expect(Question.exists?(question.id)).to be false
  end
end
