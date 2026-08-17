# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestAssignment, type: :model do
  it 'has a valid factory' do
    expect(build(:test_assignment)).to be_valid
  end

  it 'does not allow assigning the same test to the same school class twice' do
    test = create(:test)
    school_class = create(:school_class)
    create(:test_assignment, test: test, school_class: school_class)

    duplicate = build(:test_assignment, test: test, school_class: school_class)
    expect(duplicate).not_to be_valid
  end

  it 'allows the same test to be assigned to different school classes (Decision #6)' do
    test = create(:test)
    create(:test_assignment, test: test, school_class: create(:school_class))
    second = build(:test_assignment, test: test, school_class: create(:school_class))

    expect(second).to be_valid
  end
end
