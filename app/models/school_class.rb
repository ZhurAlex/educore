# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  has_many :students, dependent: :destroy
  has_many :test_assignments, dependent: :destroy
  has_many :tests, through: :test_assignments

  validates :name, presence: true
end
