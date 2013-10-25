require 'spec_helper'

describe CASino::TwoFactorAuthenticatorOverviewProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }

    context 'with a signed in User' do
      let(:user) { FactoryGirl.create :user }
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:user_agent) { ticket_granting_ticket.user_agent }

      context 'without a two-factor authenticator registered' do
        it 'calls the #two_factor_authenticators_found method on the listener' do
          listener.should_receive(:two_factor_authenticators_found).with([])
          processor.process(user, user_agent)
        end
      end

      context 'with an inactive two-factor authenticator' do
        let!(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, :inactive, user: user }

        it 'does not include the inactive authenticator' do
          listener.should_receive(:two_factor_authenticators_found).with([])
          processor.process(user, user_agent)
        end
      end

      context 'with a two-factor authenticator registered' do
        let(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, user: user }
        let!(:other_two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator }

        it 'calls the #two_factor_authenticators_found method on the listener' do
          listener.should_receive(:two_factor_authenticators_found).with([two_factor_authenticator])
          processor.process(user, user_agent)
        end
      end
    end

    context 'without a logged in user' do
      let(:user) { nil }

      let(:user_agent) { 'TestBrowser 1.0' }

      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in).with(no_args)
        processor.process(user, user_agent)
      end
    end
  end
end