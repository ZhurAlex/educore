# frozen_string_literal: true

class CreateSchoolClasses < ActiveRecord::Migration[7.1]
  def change
    create_table :school_classes do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
