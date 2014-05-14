require 'spec_helper'

describe CASino::SessionOverviewProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }
    let(:other_ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
    let(:user) { other_ticket_granting_ticket.user }
    let(:user_agent) { other_ticket_granting_ticket.user_agent }

    context 'with an existing ticket-granting ticket' do
      before do
        FactoryGirl.create :ticket_granting_ticket, user: user
      end
      it 'calls the #ticket_granting_tickets_found method on the listener' do
        listener.should_receive(:ticket_granting_tickets_found) do |tickets|
          tickets.length.should == 2
        end
        processor.process(user, user_agent)
      end
    end

    context 'with a ticket-granting ticket with same username but different authenticator' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }

      it 'calls the #ticket_granting_tickets_found method on the listener' do
        listener.should_receive(:ticket_granting_tickets_found) do |tickets|
          tickets.length.should == 1
        end
        processor.process(user, user_agent)
      end
    end

    context 'without a logged in user' do
      let(:user) { nil }
      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in).with(no_args)
        processor.process(user, user_agent)
      end
    end
  end
end