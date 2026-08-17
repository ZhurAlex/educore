# frozen_string_literal: true

class Option < ApplicationRecord
  belongs_to :question

  validates :body, presence: true
end
