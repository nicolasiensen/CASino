require 'spec_helper'

describe CASino::TwoFactorAuthenticatorActivatorProcessor do
  describe '#process' do
    let(:listener) { double(:listener, assigned:user) }
    let(:processor) { described_class.new(listener) }

    context 'with an existing ticket-granting ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
      let(:user) { ticket_granting_ticket.user }
      let(:user_agent) { ticket_granting_ticket.user_agent }
      let(:id) { two_factor_authenticator.id }
      let(:otp) { '123456' }
      let(:params) { { otp: otp, id: id } }

      context 'with an invalid authenticator' do
        context 'with an expired authenticator' do
          let(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, :inactive, user: user }

          before(:each) do
            two_factor_authenticator.created_at = 10.hours.ago
            two_factor_authenticator.save!
          end

          it 'calls the `#invalid_two_factor_authenticator` method an the listener' do
            listener.should_receive(:invalid_two_factor_authenticator).with(no_args)
            processor.process(params, user, user_agent)
          end
        end

        context 'with a authenticator of another user' do
          let(:two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, :inactive }

          before(:each) do
            two_factor_authenticator.created_at = 10.hours.ago
            two_factor_authenticator.save!
          end

          it 'calls the `#invalid_two_factor_authenticator` method an the listener' do
            listener.should_receive(:invalid_two_factor_authenticator).with(no_args)
            processor.process(params, user, user_agent)
          end
        end
      end

      context 'with a valid authenticator' do
        let(:two_factor_authenticator) do
          FactoryGirl.create :two_factor_authenticator, :inactive, user: user
        end

        context 'with a valid OTP' do
          before(:each) do
            ROTP::TOTP.any_instance.should_receive(:verify_with_drift).with(otp, 30).and_return(true)
          end

          it 'calls the `#two_factor_authenticator_activated` method an the listener' do
            listener.should_receive(:two_factor_authenticator_activated).with(no_args)
            processor.process(params, user, user_agent)
          end

          it 'does activate the authenticator' do
            listener.stub(:two_factor_authenticator_activated)
            processor.process(params, user, user_agent)
            two_factor_authenticator.reload
            two_factor_authenticator.should be_active
          end

          context 'when another two-factor authenticator was active' do
            let!(:other_two_factor_authenticator) { FactoryGirl.create :two_factor_authenticator, user: user }

            it 'does activate the authenticator' do
              listener.stub(:two_factor_authenticator_activated)
              processor.process(params, user, user_agent)
              two_factor_authenticator.reload
              two_factor_authenticator.should be_active
            end

            it 'does delete the other authenticator' do
              listener.stub(:two_factor_authenticator_activated)
              processor.process(params, user, user_agent)
              lambda do
                other_two_factor_authenticator.reload
              end.should raise_error(ActiveRecord::RecordNotFound)
            end
          end

        end

        context 'with an invalid OTP' do
          before(:each) do
            ROTP::TOTP.any_instance.should_receive(:verify_with_drift).with(otp, 30).and_return(false)
          end

          it 'calls the `#invalid_one_time_password` method an the listener' do
            listener.should_receive(:invalid_one_time_password).with(two_factor_authenticator)
            processor.process(params, user, user_agent)
          end

          it 'does not activate the authenticator' do
            listener.stub(:invalid_one_time_password)
            processor.process(params, user, user_agent)
            two_factor_authenticator.reload
            two_factor_authenticator.should_not be_active
          end
        end
      end
    end

    context 'without a logged in user' do
      let(:user) { nil }
      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in).with(no_args)
        processor.process(nil, user)
      end
    end
  end
end