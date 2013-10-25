require 'spec_helper'

describe CASino::TwoFactorAuthenticatorDestroyerProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }

    context 'with an existing ticket-granting ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
      let(:user) { ticket_granting_ticket.user }
      let(:tgt) { ticket_granting_ticket.ticket }
      let(:user_agent) { ticket_granting_ticket.user_agent }
      let(:params) { { id: two_factor_authenticator.id } }

      context 'with a valid two-factor authenticator' do
        let!(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, user: user }

        it 'calls the #two_factor_authenticator_destroyed method on the listener' do
          listener.should_receive(:two_factor_authenticator_destroyed).with(no_args)
          processor.process(params, user, user_agent)
        end

        it 'deletes the two-factor authenticator' do
          listener.stub(:two_factor_authenticator_destroyed)
          processor.process(params, user, user_agent)
          lambda do
            two_factor_authenticator.reload
          end.should raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not delete other two-factor authenticators' do
          listener.stub(:two_factor_authenticator_destroyed)
          other = FactoryGirl.create :two_factor_authenticator
          lambda do
            processor.process(params, user, user_agent)
          end.should change(CASino::TwoFactorAuthenticator, :count).by(-1)
        end
      end

      context 'with a two-factor authenticator of another user' do
        let!(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator }

        it 'calls the #invalid_two_factor_authenticator method on the listener' do
          listener.should_receive(:invalid_two_factor_authenticator).with(no_args)
          processor.process(params, user, user_agent)
        end

        it 'does not delete two-factor authenticators' do
          listener.stub(:invalid_two_factor_authenticator)
          lambda do
            processor.process(params, user, user_agent)
          end.should_not change(CASino::TwoFactorAuthenticator, :count)
        end
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