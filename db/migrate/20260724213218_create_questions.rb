class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.references :test, null: false, foreign_key: true
      t.text :body, null: false
      t.integer :answer_type, null: false
      t.decimal :points, precision: 5, scale: 2, null: false
      t.string :correct_answer

      t.timestamps
    end
  end
end
