class User < ApplicationRecord
  # アカウントを削除すると、そのユーザーの記録も削除する(eat_records.user_id の外部キーのため)
  has_many :eat_records, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth)
    logger.debug("aaaaaa")
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      #
      #user.provider = auth.provider
      #user.uid = auth.uid
      user.username = auth.info.name
    end
  end
end
