class Teacher < ApplicationRecord
  # No :registerable — registration is closed, the single Teacher account
  # is seeded via db/seeds.rb (see docs/SPEC.md Decision #11).
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many :tests, dependent: :destroy

  validates :name, presence: true

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
