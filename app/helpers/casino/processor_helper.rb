module CASino::ProcessorHelper
  protected
  def processor(processor_name, listener_name = nil)
    listener_name ||= processor_name
    listener = CASino.const_get(:"#{listener_name}Listener").new(self)
    @processor = CASino.const_get(:"#{processor_name}Processor").new(listener)
  end
end