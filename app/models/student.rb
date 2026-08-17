# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :school_class
  has_many :test_attempts, dependent: :destroy

  validates :first_name, :last_name, :birth_date, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  # Used on the public class roster (docs/SPEC.md Decision #14, revised) —
  # enough to recognize yourself, without publishing full names to anyone
  # just browsing the site.
  def name_with_initial
    "#{first_name} #{last_name.first}."
  end

  # DDMM passcode — see docs/SPEC.md "Birth-Date Passcode" (not authentication,
  # just a light check against a classmate finishing the test as a prank).
  def passcode
    birth_date.strftime('%d%m')
  end

  def passcode_matches?(input)
    ActiveSupport::SecurityUtils.secure_compare(passcode, input.to_s)
  end
end
