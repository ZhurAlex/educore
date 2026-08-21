# frozen_string_literal: true

class AddSubjectToTest < ActiveRecord::Migration[7.1]
  def change
    add_column :tests, :subject, :integer
  end
end
