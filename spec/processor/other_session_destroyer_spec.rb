require 'spec_helper'

describe CASino::OtherSessionsDestroyerProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:nil) }
    let(:processor) { described_class.new(listener) }
    let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
    let(:user) { ticket_granting_ticket.user }
    let(:user_agent) { ticket_granting_ticket.user_agent }
    let(:params) { { service:'SERVICE' } }

    context 'with an existing ticket-granting ticket' do
      let(:params) { super().merge(id: ticket_granting_ticket.id) }

      it 'deletes all other ticket-granting tickets' do
        FactoryGirl.create_list :ticket_granting_ticket, 2, user:user
        listener.stub(:other_sessions_destroyed)
        lambda do
          processor.process(params, user, user_agent)
        end.should change(CASino::TicketGrantingTicket, :count).by(-2)
      end

      it 'does not delete the ticket-granting ticket' do
        listener.stub(:other_sessions_destroyed)
        processor.process(params, user, user_agent)
        CASino::TicketGrantingTicket.find(params[:id]).should_not be_nil
      end

      it 'calls the #other_sessions_destroyed method on the listener' do
        listener.should_receive(:other_sessions_destroyed).with('SERVICE')
        processor.process(params, user, user_agent)
      end
    end

    context 'with an invalid ticket-granting ticket' do
      let(:user) { nil }
      it 'does not delete any ticket-granting ticket' do
        FactoryGirl.create_list :ticket_granting_ticket, 2
        listener.stub(:other_sessions_destroyed)

        user_agent

        lambda do
          processor.process(params, user, user_agent)
        end.should_not change(CASino::TicketGrantingTicket, :count)
      end

      it 'calls the #ticket_not_found method on the listener' do
        listener.should_receive(:other_sessions_destroyed).with('SERVICE')
        processor.process(params, user, user_agent)
      end
    end
  end
end