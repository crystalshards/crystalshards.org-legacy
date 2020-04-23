require "promise"

struct TimeCache(K, V)
  def initialize(@expire_time : Time::Span)
    @cache = {} of K => Entry(V)
  end

  def fetch(key : K) : V
    get(key) || set(key, yield key)
  end

  def fetch_lazily(key : K, optimistic_value : V, &block : -> V) : V
    get(key) || begin
      Promise(V).execute { block.call }.then { |v| set key, v }
      optimistic_value
    end
  end

  def set(key : K, value : V)
    @cache[key] = Entry.new(value, now + @expire_time)
    value
  end

  def get(key : K) : V?
    entry = @cache[key]?
    return entry.value if entry && now < entry.expire_time
  end

  private def now
    now = Time.utc
  end

  struct Entry(V)
    getter value
    getter expire_time

    def initialize(@value : V, @expire_time : Time)
    end
  end
end
