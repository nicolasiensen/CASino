require 'spec_helper'

describe CASino::TwoFactorAuthenticatorRegistratorProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }

    context 'with an existing ticket-granting ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
      let(:user) { ticket_granting_ticket.user }
      let(:user_agent) { ticket_granting_ticket.user_agent }

      it 'creates exactly one authenticator' do
        listener.stub(:two_factor_authenticator_registered)
        lambda do
          processor.process(user, user_agent)
        end.should change(CASino::TwoFactorAuthenticator, :count).by(1)
      end

      it 'calls #two_factor_authenticator_created on the listener' do
        listener.should_receive(:two_factor_authenticator_registered) do |authenticator|
          authenticator.should == CASino::TwoFactorAuthenticator.last
        end
        processor.process(user, user_agent)
      end

      it 'creates an inactive two-factor authenticator' do
        listener.stub(:two_factor_authenticator_registered)
        processor.process(user, user_agent)
        CASino::TwoFactorAuthenticator.last.should_not be_active
      end
    end

    context 'without a logged in user' do
      let(:user) { nil }
      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in).with(no_args)
        processor.process
      end
    end
  end
end