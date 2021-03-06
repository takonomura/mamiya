class DummySerf
  def initialize()
    @hooks = {}
    @responders = {}

    @tags = {}
    class << @tags
      alias_method :update, :merge!
    end
  end

  attr_reader :tags

  def name
    'my-name'
  end

  def start!
  end

  def auto_stop
  end

  def ready?
    true
  end

  def wait_for_ready
  end

  def event(name, payload)
  end

  %w(member_join member_leave member_failed
     member_update member_reap
     user_event query stop event).each do |event|

    define_method(:"on_#{event}") do |&block|
      hooks(event) << block
    end
  end

  def hooks(name)
    @hooks[name] ||= []
  end

  def respond(name, override: false, &block)
    raise 'already defined' if !override && @responders[name.to_s]
    @responders[name.to_s] = block
    self
  end

  def trigger_query(name, payload)
    event = Villein::Event.new(
      {
        'SERF_EVENT' => 'query',
        'SERF_QUERY_NAME' => "name",
      },
      payload: payload.to_s,
    )
    @responders[name.to_s] && @responders[name.to_s].call(event)
  end

  def trigger(name, *args)
    hooks(name).each do |hook|
      hook.call(*args)
    end
    nil
  end
end
