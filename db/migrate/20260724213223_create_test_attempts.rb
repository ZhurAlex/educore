class CreateTestAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :test_attempts do |t|
      t.references :student, null: false, foreign_key: true
      t.references :test, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :score, precision: 5, scale: 2
      t.integer :grade
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    # Decision #2 (docs/SPEC.md): one active (in_progress) attempt per
    # (student, test) — status 0 is in_progress (see TestAttempt enum).
    add_index :test_attempts, [ :student_id, :test_id ], unique: true,
      where: "status = 0", name: "index_test_attempts_on_active_student_test"
  end
end
