require 'rails_helper'

RSpec.describe SchoolClass, type: :model do
  it "has a valid factory" do
    expect(build(:school_class)).to be_valid
  end

  it "requires a name" do
    expect(build(:school_class, name: nil)).not_to be_valid
  end

  it "is shared across teachers — no teacher_id (see docs/SPEC.md Decision #10)" do
    expect(SchoolClass.column_names).not_to include("teacher_id")
  end

  it "can be assigned to multiple tests via TestAssignment" do
    school_class = create(:school_class)
    test_a = create(:test)
    test_b = create(:test)
    create(:test_assignment, school_class: school_class, test: test_a)
    create(:test_assignment, school_class: school_class, test: test_b)

    expect(school_class.tests).to contain_exactly(test_a, test_b)
  end
end
