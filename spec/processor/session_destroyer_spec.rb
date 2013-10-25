require 'spec_helper'

describe CASino::SessionDestroyerProcessor do
  describe '#process' do
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }
    let(:owner_ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
    let(:user) { owner_ticket_granting_ticket.user }
    let(:user_agent) { owner_ticket_granting_ticket.user_agent }

    context 'with an existing ticket-granting ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:service_ticket) { FactoryGirl.create :service_ticket, ticket_granting_ticket: ticket_granting_ticket }
      let(:consumed_service_ticket) { FactoryGirl.create :service_ticket, :consumed, ticket_granting_ticket: ticket_granting_ticket }
      let(:params) { { id: ticket_granting_ticket.id } }

      it 'deletes exactly one ticket-granting ticket' do
        listener.stub(:ticket_deleted)
        ticket_granting_ticket
        lambda do
          processor.process(params, user, user_agent)
        end.should change(CASino::TicketGrantingTicket, :count).by(-1)
      end

      it 'deletes the ticket-granting ticket' do
        listener.stub(:ticket_deleted)
        processor.process(params, user, user_agent)
        CASino::TicketGrantingTicket.where(id: params[:id]).length.should == 0
      end

      it 'calls the #ticket_deleted method on the listener' do
        listener.should_receive(:ticket_deleted).with(no_args)
        processor.process(params, user, user_agent)
      end
    end

    context 'with an invalid ticket-granting ticket' do
      let(:params) { { id: 99999 } }
      it 'does not delete a ticket-granting ticket' do
        listener.stub(:ticket_not_found)
        lambda do
          processor.process(params, user, user_agent)
        end.should_not change(CASino::TicketGrantingTicket, :count)
      end

      it 'calls the #ticket_not_found method on the listener' do
        listener.should_receive(:ticket_not_found).with(no_args)
        processor.process(params, user, user_agent)
      end
    end

    context 'when trying to delete ticket-granting ticket of another user' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket }
      let(:params) { { id: ticket_granting_ticket.id } }

      it 'does not delete a ticket-granting ticket' do
        listener.stub(:ticket_not_found)
        ticket_granting_ticket
        lambda do
          processor.process(params, user, user_agent)
        end.should change(CASino::TicketGrantingTicket, :count).by(0)
      end

      it 'calls the #ticket_not_found method on the listener' do
        listener.should_receive(:ticket_not_found).with(no_args)
        processor.process(params, user, user_agent)
      end
    end
  end
end