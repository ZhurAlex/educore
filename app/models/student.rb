class Student < ApplicationRecord
  belongs_to :school_class
  has_many :test_attempts, dependent: :destroy

  validates :first_name, :last_name, :birth_date, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  # DDMM passcode — see docs/SPEC.md "Birth-Date Passcode" (not authentication,
  # just a light check against a classmate finishing the test as a prank).
  def passcode
    birth_date.strftime("%d%m")
  end

  def passcode_matches?(input)
    ActiveSupport::SecurityUtils.secure_compare(passcode, input.to_s)
  end
end
