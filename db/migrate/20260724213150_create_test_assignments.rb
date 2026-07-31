class CreateTestAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :test_assignments do |t|
      t.references :test, null: false, foreign_key: true
      t.references :school_class, null: false, foreign_key: true

      t.timestamps
    end

    add_index :test_assignments, [ :test_id, :school_class_id ], unique: true
  end
end
