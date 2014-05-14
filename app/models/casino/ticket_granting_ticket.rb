require 'user_agent'

class CASino::TicketGrantingTicket < ActiveRecord::Base
  validates :ticket, uniqueness: true

  belongs_to :user
  has_many :service_tickets, dependent: :destroy

  # Backport Rails 4's ActiveRecord::NullRelation
  # From: http://stackoverflow.com/questions/4877931/how-to-return-an-empty-activerecord-relation
  # See also: http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-none
  if Rails.version.to_i < 4
    scope :none, where('1=0')
  end

  def self.cleanup(user = nil)
    if user.nil?
      base = self
    else
      base = user.ticket_granting_tickets
    end
    tgts = base.where([
      '(created_at < ? AND awaiting_two_factor_authentication = ?) OR (created_at < ? AND long_term = ?) OR created_at < ?',
      CASino.config.two_factor_authenticator[:timeout].seconds.ago,
      true,
      CASino.config.ticket_granting_ticket[:lifetime].seconds.ago,
      false,
      CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.ago
    ])
    CASino::ServiceTicket.where(ticket_granting_ticket_id: tgts).destroy_all
    tgts.destroy_all
  end

  def browser_info
    unless self.user_agent.blank?
      user_agent = UserAgent.parse(self.user_agent)
      if user_agent.platform.nil?
        "#{user_agent.browser}"
      else
        "#{user_agent.browser} (#{user_agent.platform})"
      end
    end
  end

  def same_user?(other_ticket)
    if other_ticket.nil?
      false
    else
      other_ticket.user_id == self.user_id
    end
  end

  def expired?
    if awaiting_two_factor_authentication?
      lifetime = CASino.config.two_factor_authenticator[:timeout]
    elsif long_term?
      lifetime = CASino.config.ticket_granting_ticket[:lifetime_long_term]
    else
      lifetime = CASino.config.ticket_granting_ticket[:lifetime]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
