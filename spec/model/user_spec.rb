require 'spec_helper'

describe CASino::User do
  describe '#active_two_factor_authenticator' do
    let(:user) { FactoryGirl.create :user }

    let!(:active_auth)   { FactoryGirl.create :two_factor_authenticator, user:user }
    let!(:inactive_auth) { FactoryGirl.create :two_factor_authenticator, :inactive, user:user }

    subject { user.active_two_factor_authenticator }

    it 'returns the active authenticator' do
      expect(subject).to eq active_auth
    end
  end

  describe '#ticket' do
    let(:user) { FactoryGirl.create :user }

    let!(:primary_ticket) { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:'Chrome' }
    let!(:other_ticket)   { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:'Firefox' }
    let!(:another_ticket) { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:'Firefox' }
    let!(:no_ua_ticket)   { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:nil }

    let(:params) { nil }

    subject { user.ticket params }

    it 'returns the first ticket found' do
      expect(subject).to eq primary_ticket
    end

    context 'with search parameters' do
      let(:params) { { user_agent:other_ticket.user_agent } }

      it 'returns the first matching ticket' do
        expect(subject).to eq other_ticket
      end

      context 'that contain nil values' do
        let(:params) { { user_agent:nil } }

        it 'does not include those parameters in the search' do
          expect(subject).to eq primary_ticket
        end
      end
    end
  end

  describe '#other_tickets' do
    let(:user) { FactoryGirl.create :user }

    let!(:primary_ticket) { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:'Chrome' }
    let!(:other_ticket)   { FactoryGirl.create :ticket_granting_ticket, user:user, user_agent:'Firefox' }

    let(:user_agent) { nil }

    subject { user.other_tickets user_agent }

    it 'returns an empty query' do
      expect(subject).to be_an ActiveRecord::Relation
    end

    context 'with a :user_agent specified' do
      context 'that has no matching Ticket Granting Ticket' do
        let(:user_agent) { 'Safari' }

        it 'returns an empty query' do
          expect(subject).to be_an ActiveRecord::Relation
        end
      end

      context 'that matches a Ticket Granting Ticket' do
        let(:user_agent) { primary_ticket.user_agent }

        it 'returns all other non-matching Ticket Granting Tickets' do
          expect(subject).to eq [other_ticket]
        end
      end
    end
  end
end
