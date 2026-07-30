require 'rails_helper'

RSpec.describe Teacher, type: :model do
  it "has a valid factory" do
    expect(build(:teacher)).to be_valid
  end

  it "requires a name" do
    teacher = build(:teacher, name: nil)
    expect(teacher).not_to be_valid
    expect(teacher.errors[:name]).to be_present
  end

  it "destroys its tests when destroyed" do
    teacher = create(:teacher)
    test = create(:test, teacher: teacher)

    expect { teacher.destroy }.to change(Test, :count).by(-1)
    expect(Test.exists?(test.id)).to be false
  end

  it "is not registerable — registration is closed (see docs/SPEC.md Decision #11)" do
    expect(Teacher.devise_modules).not_to include(:registerable)
  end

  it "sends devise notifications asynchronously" do
    teacher = build(:teacher)
    expect { teacher.send_reset_password_instructions }
    .to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end
end
