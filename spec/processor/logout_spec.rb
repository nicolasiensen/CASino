require 'spec_helper'

describe CASino::LogoutProcessor do
  describe '#process' do
    let(:listener) { double('listener') }
    let(:processor) { described_class.new(listener) }
    let(:user) { FactoryGirl.create :user }
    let(:url) { nil }
    let(:params) { { :url => url } unless url.nil? }

    context 'with an existing ticket-granting ticket' do
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:user_agent) { ticket_granting_ticket.user_agent }

      it 'deletes the ticket-granting ticket' do
        listener.stub(:user_logged_out)
        processor.process(params, user, user_agent)
        CASino::TicketGrantingTicket.where(id: ticket_granting_ticket.id).first.should == nil
      end

      it 'calls the #user_logged_out method on the listener' do
        listener.should_receive(:user_logged_out).with(nil)
        processor.process(params, user, user_agent)
      end

      context 'with an URL' do
        let(:url) { 'http://www.example.com' }

        it 'calls the #user_logged_out method on the listener and passes the URL' do
          listener.should_receive(:user_logged_out).with(url)
          processor.process(params, user, user_agent)
        end
      end

      context 'with a service' do
        let(:params) { { :service => url } }
        let(:url) { 'http://www.example.org' }

        context '(whitelisted)' do
          it 'calls the #user_logged_out method on the listener and passes the URL and the redirect_immediate flag' do
            listener.should_receive(:user_logged_out).with(url, true)
            processor.process(params, user, user_agent)
          end
        end

        context '(not whitelisted)' do
          before(:each) do
            FactoryGirl.create :service_rule, :regex, url: '^https://.*'
          end

          it 'calls the #user_logged_out method on the listener and passes no URL' do
            listener.should_receive(:user_logged_out).with(nil)
            processor.process(params, user, user_agent)
          end
        end
      end
    end
  end
end
