class CreateResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :responses do |t|
      t.references :test_attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      # Nullable: only multiple_choice responses have an option; short_text
      # responses answer via answer_text instead.
      t.references :option, null: true, foreign_key: true
      t.text :answer_text
      t.integer :grading_status, null: false, default: 0
      t.decimal :points_awarded, precision: 5, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :responses, [:test_attempt_id, :question_id], unique: true
  end
end
