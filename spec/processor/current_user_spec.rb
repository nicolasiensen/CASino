require 'spec_helper'

describe CASino::CurrentUserProcessor do
  let(:user) { FactoryGirl.create :user }
  let(:current_user) { nil }
  let(:cookies) { nil }
  let(:user_agent) { 'TestBrowser 1.0' }
  let(:listener) do
    double('listener').tap do |l|
      l.stub('assigned').with(:current_user).and_return(current_user)
    end
  end
  let(:processor) { described_class.new(listener) }

  describe '#process' do
    subject { processor.process(cookies, user_agent) }

    context 'with a previously set :current_user value' do
      let(:current_user) { user }

      it 'calls the :current_user_found callback' do
        listener.should_receive(:current_user_found)
        subject
      end
    end

    context 'with an existing Ticket Granting Ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:cookies) { { tgt:ticket_granting_ticket.ticket } }

      it 'calls the :current_user_found callback' do
        listener.should_receive(:current_user_found)
        subject
      end

      context 'that has expired' do
        let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, :expired, user:user }

        it 'calls the #user_not_logged_in method on the listener' do
          listener.should_receive(:user_not_logged_in)
          subject
        end
      end

      context 'with a different browser' do
        let(:user_agent) { 'FooBar 1.0' }

        it 'calls the #user_not_logged_in method on the listener' do
          listener.should_receive(:user_not_logged_in)
          subject
        end
      end
    end

    context 'when two-factor authentication is pending' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, :awaiting_two_factor_authentication, user: user }
      let(:cookies) { { tgt:ticket_granting_ticket.ticket } }

      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in)
        processor.process(cookies, user_agent)
      end

      context 'and we opt ignore that' do
        it 'calls the #current_user_found method on the listener' do
          listener.should_receive(:current_user_found)
          processor.process(cookies, user_agent, ignore_two_factor:true)
        end
      end
    end

    context 'with an invalid Ticket Granting Ticket' do
      let(:cookies) { { tgt:'TGT-INVALID' } }

      it 'calls the :user_not_logged_in callback' do
        listener.should_receive(:user_not_logged_in)
        subject
      end
    end
  end

  describe '#process!' do
    subject { processor.process!(cookies, user_agent) }

    context 'with an existing Ticket Granting Ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:cookies) { { tgt:ticket_granting_ticket.ticket } }

      it 'calls the :current_user_found callback' do
        listener.should_receive(:current_user_found)
        subject
      end
    end

    context 'with an invalid Ticket Granting Ticket' do
      let(:cookies) { { tgt:'TGT-INVALID' } }

      it 'calls the :user_not_logged_in! callback' do
        listener.should_receive(:user_not_logged_in!)
        subject
      end
    end
  end
end
