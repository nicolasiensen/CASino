
class CASino::User < ActiveRecord::Base
  attr_accessible :authenticator, :username, :extra_attributes
  serialize :extra_attributes, Hash

  has_many :ticket_granting_tickets
  has_many :two_factor_authenticators

  def active_two_factor_authenticator
    self.two_factor_authenticators.where(active: true).first
  end

  def ticket(params = {})
    query = if params
      params = params.delete_if{ |k,v| v.nil? }
      ticket_granting_tickets.where(params)
    else
      ticket_granting_tickets
    end

    query.first
  end

  def other_tickets(user_agent = nil)
    if primary = ticket(user_agent:user_agent)
      ticket_granting_tickets.where('id != ?', primary.id)
    else
      ticket_granting_tickets.none
    end
  end
end
