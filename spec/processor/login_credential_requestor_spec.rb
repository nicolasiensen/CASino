require 'spec_helper'

describe CASino::LoginCredentialRequestorProcessor do
  describe '#process' do
    let(:user) { nil }
    let(:listener) { double('listener', assigned:user) }
    let(:processor) { described_class.new(listener) }

    context 'with a not allowed service' do
      before(:each) do
        FactoryGirl.create :service_rule, :regex, url: '^https://.*'
      end
      let(:service) { 'http://www.example.org/' }
      let(:params) { { service: service } }

      it 'calls the #service_not_allowed method on the listener' do
        listener.should_receive(:service_not_allowed).with(service)
        processor.process(params)
      end
    end

    context 'when logged out' do
      it 'calls the #user_not_logged_in method on the listener' do
        listener.should_receive(:user_not_logged_in).with(kind_of(CASino::LoginTicket))
        processor.process
      end

      context 'with gateway parameter' do
        context 'with a service' do
          let(:service) { 'http://example.com/' }
          let(:params) { { service: service, gateway: 'true' } }

          it 'calls the #user_logged_in method on the listener' do
            listener.should_receive(:user_logged_in).with(service)
            processor.process(params)
          end
        end

        context 'without a service' do
          let(:params) { { gateway: 'true' } }

          it 'calls the #user_not_logged_in method on the listener' do
            listener.should_receive(:user_not_logged_in).with(kind_of(CASino::LoginTicket))
            processor.process
          end
        end
      end
    end

    context 'when logged in' do
      let(:user) { FactoryGirl.create :user }
      let(:ticket_granting_ticket) { FactoryGirl.create :ticket_granting_ticket, user: user }
      let(:user_agent) { ticket_granting_ticket.user_agent }

      before do
        FactoryGirl.create :ticket_granting_ticket, user: user
      end

      context 'with a service' do
        let(:service) { 'http://example.com/' }
        let(:params) { { service: service } }

        it 'calls the #user_logged_in method on the listener' do
          listener.should_receive(:user_logged_in).with(/^#{service}\?ticket=ST\-/)
          processor.process(params, user, user_agent)
        end

        it 'generates a service ticket' do
          listener.stub(:user_logged_in)
          lambda do
            processor.process(params, user, user_agent)
          end.should change(CASino::ServiceTicket, :count).by(1)
        end

        context 'with renew parameter' do
          let(:params) { super().merge renew:'true' }

          it 'calls the #user_not_logged_in method on the listener' do
            listener.should_receive(:user_not_logged_in).with(kind_of(CASino::LoginTicket))
            processor.process(params, user, user_agent)
          end
        end
      end

      context 'with a service with nested attributes' do
        let(:service) { 'http://example.com/?a%5B%5D=test&a%5B%5D=example' }
        let(:params) { { service: service } }

        it 'does not remove the attributes' do
          listener.should_receive(:user_logged_in).with(/\?a%5B%5D=test&a%5B%5D=example&ticket=ST\-[^&]+$/)
          processor.process(params, user, user_agent)
        end
      end

      context 'without a service' do
        it 'calls the #user_logged_in method on the listener' do
          listener.should_receive(:user_logged_in).with(nil)
          processor.process
        end

        it 'does not generate a service ticket' do
          listener.stub(:user_logged_in)
          lambda do
            processor.process
          end.should change(CASino::ServiceTicket, :count).by(0)
        end
      end
    end
  end
end
