# frozen_string_literal: true

class AddFeedbackColumnToResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :responses, :feedback, :text
  end
end
