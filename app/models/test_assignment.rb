class TestAssignment < ApplicationRecord
  belongs_to :test
  belongs_to :school_class

  validates :test_id, uniqueness: { scope: :school_class_id }
end
