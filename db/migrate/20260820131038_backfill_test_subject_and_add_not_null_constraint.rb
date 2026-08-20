# frozen_string_literal: true

class BackfillTestSubjectAndAddNotNullConstraint < ActiveRecord::Migration[7.1]
  def up
    # A default alone doesn't touch existing rows — only affects future
    # INSERTs. Any pre-existing test (created before `subject` existed) has
    # no way to reliably infer an intended subject — default to :math (0),
    # arbitrary but explicit; the teacher can correct it by hand afterward.
    execute 'UPDATE tests SET subject = 0 WHERE subject IS NULL'

    change_column_null :tests, :subject, false
  end

  def down
    change_column_null :tests, :subject, true
  end
end
